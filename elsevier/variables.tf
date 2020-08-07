############## Regions, AZ's #############################
variable region {
  default = "us-east-1"
}

variable azs {
  type    = list
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

############## VPC CIDR, ID #############################
variable vpc_cidr {
  type    = list(string)
  default = ["10.93.189.0/24", "10.164.53.0/24"]
}

variable vpc_id {
  type    = string
  default = "vpc-ed17068b"
}

variable cluster_name {
  type    = string
  default = "RRCert"
}

############## TAGS #############################
variable tag_name {
  type    = string
  default = "Carlos"
}
variable tag_product {
  type    = string
  default = "Parity"
}
variable tag_sub_product {
  type    = string
  default = "RR"
}
variable tag_contact {
  type    = string
  default = "Carlos"
}
variable tag_cost_code {
  type    = string
  default = "20879"
}
variable tag_environment {
  type    = string
  default = "UAT"
}
variable tag_orchestration {
  type    = string
  default = "https://github.com/elsevier-research/parity-mhub-terraformcontrol-nonprod"
}
variable tag_description {
  type    = string
  default = "UAT Cassandra Cluster"
}

############## KEYPAIR #############################
variable public_key_path {
  description = "Public key path"
  default     = "D:/elsevier/carlos-cass/keys/casstest_rsa.pub"
}
variable private_key_path {
  description = "Private key"
  default     = "D:/elsevier/carlos-cass/keys/casstest_rsa"
}

##############  EC2 INSTANCE #############################
variable instance_type {
  description = "the type of instances to use for this deployment"
  type        = string
  default     = "r5.2xlarge"
}
variable instance_count {
  type    = number
  default = 9
}
