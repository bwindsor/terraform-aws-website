variable "deployment_name" {
  description = "A unique string to use for this module to make sure resources do not clash with others"
  type = string
}

variable "website_dir" {
  description = "A folder containing all the files for your website. The contents of this folder, including all subfolders, will be stored in an S3 website and served as your website"
}
variable "additional_files" {
  description = "A mapping from file name (in S3) to file contents. For each (key,value) pair, a file will be created in S3 with the given key, with contents given by value"
  type        = map(string)
  default     = {}
}
variable "hosted_zone_name" {
  description = "The name of the hosted zone in Route53 where the SSL certificates will be created"
  type = string
}
variable "custom_domain" {
  description = "The primary domain name to use for the website"
  type        = string
}
variable "alternative_custom_domains" {
  description = "A set of any alternative domain names. Typically this would just contain the same as custom_domain but prefixed by www."
  type        = set(string)
  default     = []
}

variable "template_file_vars" {
  description = "A mapping from substitution variable name to value. Any files inside `website_dir` which end in `.template` will be processed by Terraform's template provider, passing these variables for substitution. The file will have the `.template` suffix removed when uploaded to S3."
  type        = map(string)
  default     = {}
}

variable "is_spa" {
  description = "If your website is a single page application (SPA), this sets up the cloudfront redirects such that whenever an item is not found, the file `index.html` is returned instead."
  default     = false
}

variable "csp_allow_default" {
  description = "List of default domains to include in the Content Security Policy. Typically you would list the URL of your API here if your pages access that. Always includes `'self'`."
  type    = list(string)
  default = []
}

variable "csp_allow_style" {
  description = "List of places to allow CSP to load styles from. Always includes `'self'`"
  type = list(string)
  default = []
}

variable "csp_allow_img" {
  description = "List of places to allow CSP to load images from. Always includes `'self'`"
  type = list(string)
  default = []
}

variable "csp_allow_font" {
  description = "List of places to allow CSP to load fonts from. Always includes `'self'`"
  type = list(string)
  default = [
    "https://fonts.gstatic.com"
  ]
}

variable "csp_allow_frame" {
  description = "List of places to allow CSP to load iframes from. Always includes `'self'`"
  type = list(string)
  default = []
}

variable "csp_allow_manifest" {
  description = "List of places to allow CSP to load manifests from. Always includes `'self'`"
  type = list(string)
  default = []
}

variable "mime_types" {
  description = "Map from file extension to MIME type. Defaults are provided, but you will need to provide any unusual extensions with a MIME type"
  default = {}
  type = map(string)
}

variable "refresh_auth_path" {
  description = "Path relative to `custom_domain` to redirect to when a token refresh is required"
  default = "/refreshauth"
}

variable "logout_path" {
  description = "Path relative to custom_domain to redirect to after logging out"
  default = "/"
}

variable "parse_auth_path" {
  description = "Path relative to custom_domain to redirect to upon successful authentication"
  default = "/parseauth"
}

variable "refresh_token_validity_days" {
  description = "Time until the refresh token expires and the user will be required to log in again"
  default = 3650
}

variable "is_private" {
  type = bool
  description = "Boolean, default true. Whether to make the site private (behind Cognito)"
  default = true
}

variable "create_cognito_pool" {
  type = bool
  description = "Boolean, default true. Whether to create a Cognito pool for authentication. If false, a `cognito` configuration must be provided"
  default = true
}

variable "cognito"{
  type = object({
    user_pool_arn = string
    client_id = string
    auth_domain = string
  })
  description = "Configuration block for an existing user pool. Required when `create_cognito_pool` is false"
  # Setting default to null means we'll get errors if we try to access this when create_cognito_pool is false if we haven't provided it
  default = null
}

variable "oauth_scopes" {
  type = list(string)
  default = ["openid"]
  description = "List of auth scopes to grant (or which are granted, if a Cognito pool is created externally). Options include phone, email, profile, openid, aws.cognito.signin.user.admin"
}

variable "auth_domain_prefix" {
  type = string
  # Setting default to null means we'll get errors if we try to access this when create_cognito_pool is true if we haven't provided it
  default = null
  description = "The first part of the hosted UI login domain, as in https://[AUTH_DOMAIN_PREFIX].auth.region.amazoncognito.com/"
}
