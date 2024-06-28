locals {
  url = "https://${var.custom_domain}"
}

output "url" {
  description = "URL of the main website"
  value = local.url
}

output "alternate_urls" {
  description = "Alternate URLs of the website"
  value = formatlist("https://%s", var.alternative_custom_domains)
}

output "user_pool_arn" {
  description = "ARN of Cognito user pool being used"
  value = local.user_pool_arn
}

output "bucket_name" {
  description = "Bucket with the website files"
  value = aws_s3_bucket.website.bucket
}

output "data_bucket_name" {
  description = "Data bucket name, if create_data_bucket input is true"
  value = var.create_data_bucket ? aws_s3_bucket.data[0].bucket : ""
}
