locals {
  s3_origin_id = "${var.deployment_name}-S3-website"
  s3_data_origin_id = "${var.deployment_name}-S3-data"
  dummy_origin_id = "${var.deployment_name}-dummy-origin"
  use_origin_request = var.redirects != null || var.allow_omit_html_extension == true
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Created for ${var.deployment_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  tags = {
    Name = "${var.deployment_name}-website"
  }
  // S3 main origin
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  // S3 origin to host assets (just empty bucket created, must be populated manually)
  dynamic "origin" {
    for_each = var.create_data_bucket ? [
      0] : []
    content {
      domain_name = aws_s3_bucket.data[0].bucket_regional_domain_name
      origin_id = local.s3_data_origin_id
      s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
      }
    }
  }

  // Dummy origin for requests which are handled by lambda@edge
  dynamic "origin" {
    for_each = local.is_cognito ? [
      0] : []
    content {
      domain_name = "example.com"
      origin_id = local.dummy_origin_id
      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = [
          "SSLv3",
          "TLSv1",
          "TLSv1.1",
          "TLSv1.2"]
      }
    }
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  // Main behaviour
  default_cache_behavior {
    compress = true
    allowed_methods = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"]
    cached_methods = [
      "GET",
      "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    min_ttl = var.cache_control_max_age_seconds
    default_ttl = var.cache_control_max_age_seconds
    max_ttl = var.cache_control_max_age_seconds
    smooth_streaming = false

    dynamic "lambda_function_association" {
      # This function is needed for both Cognito and Basic auth, hence the conditional on is_private and not on is_cognito
      for_each = var.is_private ? [
        0] : []
      content {
        event_type = "viewer-request"
        lambda_arn = module.lambda_edge_function[local.is_cognito ? "check-auth" : local.is_basic_auth ? "check-auth-basic" : null].qualified_arn
      }
    }

    lambda_function_association {
      event_type = "origin-response"
      lambda_arn = module.lambda_edge_function["http-headers"].qualified_arn
      include_body = false
    }

    dynamic "lambda_function_association" {
      for_each = local.use_origin_request ? [
        0] : []
      content {
        event_type = "origin-request"
        lambda_arn = module.lambda_edge_function["redirects"].qualified_arn
        include_body = false
      }
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.create_data_bucket ? [
      0] : []

    content {
      path_pattern = "${var.data_path}/*"
      allowed_methods = [
        "GET",
        "HEAD",
        "OPTIONS"]
      cached_methods = [
        "GET",
        "HEAD",
        "OPTIONS"]
      target_origin_id = local.s3_data_origin_id
      forwarded_values {
        query_string = false
        cookies {
          forward = "none"
        }
      }
      min_ttl = var.cache_control_max_age_seconds
      default_ttl = var.cache_control_max_age_seconds
      max_ttl = var.cache_control_max_age_seconds
      compress = true
      viewer_protocol_policy = "redirect-to-https"

      dynamic "lambda_function_association" {
        # This function is needed for both Cognito and Basic auth, hence the conditional on is_private and not on is_cognito
        for_each = var.is_private ? [
          0] : []
        content {
          event_type = "viewer-request"
          lambda_arn = module.lambda_edge_function[local.is_cognito ? "check-auth" : local.is_basic_auth ? "check-auth-basic" : null].qualified_arn
        }
      }

      lambda_function_association {
        event_type = "origin-response"
        lambda_arn = module.lambda_edge_function["http-headers"].qualified_arn
        include_body = false
      }

      dynamic "lambda_function_association" {
        for_each = local.use_origin_request ? [
          0] : []
        content {
          event_type = "origin-request"
          lambda_arn = module.lambda_edge_function["redirects"].qualified_arn
          include_body = false
        }
      }
    }
  }

  // Cache behaviour for parse-auth
  dynamic "ordered_cache_behavior" {
    for_each = local.is_cognito ? [
      0] : []
    content {
      compress = true
      allowed_methods = [
        "HEAD",
        "GET",
        "OPTIONS"]
      cached_methods = [
        "HEAD",
        "GET"]
      path_pattern = var.parse_auth_path
      target_origin_id = local.dummy_origin_id
      viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
        query_string = true
        cookies {
          forward = "none"
        }
      }

      lambda_function_association {
        event_type = "viewer-request"
        lambda_arn = module.lambda_edge_function["parse-auth"].qualified_arn
      }
    }
  }

  // Cache behaviour for refresh-auth
  dynamic "ordered_cache_behavior" {
    for_each = local.is_cognito ? [
      0] : []
    content {
      compress = true
      allowed_methods = [
        "HEAD",
        "GET",
        "OPTIONS"]
      cached_methods = [
        "HEAD",
        "GET"]
      path_pattern = var.refresh_auth_path
      target_origin_id = local.dummy_origin_id
      viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
        query_string = true
        cookies {
          forward = "none"
        }
      }

      lambda_function_association {
        event_type = "viewer-request"
        lambda_arn = module.lambda_edge_function["refresh-auth"].qualified_arn
      }
    }
  }

  // Cache behaviour for logout-path
  dynamic "ordered_cache_behavior" {
    for_each = local.is_cognito ? [
      0] : []
    content {
      compress = true
      allowed_methods = [
        "HEAD",
        "GET",
        "OPTIONS"]
      cached_methods = [
        "HEAD",
        "GET"]
      path_pattern = var.logout_path
      target_origin_id = local.dummy_origin_id
      viewer_protocol_policy = "redirect-to-https"
      forwarded_values {
        query_string = true
        cookies {
          forward = "none"
        }
      }

      lambda_function_association {
        event_type = "viewer-request"
        lambda_arn = module.lambda_edge_function["sign-out"].qualified_arn
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [
    var.custom_domain]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main_website_cert.certificate_arn
    ssl_support_method = "sni-only"
  }

  # Custom error response to make SPA work, always return index.html for all routes
  dynamic "custom_error_response" {
    for_each = var.is_spa ? [
      0] : []
    content {
      error_code = 404
      error_caching_min_ttl = 0
      response_page_path = "/index.html"
      response_code = 200
    }
  }

  wait_for_deployment = false
}


resource "aws_cloudfront_distribution" "alternative_domain_distributions" {
  for_each = var.alternative_custom_domains

  tags = {
    Name = "${var.deployment_name}-website-alternative-${each.value}"
  }
  origin {
    domain_name = aws_s3_bucket.website_alternative_redirect[each.value].website_endpoint
    origin_id = local.s3_origin_id
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = [
        "TLSv1"]
    }
  }

  enabled = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods = [
      "HEAD",
      "DELETE",
      "POST",
      "GET",
      "OPTIONS",
      "PUT",
      "PATCH"]
    cached_methods = [
      "GET",
      "HEAD"]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    # Set caching to 30 seconds for quick updates
    min_ttl = 30
    default_ttl = 30
    max_ttl = 30
    smooth_streaming = false
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [
    each.value]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main_website_cert.certificate_arn
    ssl_support_method = "sni-only"
  }

  wait_for_deployment = false
}
