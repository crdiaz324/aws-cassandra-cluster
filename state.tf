terraform {
  backend "s3" {
    encrypt 			= "false"
    region  			= "us-east-1"
    bucket  			= "test-cass-carlos"
    key     			= "terraform/terraform2.tfstate"
  }
  required_version = "0.12.28"
}