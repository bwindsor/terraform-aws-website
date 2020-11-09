data "aws_region" "current" {}

module "cognito_auth" {
  count = var.is_private && var.create_cognito_pool ? 1 : 0

  source = "./cognito"

  auth_domain_prefix = var.auth_domain_prefix
  callback_urls = concat(["${local.url}${var.parse_auth_path}"], formatlist("%s${var.parse_auth_path}", var.additional_redirect_urls))
  deployment_name = var.deployment_name
  logout_urls = concat(["${local.url}${var.logout_path}"], formatlist("%s${var.logout_path}", var.additional_redirect_urls))
  refresh_token_validity_days = var.refresh_token_validity_days
  oauth_scopes = var.oauth_scopes
}

locals {
  user_pool_arn = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].user_pool_arn : var.is_private ? var.cognito.user_pool_arn : null
  user_pool_id = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].user_pool_id : var.is_private ? var.cognito.user_pool_id : null
  cognito_client_id = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].client_id: var.is_private ? var.cognito.client_id : null
  auth_domain = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].auth_domain : var.is_private ? var.cognito.auth_domain : null
  auth_base_url = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].auth_base_url : var.is_private ? "https://${var.cognito.auth_domain}" : null
}
