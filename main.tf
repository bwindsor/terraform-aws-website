/*
These are proxy provider blocks, they just declare that the calling module must explicitly
pass aws.us-east-1 as an additional provider
*/
provider "aws" {
  alias = "us-east-1"
}
