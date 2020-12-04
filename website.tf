locals {
  mime_types = merge({
    htm   = "text/html"
    html  = "text/html"
    css   = "text/css"
    js    = "text/javascript"
    map   = "text/javascript"
    json  = "application/json"
    png   = "image/png"
    jpg   = "image/jpeg"
    jpeg  = "image/jpeg"
    ico   = "image/x-icon"
    svg   = "image/svg+xml"
    gif   = "image/gif"
    gpx   = "application/gpx+xml"
    txt   = "text/plain"
    scss  = "text/x-scss"
    eot   = "application/vnd.ms-fontobject"
    ttf   = "font/ttf"
    woff  = "font/woff"
    woff2 = "font/woff2"
    mp4   = "video/mp4"
    yaml  = "application/x-yaml"
  }, var.mime_types)
}

/* S3 buckets for frontend */
data "aws_iam_policy_document" "s3_website" {
  statement {
    effect = "Allow"
    actions = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
  statement {
    effect = "Allow"
    actions = ["s3:ListBucket"]
    resources = [aws_s3_bucket.website.arn]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.main.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "website_access_from_cloudfront" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.s3_website.json
}

resource "aws_s3_bucket" "website" {
  bucket        = "${lower(var.deployment_name)}-website-files"
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "block_direct_access" {
  bucket = aws_s3_bucket.website.id

  block_public_acls = true
  block_public_policy = true
}

resource "aws_s3_bucket" "website_alternative_redirect" {
  for_each = var.alternative_custom_domains

  bucket        = "${lower(var.deployment_name)}-website-alternative-${substr(sha256(each.value), 0, 8)}"
  acl           = "private"
  force_destroy = true

  website {
    redirect_all_requests_to = local.url
  }
}

locals {
  non_template_files = toset([for f in fileset(var.website_dir, "**") : f if replace(f, ".template.", "") == f])
  template_files     = toset([for f in fileset(var.website_dir, "**") : f if replace(f, ".template.", "") != f])
}

resource "aws_s3_bucket_object" "website_non_template_files" {
  for_each = local.non_template_files

  bucket       = aws_s3_bucket.website.id
  acl          = "private"
  content_type = lookup(var.override_file_mime_types, each.value, lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1)))
  key          = each.value
  source       = "${var.website_dir}/${each.value}"
  etag         = filemd5("${var.website_dir}/${each.value}")
}

data "template_file" "website_template_files" {
  for_each = local.template_files

  template = file("${var.website_dir}/${each.value}")
  vars     = var.template_file_vars
}

resource "aws_s3_bucket_object" "website_template_files" {
  for_each = local.template_files

  bucket       = aws_s3_bucket.website.id
  acl          = "private"
  content_type = lookup(var.override_file_mime_types, replace(each.value, ".template.", "."), lookup(local.mime_types, element(split(".", each.value), length(split(".", each.value)) - 1)))
  key          = replace(each.value, ".template.", ".")
  content      = data.template_file.website_template_files[each.value].rendered
  etag         = md5(data.template_file.website_template_files[each.value].rendered)
}

resource "aws_s3_bucket_object" "website_additional_files" {
  for_each = var.additional_files

  bucket       = aws_s3_bucket.website.id
  acl          = "private"
  content_type = lookup(var.override_file_mime_types, each.key, lookup(local.mime_types, element(split(".", each.key), length(split(".", each.key)) - 1)))
  key          = each.key
  content      = each.value
  etag         = md5(each.value)
}

locals {
  auth_config = jsonencode({
    region = data.aws_region.current.name
    userPoolId = local.user_pool_id
    userPoolWebClientId = local.cognito_client_id
    authDomain = local.auth_domain
    scopes = var.oauth_scopes
    redirectSignIn = var.parse_auth_path
    redirectSignOut = var.logout_path
  })
}
resource "aws_s3_bucket_object" "auth_configuration" {
  count = var.is_private ? 1 : 0

  bucket = aws_s3_bucket.website.id
  acl = "private"
  content_type = lookup(local.mime_types, "json")
  key = var.auth_config_path
  content = local.auth_config
  etag = md5(local.auth_config)
}
