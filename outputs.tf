data aws_region "current" {}

output endpoint_url {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${data.aws_region.current.name}.amazonaws.com/${aws_api_gateway_deployment.api.stage_name}"
}
