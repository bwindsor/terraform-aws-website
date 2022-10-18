locals {
  # Hard corded fixed for cloudfront, see https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-route53-aliastarget.html#cfn-route53-aliastarget-hostedzoneid
  AWS_CLOUDFRONT_HOSTED_ZONE_ID = "Z2FDTNDATAQYW2"
}

data "aws_route53_zone" "hosted_zone" {
  name         = var.hosted_zone_name
  private_zone = false
}

data "aws_route53_zone" "alternative_hosted_zone" {
  for_each = var.alternative_custom_domain_hosted_zone_lookup

  name = each.value
  private_zone = false
}
locals {
  alternative_hosted_zone_ids = {for k, v in data.aws_route53_zone.alternative_hosted_zone: k => v.id}
}

resource "aws_acm_certificate" "ssl_certificate" {
  domain_name       = var.custom_domain
  subject_alternative_names = var.alternative_custom_domains
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  tags = {
    Name = var.custom_domain
  }

  provider = aws.us-east-1
}

resource "aws_route53_record" "ssl_cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.ssl_certificate.domain_validation_options: dvo.domain_name => {
      name = dvo.resource_record_name
      record = dvo.resource_record_value
      type = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = lookup(local.alternative_hosted_zone_ids, each.key, data.aws_route53_zone.hosted_zone.id)
  records = [each.value.record]
  ttl     = 60

  provider = aws.us-east-1
}

resource "aws_acm_certificate_validation" "main_website_cert" {
  certificate_arn         = aws_acm_certificate.ssl_certificate.arn
  validation_record_fqdns = [for validation in aws_route53_record.ssl_cert_validation: validation.fqdn]
  provider                = aws.us-east-1
}

resource "aws_route53_record" "main_website_A" {
  count = var.create_dns_records ? 1 : 0

  name    = aws_acm_certificate.ssl_certificate.domain_name
  type    = "A"
  zone_id = data.aws_route53_zone.hosted_zone.id

  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = local.AWS_CLOUDFRONT_HOSTED_ZONE_ID
  }
}
resource "aws_route53_record" "main_website_alternatives" {
  for_each = var.create_dns_records ? var.alternative_custom_domains : []

  name    = each.value
  type    = "A"
  zone_id = lookup(local.alternative_hosted_zone_ids, each.value, data.aws_route53_zone.hosted_zone.id)

  alias {
    evaluate_target_health = true
    name                   = aws_cloudfront_distribution.alternative_domain_distributions[each.value].domain_name
    zone_id                = local.AWS_CLOUDFRONT_HOSTED_ZONE_ID
  }
}
