resource "aws_lambda_function" "stns" {
  filename         = data.external.package_api.result.filename
  source_code_hash = filebase64sha256(data.external.package_api.result.filename)
  function_name    = var.api_name
  role             = aws_iam_role.stns.arn
  handler          = "app.lambda_handler"
  runtime          = "ruby2.5"
  tags             = var.base_tags

  environment {
    variables = {
      USER_TABLE  = aws_dynamodb_table.stns_users.id
      GROUP_TABLE = aws_dynamodb_table.stns_groups.id
    }
  }
}

resource "aws_cloudwatch_log_group" "stns" {
  name              = "/aws/lambda/${aws_lambda_function.stns.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_iam_role" "stns" {
  name               = "${var.api_name}-function-role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
  tags               = var.base_tags
}

resource "aws_iam_role_policy" "stns" {
  name   = "${aws_lambda_function.stns.function_name}-function-policy"
  role   = aws_iam_role.stns.id
  policy = data.aws_iam_policy_document.stns.json
}

data "aws_iam_policy_document" "lambda" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "stns" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:PutItem",
    ]

    resources = [
      aws_dynamodb_table.stns_users.arn,
      "${aws_dynamodb_table.stns_users.arn}/*",
      aws_dynamodb_table.stns_groups.arn,
      "${aws_dynamodb_table.stns_groups.arn}/*",
      aws_dynamodb_table.stns_auth.arn,
      "${aws_dynamodb_table.stns_auth.arn}/*",
    ]
  }
}

data "external" "package_api" {
  program = ["${path.module}/lambda/stns-api/package.sh"]
}

