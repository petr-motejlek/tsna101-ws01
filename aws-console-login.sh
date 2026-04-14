#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# aws-console-login.sh
#
# Opens the AWS Management Console using your IAM user's access key and
# secret key (the ones you created for the TerraformAdmin user).
#
# How it works:
#   1. Calls  aws sts get-federation-token  to obtain temporary credentials.
#   2. Exchanges them for a sign-in token via the AWS federation endpoint.
#   3. Prints a one-time Console URL you can open in your browser.
#
# Prerequisites:
#   - AWS CLI configured with your access key / secret key
#     (via  aws configure , env vars, or ~/.aws/credentials)
#   - python3  (used for URL encoding / JSON handling)
#   - curl
#
# Usage:
#   ./aws-console-login.sh              # 12-hour session (default)
#   ./aws-console-login.sh 3600         # 1-hour session
# ---------------------------------------------------------------------------
set -euo pipefail

DURATION="${1:-43200}"   # seconds; default 12 h, max 36 h (129 600)
FEDERATION_URL="https://signin.aws.amazon.com/federation"
CONSOLE_URL="https://console.aws.amazon.com/"

# ── Pre-flight checks ─────────────────────────────────────────────────────
for cmd in aws python3 curl; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not found in PATH." >&2
    exit 1
  fi
done

# Quick sanity check – can we talk to AWS at all?
if ! aws sts get-caller-identity &>/dev/null; then
  echo "ERROR: AWS credentials are not configured or are invalid." >&2
  echo "       Run 'aws configure' first." >&2
  exit 1
fi

CALLER=$(aws sts get-caller-identity --output json)
echo "Authenticated as: $(echo "$CALLER" | python3 -c "import sys,json; print(json.load(sys.stdin)['Arn'])")"

# ── Step 1: Get federation token ──────────────────────────────────────────
echo "Requesting federation token (session duration: ${DURATION}s) ..."

CREDS=$(aws sts get-federation-token \
  --name ConsoleSession \
  --duration-seconds "$DURATION" \
  --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Action":"*","Resource":"*"}]}' \
  --output json)

# ── Step 2: Build URL-encoded session JSON ────────────────────────────────
ENCODED_SESSION=$(echo "$CREDS" | python3 -c "
import sys, json, urllib.parse
creds = json.load(sys.stdin)['Credentials']
session = json.dumps({
    'sessionId':    creds['AccessKeyId'],
    'sessionKey':   creds['SecretAccessKey'],
    'sessionToken': creds['SessionToken'],
})
print(urllib.parse.quote_plus(session))
")

# ── Step 3: Exchange session for a sign-in token ─────────────────────────
SIGNIN_RESPONSE=$(curl -s "${FEDERATION_URL}?Action=getSigninToken&Session=${ENCODED_SESSION}")

SIGNIN_TOKEN=$(echo "$SIGNIN_RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'SigninToken' not in data:
    print('ERROR: Federation endpoint did not return a SigninToken.', file=sys.stderr)
    print('Response: ' + json.dumps(data), file=sys.stderr)
    sys.exit(1)
print(data['SigninToken'])
")

# ── Step 4: Build the Console login URL ──────────────────────────────────
ENCODED_DEST=$(python3 -c "import urllib.parse; print(urllib.parse.quote_plus('${CONSOLE_URL}'))")

LOGIN_URL="${FEDERATION_URL}?Action=login&Issuer=&Destination=${ENCODED_DEST}&SigninToken=${SIGNIN_TOKEN}"

echo ""
echo "============================================================"
echo "  Open this URL in your browser to access the AWS Console:"
echo "============================================================"
echo ""
echo "$LOGIN_URL"
echo ""
echo "(The link is valid for 15 minutes. The console session lasts ${DURATION}s.)"
