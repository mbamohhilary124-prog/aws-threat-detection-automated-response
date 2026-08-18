output "authenticated_principal_arn" {
  description = "ARN of the AWS identity used by Terraform."
  value       = data.aws_caller_identity.current.arn
  sensitive   = true
}

output "deployment_region" {
  description = "AWS region selected for this deployment."
  value       = var.aws_region
}
