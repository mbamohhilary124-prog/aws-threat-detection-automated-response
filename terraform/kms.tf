locals {
  security_kms_cloudtrail_arn = "arn:${data.aws_partition.current.partition}:cloudtrail:${var.aws_region}:${data.aws_caller_identity.current.account_id}:trail/${local.cloudtrail_name}"
  security_kms_sns_topic_arn  = "arn:${data.aws_partition.current.partition}:sns:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.environment}-guardduty-alerts"
  security_kms_event_rule_arn = "arn:${data.aws_partition.current.partition}:events:${var.aws_region}:${data.aws_caller_identity.current.account_id}:rule/${var.environment}-guardduty-findings"
}

data "aws_iam_policy_document" "security_data_kms" {
  statement {
    sid    = "EnableAccountKeyAdministration"
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        "arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }

    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowCloudTrailEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions = [
      "kms:DescribeKey",
      "kms:GenerateDataKey*"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.security_kms_cloudtrail_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "kms:EncryptionContext:aws:cloudtrail:arn"
      values   = [local.security_kms_cloudtrail_arn]
    }
  }

  statement {
    sid    = "AllowSNSMessageEncryption"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["sns.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.security_kms_sns_topic_arn]
    }
  }

  statement {
    sid    = "AllowEventBridgeEncryptedSNSPublishing"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [local.security_kms_event_rule_arn]
    }
  }
}

resource "aws_kms_key" "security_data" {
  description              = "Encrypts security-lab audit logs and security notifications."
  key_usage                = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  enable_key_rotation      = true
  deletion_window_in_days  = 7
  policy                   = data.aws_iam_policy_document.security_data_kms.json

  tags = {
    Name = "${var.environment}-security-data"
  }
}

resource "aws_kms_alias" "security_data" {
  name          = "alias/${var.environment}-security-data"
  target_key_id = aws_kms_key.security_data.key_id
}