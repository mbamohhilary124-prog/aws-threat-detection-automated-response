resource "aws_sns_topic" "guardduty_alerts" {
  name         = "${var.environment}-guardduty-alerts"
  display_name = "GuardDuty Alerts"
}

resource "aws_sns_topic_subscription" "guardduty_email" {
  topic_arn = aws_sns_topic.guardduty_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}

resource "aws_cloudwatch_event_rule" "guardduty_findings" {
  name        = "${var.environment}-guardduty-findings"
  description = "Captures medium, high, and critical Amazon GuardDuty findings."

  event_pattern = jsonencode({
    source      = ["aws.guardduty"]
    detail-type = ["GuardDuty Finding"]

    detail = {
      severity = [{
        numeric = [">=", 4]
      }]
    }
  })
}

data "aws_iam_policy_document" "guardduty_alerts" {
  statement {
    sid    = "AllowEventBridgeToPublish"
    effect = "Allow"

    actions   = ["SNS:Publish"]
    resources = [aws_sns_topic.guardduty_alerts.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [aws_cloudwatch_event_rule.guardduty_findings.arn]
    }
  }
}

resource "aws_sns_topic_policy" "guardduty_alerts" {
  arn    = aws_sns_topic.guardduty_alerts.arn
  policy = data.aws_iam_policy_document.guardduty_alerts.json
}

resource "aws_cloudwatch_event_target" "guardduty_to_sns" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendGuardDutyFindingToSNS"
  arn       = aws_sns_topic.guardduty_alerts.arn

  input_transformer {
    input_paths = {
      account_id = "$.detail.accountId"
      finding_id = "$.detail.id"
      region     = "$.region"
      severity   = "$.detail.severity"
      title      = "$.detail.title"
      type       = "$.detail.type"
    }

    input_template = <<TEMPLATE
{
  "alert": "Amazon GuardDuty security finding",
  "title": <title>,
  "severity": <severity>,
  "finding_type": <type>,
  "aws_account": <account_id>,
  "region": <region>,
  "finding_id": <finding_id>
}
TEMPLATE
  }

  depends_on = [aws_sns_topic_policy.guardduty_alerts]
}