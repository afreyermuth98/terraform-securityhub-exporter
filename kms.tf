resource "aws_kms_alias" "securityhub_alias" {
  name          = "alias/securityhub-key"
  target_key_id = aws_kms_key.securityhub_key.key_id
}


resource "aws_kms_key" "securityhub_key" {
  description = "KMS KEY for securityhub exporter lambda"
  policy      = data.aws_iam_policy_document.kms_key_policy.json
}

data "aws_iam_policy_document" "kms_key_policy" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.account_id}:root"]
    }
  }

  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [aws_s3_bucket.securityhub_bucket.arn]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.lambda.arn,
      ]
    }
  }

}