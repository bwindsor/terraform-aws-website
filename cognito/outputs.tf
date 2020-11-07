output "user_pool_id" {
  value = aws_cognito_user_pool.user_pool.id
}

output "user_pool_arn" {
  value = aws_cognito_user_pool.user_pool.arn
}

output "client_id" {
  value = aws_cognito_user_pool_client.user_pool_client.id
}

output "auth_domain" {
  value = local.auth_domain
}

output "auth_base_url" {
  value = local.auth_base_url
}
