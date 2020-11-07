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
