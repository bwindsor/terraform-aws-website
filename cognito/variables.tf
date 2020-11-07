variable "deployment_name" {
  type = string
  description = "Deployment name"
}

variable "auth_domain_prefix" {
  type = string
  description = "The first part of the hosted UI login domain, as in https://[AUTH_DOMAIN_PREFIX].auth.eu-west-1.amazoncognito.com/"
}

variable "callback_urls" {
  type = list(string)
  description = "Callback URLs for parsing auth code"
}

variable "logout_urls" {
  type = list(string)
  description = "URLs to redirect to from hosted UI after logout"
}

variable "refresh_token_validity_days" {
  type = number
  description = "Refresh token validity period in days"
}

variable "oauth_scopes" {
  type = list(string)
  description = "Description: The OAuth scopes to request the User Pool to add to the access token JWT."
}
