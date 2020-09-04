variable "region" {
  default 		       = "us-east-1"
}

variable "cluster_name" {
	type 				        = string
  default             = "cass-test-disaster-recovery"
}

variable "vpc_id" {
  type                = string
  default             = "vpc-08fa759a37699abc0"
}

variable "vpc_cidr" {
  type                = string
  default 		       = "10.1.0.0/16"
}

variable "user_data_file_path" {
	type 				        = string
  default            = "./user_data.sh"
}

variable "instance_type" {
  type        = string
  default     = "r5.2xlarge"
}

variable "instance_count" {
  type    = number
  default = 6
}

# variable "tag_name" {
#   type                = string
# }

variable "private_key_path" {
  type                = string
  description         = "the private key that will be used for inter-node logins"
  default             = "~/.ssh/aws_rsa"
}

variable "ec2key_name" {
  type                = string
  description         = "the puplic key that will be placed on all the nodes"
  default             = "ec2PublicKey2"
}

# variable "ami" {
#   type                = string
# }

# variable "aws_subnets" {
#   type                = list
# }

# variable "aws_subnet" {
#   type                = string
#   default             = ""
# }

variable "vpc_security_group_ids" {
  type                = list
  default             = ["sg-054ee9bd1e66a9841"]
}

variable "availability_zone" {
  type                = string
  description         = "availability_zone the node will be placed in"
  default             = ""
}

variable "azs" {
  type                = list
  description         = "List of AZs should be equal to the default RF"
  default = ["us-east-1a", "us-east-1b","us-east-1c"]
}

variable "bastion_host_ip" {
  type                = string
  description         = "the ip of a host on the public subnet"
  default             = "54.86.97.134"
}

variable "this_depends_on" {
  type                = any
  default             = null
}

variable customlog_ebs_volume_size {
  type    = number
  default = 50
}

############## TAGS #############################
variable tag_name {
  type    = string
  default = "Carlos-Restore"
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
  default = "dev-restore"
}
variable tag_orchestration {
  type    = string
  default = ""
}
variable tag_description {
  type    = string
  default = "Restored Cassandra Cluster"
}

variable snapshots {
  type = list
  default = []
}

locals {
  snapshots = zipmap(
    data.aws_ebs_snapshot.data_vols.*.snapshot_id, 
    data.aws_ebs_snapshot.data_vols.*.tags.availability_zone
  )
  common_tags = {
    Product       = var.tag_product
    SubProduct    = var.tag_sub_product
    Contact       = var.tag_contact
    CostCode      = var.tag_cost_code
    Environment   = var.tag_environment
    Orchestration = var.tag_orchestration
  }
}

