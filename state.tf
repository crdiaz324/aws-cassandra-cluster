terraform {
  backend "s3" {
    encrypt 			= "false"
    region  			= "us-east-1"
    bucket  			= "elsevier-tio-aws-rap-parity-nonprod-421093829873"
    key     			= "tfstate/dev/applications/rr/cassandra-dev-cluster.tfstate"
    #key     			= "terraform/terraform2.tfstate"
  }
  required_version = "0.12.28"
}