resource "aws_guardduty_detector" "main" {
  enable                       = true
  finding_publishing_frequency = "FIFTEEN_MINUTES"
}

locals {
  guardduty_disabled_features = toset([
    "S3_DATA_EVENTS",
    "EKS_AUDIT_LOGS",
    "EBS_MALWARE_PROTECTION",
    "RDS_LOGIN_EVENTS",
    "LAMBDA_NETWORK_LOGS",
    "RUNTIME_MONITORING",
    "AI_PROTECTION",
    "AI_ANALYST"
  ])

  guardduty_runtime_agents = toset([
    "EC2_AGENT_MANAGEMENT",
    "ECS_FARGATE_AGENT_MANAGEMENT",
    "EKS_ADDON_MANAGEMENT"
  ])
}

resource "aws_guardduty_detector_feature" "cost_control" {
  for_each = local.guardduty_disabled_features

  detector_id = aws_guardduty_detector.main.id
  name        = each.value
  status      = "DISABLED"

  dynamic "additional_configuration" {
    for_each = each.value == "RUNTIME_MONITORING" ? local.guardduty_runtime_agents : toset([])

    content {
      name   = additional_configuration.value
      status = "DISABLED"
    }
  }
}
