variable function_name {
  type = string
  description = "Lambda function name"
}

variable bundle_file_name {
  type = string
  description = "Full path to the .js bundle of the lambda function main file"
}

variable "configuration" {
  type = object({
    userPoolArn = string,
    clientId = string,
    clientSecret = string,
    oauthScopes = list(string),
    cognitoAuthDomain = string,
    redirectPathSignIn = string,
    redirectPathSignOut = string,
    redirectPathAuthRefresh = string,
    cookieSettings = string,
    mode = string,
    httpHeaders = map(string),
    logLevel = string,
    nonceSigningSecret = string,
    cookieCompatibility = string,
    additionalCookies = map(string),
    requiredGroup = string,
    redirects = list(object({
      source = string
      target = string
    }))
    allowOmitHtmlExtension = bool
    basicAuthUsername = string
    basicAuthPassword = string
  })
  description = "Configuration for the function, to be stored in configuration.json"
}

variable "description" {
  type = string
  default = ""
  description = "Lambda function description"
}

variable lambda_role_arn {
  type = string
  description = "ARN of the lambda execution role for the function"
}

variable "handler_name" {
  type = string
  default = "handler"
  description = "Name of the main handler within the file specified by bundle_file_name. Default 'handler'"
}
