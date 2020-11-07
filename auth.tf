module "cognito_auth" {
  count = var.is_private && var.create_cognito_pool ? 1 : 0

  source = "./cognito"

  auth_domain_prefix = var.auth_domain_prefix
  callback_urls = ["${local.url}${var.parse_auth_path}"]
  deployment_name = var.deployment_name
  logout_urls = ["${local.url}${var.logout_path}"]
  refresh_token_validity_days = var.refresh_token_validity_days
  oauth_scopes = var.oauth_scopes
}

locals {
  user_pool_arn = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].user_pool_arn : var.cognito.user_pool_arn
  cognito_client_id = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].client_id: var.cognito.client_id
  auth_domain = var.is_private && var.create_cognito_pool ? module.cognito_auth[0].auth_domain : var.cognito.auth_domain
}
