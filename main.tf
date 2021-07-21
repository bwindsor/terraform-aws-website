locals {
  is_cognito = var.is_private && var.auth_type == "COGNITO"
  is_basic_auth = var.is_private && var.auth_type == "BASIC"
}
