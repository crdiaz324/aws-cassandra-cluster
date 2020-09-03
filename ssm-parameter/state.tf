terraform {
  backend "s3" {
    encrypt 			= "true"
    region  			= "us-east-1"
    bucket  			= "carlos-tf"
    key     			= "terraform/elsevier-cassandra-ssm.tfstate"
    # bucket  			= "elsevier-tio-mhub2-988363732552"
    # key     			= "tfstate/acceptance/applications/rr/cassandra-dr-ssm-parameters.tfstate"
 }
  required_version = "0.12.28"
}