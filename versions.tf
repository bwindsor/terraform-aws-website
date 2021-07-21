terraform {
  required_version = ">= 1.0.2"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 3.50.0"
      configuration_aliases = [aws.us-east-1]
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2.2.0"
    }
    template = {
      source = "hashicorp/template"
      version = "~>2.2.0"
    }
  }
}
