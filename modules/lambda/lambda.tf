resource "aws_lambda_function" "fn" {
  function_name = var.name
  description   = var.description
  runtime       = "go1.x"
  handler       = var.handler
  role          = aws_iam_role.lambda_execution.arn
  timeout       = var.timeout

  # Stub an application deployment
  # (deployments will be managed outside terraform)
  filename = data.archive_file.lambda_code_stub.output_path

  lifecycle {
    # Filename will change, as new application deployments are pushed.
    # Prevent terraform from reverting to old application deployments
    # We're not using terraform to manage application deployments
    ignore_changes = [filename]
  }

  environment {
    variables = var.environment
  }

  dynamic "dead_letter_config" {
    for_each = aws_sqs_queue.lambda_dlq.*.arn
    content {
      target_arn = dead_letter_config.value
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.fn
  ]

  tags = var.global_tags
}

resource "aws_cloudwatch_log_group" "fn" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = var.cloudwatch_log_retention
}

# Lambda code deployments are managed outside of Terraform,
# by our Jenkins pipeline.
# However, Lambda TF resource require a code file to initialize.
# We'll create an empty "stub" file to initialize the lambda function,
# and then publish the code afterwards from jenkins.
data "archive_file" "lambda_code_stub" {
  type        = "zip"
  output_path = "${path.module}/lambda_stub.zip"

  source {
    filename = "stub_file"
    content  = "STUB CONTENT"
  }
}
