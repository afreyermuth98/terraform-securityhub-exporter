data "archive_file" "securityhub_exporter" {
  type        = "zip"
  source_file = "sources/securityhub_exporter.py"
  output_path = "sources/securityhub_exporter.zip"
}

resource "aws_lambda_function" "securityhub_exporter" {
  filename      = data.archive_file.securityhub_exporter.output_path
  function_name = "SecurityHub-Exporter"
  description   = "This script exports the findings of security hub"

  role             = aws_iam_role.lambda.arn
  handler          = "securityhub_exporter.lambda_handler"
  source_code_hash = data.archive_file.securityhub_exporter.output_base64sha256
  runtime          = var.runtime
  memory_size      = var.memory_size
  timeout          = var.timeout

  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.securityhub_topic.arn
      BUCKET        = aws_s3_bucket.securityhub_bucket.bucket
    }
  }

  depends_on = [data.archive_file.securityhub_exporter]

}


