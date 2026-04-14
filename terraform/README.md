# Workshop 1 — VPC Foundations & Exposing a Service

## Before You Start — Environment Setup

You received **console login credentials** (username + password) for your sandbox AWS account.
All Terraform work is done locally on your machine.

### What you need

1. **Terraform ≥ 1.7** installed (`terraform version`).
2. **AWS CLI v2** installed.
3. **AWS Session Manager plugin** installed (used for EC2 access via `aws ssm start-session`
   in Workshop 3 — no SSH keys needed).

### One-time setup (create IAM user)

You need an IAM user with programmatic access. Use **AWS CloudShell** (or any AWS-authenticated
environment) to create it:

1. **Log in** to AWS Console → switch to **eu-west-1** (Ireland)
2. **Open CloudShell** → click `>_` icon in top nav, wait ~30 seconds
3. **Deploy CloudFormation stack:**
   ```bash
   aws cloudformation create-stack \
     --stack-name terraform-admin \
     --template-body file://terraform-admin.yaml \
     --capabilities CAPABILITY_NAMED_IAM
   aws cloudformation wait stack-create-complete --stack-name terraform-admin
   ```
4. **Create access key:**
   ```bash
   aws iam create-access-key --user-name TerraformAdmin
   ```
   **Copy AccessKeyId and SecretAccessKey now!**
5. **Configure locally:**
   ```bash
   aws configure
   # Enter AccessKeyId, SecretAccessKey, region (eu-west-1), output format (json)
   ```
6. **Verify:**
   ```bash
   aws sts get-caller-identity   # should show "TerraformAdmin"
   ```

> ⚠️ CloudShell is only for creating the IAM user. All Terraform work is done locally.

## Goal

By the end of this session you will have:
- **Two VPCs** (VPC 1: ALB + egress, VPC 2: ECS backend)
- **ECS Fargate** running `ealen/echo-server` in private subnets
- **ALB** publicly reachable via VPC Peering

## Architecture

```
Internet
  │
  ▼
ALB (:80) ── VPC 1 (10.0.0.0/16) ── public subnets
  │                              ── private subnets
  │                                    └── NAT GW (egress)
  │
  │ [VPC Peering]
  ▼
ECS Fargate ── VPC 2 (10.1.0.0/16) ── private subnets
  echo-server                              └── NAT GW
      └── CloudWatch Logs
```

## Quick Start

```bash
# Initialize Terraform
terraform init
terraform validate

# Follow the exercises (see below)
# Each .todo file contains inline instructions marked with:
#   🚩 ACTION  — what to do
#   💡 TIP     — pro tips
#   ⚠️ WARNING — common mistakes
#   ✅ Verification — quick check command

# After completing an exercise
terraform validate   # must pass
terraform plan        # review planned changes
terraform apply       # deploy to AWS
```

## Exercises

| # | Exercise | Files | Duration |
|---|----------|-------|----------|
| 1 | Two VPCs | 10-vpc1.tf.todo, 11-vpc2.tf.todo | 55 min |
| 2 | ECS Fargate | 50-ecs.tf.todo | 60 min |
| 2 | ECS Security Group | 30-security-ecs.tf.todo | — |
| 3 | VPC Peering | 20-peering.tf.todo | 35 min |
| 4 | ALB Security Group | 31-security-alb.tf.todo | — |
| 4 | ALB + Service | 40-alb.tf.todo, 51-ecs-service.tf.todo | 75 min |

## Troubleshooting

| Error | Solution |
|-------|----------|
| `Error: InvalidAMIID.NotFound` | Image `ealen/echo-server:latest` may be deprecated. Try `ealen/echo-server:v1` |
| `Error: No subnets found` | Ensure VPC 1 subnets are created and associated with route tables |
| VPC Peering: connection fails | Check that routes exist in BOTH VPCs (return path!) |
| ECS tasks stuck in PROVISIONING | Check NAT GW exists in VPC 2 + route to IGW |
| ALB returns 503 | Target group health check failing — ensure security group allows ALB → ECS |

## Clean Up

```bash
# IMPORTANT! Destroy all resources to avoid charges
terraform destroy

# Verify
aws cloudformation list-stacks --stack-statuses DELETE_COMPLETE
```

## Files

```
starter/
├── README.md              ← This file
├── 00-versions.tf          ← Terraform + AWS provider config
├── 01-variables.tf         ← Variables (project, region, CIDRs)
├── 02-main.tf              ← Locals (AZs)
├── 10-vpc1.tf.todo         ← Exercise 1: VPC 1
├── 11-vpc2.tf.todo         ← Exercise 1: VPC 2
├── 20-peering.tf.todo     ← Exercise 3: VPC Peering
├── 30-security-ecs.tf.todo ← Exercise 2: ECS Security Group
├── 31-security-alb.tf.todo ← Exercise 4: ALB Security Group
├── 40-alb.tf.todo         ← Exercise 4: ALB
├── 50-ecs.tf.todo         ← Exercise 2: ECS infrastructure
├── 51-ecs-service.tf.todo ← Exercise 4: ECS Service
└── 99-outputs.tf          ← Outputs
```

## Key Concepts

- **VPC Peering** — connects two VPCs, no transit (intentional for WS1 → TGW in WS2)
- **target_type = "ip"** — ALB registers ECS task IPs, not instance IDs (required for cross-VPC)
- **Regional NAT GW** — one gateway works across AZs (upgraded to zonal in WS2)
- **Separate security group rules** — allows fine-grained updates without SG recreate