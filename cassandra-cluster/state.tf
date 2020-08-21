terraform {
  backend "s3" {
    encrypt 			= "true"
    region  			= "us-east-1"
    bucket  			= "elsevier-tio-aws-rap-parity-nonprod-421093829873"
    key     			= "tfstate/dev/applications/rr/cassandra-dev-cluster.tfstate"
  }
  required_version = "0.12.28"
}