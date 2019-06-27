# Lambda を利用した Custom Authorizer

resource "aws_lambda_function" "authorizer" {
  filename         = data.external.package_authorizer.result.filename
  source_code_hash = filebase64sha256(data.external.package_authorizer.result.filename)
  function_name    = "${var.api_name}-authorizer"
  role             = aws_iam_role.authorizer.arn
  handler          = "authorizer.lambda_handler"
  runtime          = "ruby2.5"
  tags             = var.base_tags

  environment {
    variables = {
      API_ID     = aws_api_gateway_rest_api.api.id
      AUTH_TABLE = aws_dynamodb_table.stns_auth.id
      API_KEY    = aws_api_gateway_api_key.api.value
    }
  }
}

resource "aws_cloudwatch_log_group" "authorizer" {
  name              = "/aws/lambda/${aws_lambda_function.authorizer.function_name}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_iam_role" "authorizer" {
  name               = "${var.api_name}-authorizer-function-role"
  assume_role_policy = data.aws_iam_policy_document.lambda.json
  tags               = var.base_tags
}

resource "aws_iam_role_policy" "authorizer" {
  name   = "${aws_lambda_function.authorizer.function_name}-function-policy"
  role   = aws_iam_role.authorizer.id
  policy = data.aws_iam_policy_document.authorizer.json
}

data "aws_iam_policy_document" "authorizer" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["*"]
  }

  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [aws_dynamodb_table.stns_auth.arn]
  }
}

data "external" "package_authorizer" {
  program = ["${path.module}/lambda/authorizer/package.sh"]
}

resource "aws_api_gateway_authorizer" "lambda_token_auth" {
  name                             = "${var.api_name}-authorizer"
  rest_api_id                      = aws_api_gateway_rest_api.api.id
  identity_source                  = "method.request.header.Authorization"
  identity_validation_expression   = "^token .*$"
  authorizer_result_ttl_in_seconds = 3600
  authorizer_uri                   = aws_lambda_function.authorizer.invoke_arn
  authorizer_credentials           = aws_iam_role.invocation_role.arn
}

resource "aws_iam_role" "invocation_role" {
  name               = "${var.api_name}-authorizer-invocation-role"
  assume_role_policy = data.aws_iam_policy_document.apigateway.json
  tags               = var.base_tags
}

data "aws_iam_policy_document" "apigateway" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "invocation_policy" {
  name   = "${var.api_name}-authorizer-invocation-policy"
  role   = aws_iam_role.invocation_role.id
  policy = data.aws_iam_policy_document.invocation_role.json
}

data "aws_iam_policy_document" "invocation_role" {
  statement {
    actions   = ["lambda:InvokeFunction"]
    resources = [aws_lambda_function.authorizer.arn]
  }
}

