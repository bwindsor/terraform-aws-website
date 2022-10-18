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
variable "alternative_custom_domain_hosted_zone_lookup" {
  description = "Mapping from alternative custom domain to hosted zone name, if the hosted zone for the alternative custom domain should be different from the hosted_zone_name input."
  type = map(string)
  default = {}
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

variable "csp_allow_script" {
  description = "List of places to allow CSP to load scripts from. Always includes `'self'`"
  type = list(string)
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

variable "csp_allow_connect" {
  description = "List of places to allow CSP to make HTTP requests to. Always includes `'self'`"
  type = list(string)
  default = []
}

variable "cache_control_max_age_seconds" {
  description = "Maximum time in seconds to cache items for before checking with the server again for an updated copy. Default is one week"
  type = number
  default = 604800
}

variable "mime_types" {
  description = "Map from file extension to MIME type. Defaults are provided, but you will need to provide any unusual extensions with a MIME type"
  default = {}
  type = map(string)
}

variable "override_file_mime_types" {
  description = "Map from exact file name to MIME type. If the specified file is available in website_dir, it will be set to the specified MIME type"
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

variable "additional_redirect_urls" {
  type = list(string)
  description = "Additional URLs to allow cognito redirects to"
  default = []
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

variable "auth_type" {
  type = string
  description = "Method of authorization when is_private is true. Options are COGNITO or BASIC"
  default = "COGNITO"
  validation {
    condition = contains(["COGNITO", "BASIC"], var.auth_type)
    error_message = "Variable auth_type must be one of the following: COGNITO, BASIC."
  }
}

variable "basic_auth_username" {
  type = string
  description = "Username to use for basic auth when is_private is true and auth_type is BASIC"
  default = null
}
variable "basic_auth_password" {
  type = string
  description = "Password to user for basic auth when is_private is true and auth_type is BASIC"
  default = null
}

variable "create_cognito_pool" {
  type = bool
  description = "Boolean, default true. Whether to create a Cognito pool for authentication. If false, a `cognito` configuration must be provided"
  default = true
}

variable "cognito"{
  type = object({
    user_pool_arn = string
    user_pool_id = string
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

variable "auth_config_path" {
  type = string
  # This should give us errors if we try to access it when is_private is true and auth_type is COGNITO and haven't provided it
  default = null
  description = "The path at which to place a file containing the Cognito auth configuration. This can then be read by your Javascript to configure your auth provider."
}

variable "log_level" {
  type = string
  default = "none"
  description = "Log level to use for auth functions. Use none in production as sensitive data may be logged"
  validation {
    condition = contains(["none", "info", "warn", "error", "debug"], var.log_level)
    error_message = "Log level must be one of the following: - none, info, warn, error, debug."
  }
}



variable "redirects" {
  description = "List of redirects specifying source and target URLs"
  default = null
  type = list(object({
    source = string
    target = string
  }))
}


variable "allow_omit_html_extension" {
  description = "Boolean, default false. If true, any URL where the final part does not contain a `.` will reference the S3 object with `html` appended. For example `https://example.com/home` would retrieve the file `home.html` from the website S3 bucket."
  default = false
  type = bool
}

variable "create_dns_records" {
  description = "Whether to create the DNS records pointing to the cloudfront distribution"
  default = true
  type = bool
}

variable "create_data_bucket" {
  description = "Whether to create an empty S3 bucket, the contents of which will be available under data_path (default /data)"
  default = false
  type = bool
}
variable "data_path" {
  description = "String, default '/data'. Only used if create_data_bucket is true. This is the path under which the contents of the data bucket will be hosted."
  default = "/data"
  type = string
}