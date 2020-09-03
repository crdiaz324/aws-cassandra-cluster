############## Regions, AZ's #############################
variable region {
  default = "us-east-1"
}

variable azs {
  type    = list
  default = ["us-east-1a", "us-east-1b","us-east-1c"]
}

############## VPC CIDR, ID #############################
variable vpc_cidr {
  type    = list(string)
  default = ["10.1.0.0/16"]
}

variable vpc_id {
  type    = string
  default = "vpc-08fa759a37699abc0"
}

variable cluster_name {
  type    = string
  default = "cass-test-disaster-recovery"
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
  default = "22519"
}
variable tag_environment {
  type    = string
  default = "dev"
}
variable tag_orchestration {
  type    = string
  default = ""
}
variable tag_description {
  type    = string
  default = "DEV Cassandra Cluster"
}

locals {
  common_tags = {
    Product       = var.tag_product
    SubProduct    = var.tag_sub_product
    Contact       = var.tag_contact
    CostCode      = var.tag_cost_code
    Environment   = var.tag_environment
    Orchestration = var.tag_orchestration
  }
}

############## KEYPAIR #############################
variable public_key_path {
  description = "Public key path"
  default     = "~/.ssh/aws_rsa.pub"
}
variable private_key_path {
  description = "Private key"
  default     = "~/.ssh/aws_rsa"
}

##############  EC2 INSTANCE #############################
variable instance_type {
  description = "the type of instances to use for this deployment"
  type        = string
  default     = "r5.2xlarge"
}
variable instance_count {
  type    = number
  default = 6
}
variable aws_security_group_name{
   type    = string
  default = "sg_dev_cassandra_cluster"
}
variable aws_keypair_name {
  type    = string
  default = "dev_cassandra_cluster"
}


############## ROLES FOR CASSANDRA #######################
variable admin_role {
  type    = string
  default = "RRAdminUser"
}

variable application_role {
  type    = string
  default = "RRApplicationUser"
}

variable monitor_role {
  type    = string
  default = "RRMonitorUser"
}