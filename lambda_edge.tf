locals {
  cspString = join("; ", [for k, v in {
    default: concat([local.auth_base_url], var.csp_allow_default),
    script: [],
    style: var.csp_allow_style,
    img: var.csp_allow_img,
    font: var.csp_allow_font,
    frame: var.csp_allow_frame,
    manifest: concat([local.auth_base_url], var.csp_allow_manifest),
  }: "${k}-src ${join(" ", concat(["'self'"], v))}"])
  headers = {
    Content-Security-Policy = local.cspString
    Strict-Transport-Security = "max-age=63072000; includeSubdomains; preload"
    X-Content-Type-Options = "nosniff"
    X-Frame-Options = "DENY"
    X-XSS-Protection = "1; mode=block"
    Referrer-Policy = "strict-origin"
  }
  cookie_settings = <<EOF
{
  "idToken": null,
  "accessToken": null,
  "refreshToken": null,
  "nonce": null
}
EOF
}

module "lambda_edge_function" {
  for_each = var.is_private ? toset(["check-auth", "http-headers", "parse-auth", "refresh-auth", "sign-out"]) : toset(["http-headers"])

  source = "./lambda_edge_function"

  bundle_file_name = "${path.module}/cloudfront-authorization-at-edge/dist/${each.value}.js"
  configuration = {
    userPoolArn = local.user_pool_arn,
    clientId = local.cognito_client_id,
    clientSecret = "",
    oauthScopes = var.oauth_scopes,
    cognitoAuthDomain = local.auth_domain,
    redirectPathSignIn = var.parse_auth_path,
    redirectPathSignOut = var.logout_path,
    redirectPathAuthRefresh = var.refresh_auth_path,
    cookieSettings = local.cookie_settings,
    mode = "spaMode",
    httpHeaders = local.headers,
    logLevel = "none",
    nonceSigningSecret = var.is_private ? random_password.nonce_secret[0].result : "",
    cookieCompatibility = "amplify",
    additionalCookies = {},
    requiredGroup = "",
  }
  function_name = "${var.deployment_name}-${each.value}"
  lambda_role_arn = aws_iam_role.iam_for_lambda_edge.arn

  providers = {
    aws.us-east-1 = aws.us-east-1
  }
}


resource "random_password" "nonce_secret" {
  count = var.is_private ? 1 : 0
  length = 16
  special = true
  override_special = "-._~"
}


resource "aws_iam_role" "iam_for_lambda_edge" {
  name               = "${var.deployment_name}-iam_for_lambda_edge"
  provider           = aws.us-east-1
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com",
          "edgelambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}


/* Policy attached to lambda execution role to allow logging */
resource "aws_iam_role_policy" "lambda_log_policy" {
  name = "${var.deployment_name}-lambda_log_policy"
  role = aws_iam_role.iam_for_lambda_edge.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:PutLogEvents",
                "logs:GetLogEvents",
                "logs:FilterLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}