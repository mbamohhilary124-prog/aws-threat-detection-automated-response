output "authenticated_principal_arn" {
  description = "ARN of the AWS identity used by Terraform."
  value       = data.aws_caller_identity.current.arn
  sensitive   = true
}

output "deployment_region" {
  description = "AWS region selected for this deployment."
  value       = var.aws_region
}

output "security_log_bucket_name" {
  description = "Name of the encrypted S3 bucket used for security logs."
  value       = aws_s3_bucket.security_logs.id
}

output "guardduty_alert_topic_name" {
  description = "Name of the SNS topic used for GuardDuty alert delivery."
  value       = aws_sns_topic.guardduty_alerts.name
}

output "guardduty_event_rule_name" {
  description = "Name of the EventBridge rule that captures GuardDuty findings."
  value       = aws_cloudwatch_event_rule.guardduty_findings.name
}