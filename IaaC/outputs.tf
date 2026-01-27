########################################
# OUTPUTS
########################################
output "api_url" {
  value = aws_api_gateway_deployment.deploy.invoke_url
}

output "frontend_url" {
  value = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
