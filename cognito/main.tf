data "aws_region" "current" {}

resource "aws_cognito_user_pool" "user_pool" {
  name = "${var.deployment_name}-user-pool"
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

locals {
  auth_domain = "${var.auth_domain_prefix}.auth.${data.aws_region.current.name}.amazoncognito.com"
  auth_base_url = "https://${local.auth_domain}"
}

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name = "${var.deployment_name}-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  prevent_user_existence_errors = "ENABLED"
  generate_secret = false
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = var.oauth_scopes
  supported_identity_providers = ["COGNITO"]
  callback_urls = var.callback_urls
  logout_urls = var.logout_urls
  refresh_token_validity = var.refresh_token_validity_days
}

resource "aws_cognito_user_pool_domain" "hosted_ui_domain" {
  domain       = var.auth_domain_prefix
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
