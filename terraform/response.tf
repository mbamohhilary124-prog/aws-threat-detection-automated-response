data "archive_file" "guardduty_response" {
  type        = "zip"
  source_file = "${path.module}/../lambda/response_handler.py"
  output_path = "${path.module}/lambda_response.zip"
}

data "aws_iam_policy_document" "guardduty_response_assume_role" {
  statement {
    sid     = "AllowLambdaServiceToAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "guardduty_response" {
  name               = "${var.environment}-guardduty-response-role"
  assume_role_policy = data.aws_iam_policy_document.guardduty_response_assume_role.json
}

resource "aws_cloudwatch_log_group" "guardduty_response" {
  name              = "/aws/lambda/${var.environment}-guardduty-response"
  retention_in_days = 14
}

data "aws_iam_policy_document" "guardduty_response_logs" {
  statement {
    sid    = "AllowWritingLambdaLogs"
    effect = "Allow"

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = [
      "${aws_cloudwatch_log_group.guardduty_response.arn}:*"
    ]
  }
}

resource "aws_iam_role_policy" "guardduty_response_logs" {
  name   = "${var.environment}-guardduty-response-logs"
  role   = aws_iam_role.guardduty_response.id
  policy = data.aws_iam_policy_document.guardduty_response_logs.json
}

resource "aws_lambda_function" "guardduty_response" {
  function_name = "${var.environment}-guardduty-response"
  description   = "Evaluates GuardDuty findings and records safe dry-run response decisions."

  filename         = data.archive_file.guardduty_response.output_path
  source_code_hash = data.archive_file.guardduty_response.output_base64sha256

  role    = aws_iam_role.guardduty_response.arn
  handler = "response_handler.lambda_handler"
  runtime = "python3.13"

  architectures = ["x86_64"]
  memory_size   = 128
  timeout       = 10


  environment {
    variables = {
      DRY_RUN          = "true"
      MINIMUM_SEVERITY = "4.0"
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.guardduty_response,
    aws_iam_role_policy.guardduty_response_logs
  ]
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.guardduty_response.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.guardduty_findings.arn
}

resource "aws_cloudwatch_event_target" "guardduty_to_response_lambda" {
  rule      = aws_cloudwatch_event_rule.guardduty_findings.name
  target_id = "SendGuardDutyFindingToResponseLambda"
  arn       = aws_lambda_function.guardduty_response.arn

  retry_policy {
    maximum_event_age_in_seconds = 3600
    maximum_retry_attempts       = 2
  }

  depends_on = [
    aws_lambda_permission.allow_eventbridge
  ]
}
