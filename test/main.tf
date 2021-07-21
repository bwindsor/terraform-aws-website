provider "aws" {
  region = "eu-west-1"
}
provider "aws" {
  alias = "us-east-1"
  region = "us-east-1"
}

module "test_website" {
  source = "./.."

  custom_domain = ""
  deployment_name = ""
  hosted_zone_name = ""
  website_dir = ""

  providers = {
    aws.us-east-1: aws.us-east-1
  }
}
