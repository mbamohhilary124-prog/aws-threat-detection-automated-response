output "guardduty_response_function_name" {
  description = "Name of the Lambda function that evaluates GuardDuty findings."
  value       = aws_lambda_function.guardduty_response.function_name
}

output "guardduty_response_log_group_name" {
  description = "CloudWatch log group containing Lambda dry-run response decisions."
  value       = aws_cloudwatch_log_group.guardduty_response.name
}

output "guardduty_response_mode" {
  description = "Current remediation operating mode."
  value       = "DRY_RUN"
}
