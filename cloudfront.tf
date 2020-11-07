locals {
  s3_origin_id = "${var.deployment_name}-S3-website"
  dummy_origin_id = "${var.deployment_name}-dummy-origin"
}

resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "Created for ${var.deployment_name}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  tags = {
    Name = "${var.deployment_name}-website"
  }
  origin {
    domain_name = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }
  dynamic "origin" {
    for_each = var.is_private ? [0] : []
    content {
      domain_name = "example.com"
      origin_id = local.dummy_origin_id
      custom_origin_config {
        http_port = 80
        https_port = 443
        origin_protocol_policy = "match-viewer"
        origin_ssl_protocols = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
      }
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    compress = true
    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      query_string = true
      cookies {
        forward = "none"
      }
    }
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    # Set caching to 30 seconds for quick updates
    min_ttl          = 30
    default_ttl      = 30
    max_ttl          = 30
    smooth_streaming = false

    dynamic "lambda_function_association" {
      for_each = var.is_private ? [0] : []
      content {
        event_type = "viewer-request"
        lambda_arn = module.lambda_edge_function["check-auth"].qualified_arn
      }
    }

    lambda_function_association {
      event_type   = "origin-response"
      lambda_arn = module.lambda_edge_function["http-headers"].qualified_arn
      include_body = false
    }
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.is_private ? [0] : []
    content {
      compress = true
      allowed_methods = ["GET"]
      cached_methods = []
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

  dynamic "ordered_cache_behavior" {
    for_each = var.is_private ? [0] : []
    content {
      compress = true
      allowed_methods = ["GET"]
      cached_methods = []
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

  dynamic "ordered_cache_behavior" {
    for_each = var.is_private ? [0] : []
    content {
      compress = true
      allowed_methods = ["GET"]
      cached_methods = []
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

  aliases = [var.custom_domain]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main_website_cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  # Custom error response to make SPA work, always return index.html for all routes
  dynamic "custom_error_response" {
    for_each = var.is_spa ? [0] : []
    content {
      error_code            = 404
      error_caching_min_ttl = 0
      response_page_path    = "/index.html"
      response_code         = 200
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
    origin_id   = local.s3_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  enabled         = true
  is_ipv6_enabled = true

  default_cache_behavior {
    allowed_methods = ["HEAD", "DELETE", "POST", "GET", "OPTIONS", "PUT", "PATCH"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id       = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"
    # Set caching to 30 seconds for quick updates
    min_ttl          = 30
    default_ttl      = 30
    max_ttl          = 30
    smooth_streaming = false
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  aliases = [each.value]

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.main_website_cert.certificate_arn
    ssl_support_method  = "sni-only"
  }

  wait_for_deployment = false
}
