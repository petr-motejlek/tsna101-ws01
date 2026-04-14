# ---------------------------------------------------------------------------
# Convenience (always active)
# ---------------------------------------------------------------------------

output "aws_account_id" {
  description = "AWS account ID — verify you are in the correct sandbox account."
  value       = data.aws_caller_identity.current.account_id
}

output "aws_region" {
  description = "AWS region all resources are deployed into."
  value       = var.aws_region
}