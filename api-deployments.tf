# Deployment

resource aws_api_gateway_deployment "api" {
  depends_on = [
    "aws_api_gateway_integration.lambda_root",
    "aws_api_gateway_integration.lambda_proxy",
  ]

  rest_api_id       = "${aws_api_gateway_rest_api.api.id}"
  stage_name        = "${var.stage_name}"
  stage_description = "Terraform hash ${md5("${file("${path.module}/api-resources.tf")}${local.resource_policy}")}"
  description       = "Terraform hash ${md5("${file("${path.module}/api-resources.tf")}${local.resource_policy}")}"
}

resource aws_api_gateway_usage_plan "api" {
  name = "${var.api_name}-usage-plan"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api.id}"
    stage  = "${aws_api_gateway_deployment.api.stage_name}"
  }
}

resource aws_api_gateway_api_key "api" {
  name = "${var.api_name}-api-key"
}

resource aws_api_gateway_usage_plan_key "api" {
  key_id        = "${aws_api_gateway_api_key.api.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.api.id}"
}
