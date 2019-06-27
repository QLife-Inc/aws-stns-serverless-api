resource "aws_api_gateway_rest_api" "api" {
  name           = var.api_name
  description    = "STNS Serverlss API"
  api_key_source = "AUTHORIZER"
  policy         = var.api_policy_json

  endpoint_configuration {
    types = ["PRIVATE"]
  }
}

# すべてのリクエストを Lambda に Proxy する。
# https://docs.aws.amazon.com/ja_jp/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html
# https://bit.ly/2GGsn4j
resource "aws_api_gateway_resource" "proxy_path" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy_path" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.proxy_path.id
  http_method      = "ANY"
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.lambda_token_auth.id
  api_key_required = true

  request_parameters = {
    "method.request.path.proxy" = true
  }
}

resource "aws_api_gateway_integration" "lambda_proxy" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.proxy_path.resource_id
  http_method             = aws_api_gateway_method.proxy_path.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.stns.invoke_arn
}

# ルートパスに対するリクエストは別途定義が必要（内容は proxy_path と同じ）
resource "aws_api_gateway_method" "root_path" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_rest_api.api.root_resource_id
  http_method      = "ANY"
  authorization    = "CUSTOM"
  authorizer_id    = aws_api_gateway_authorizer.lambda_token_auth.id
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_root" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_method.root_path.resource_id
  http_method             = aws_api_gateway_method.root_path.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.stns.invoke_arn
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.stns.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}

