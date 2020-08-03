variable "cluster_name" {
	type 				        = string
  default             = "default_cluster_name"
}

variable "vpc_id" {
  type                = string
}

variable "vpc_cidr" {
  type                = string
}

variable "user_data_file_path" {
	type 				        = string
}

variable "instance_type" {
  type                = string
}

variable "instance_count" {
  type 	              = string
}

variable "tag_name" {
  type                = string
}

variable "private_key_path" {
  type                = string
  description         = "the private key that will be used for inter-node logins"
}

variable "ec2key_name" {
  type                = string
  description         = "the puplic key that will be placed on all the nodes"
}

variable "ami" {
  type                = string
}

variable "aws_subnets" {
  type                = list
}

variable "aws_subnet" {
  type                = string
  default             = ""
}

variable "vpc_security_group_ids" {
  type                = list
}

variable "availability_zone" {
  type                = string
  description         = "availability_zone the node will be placed in"
  default             = ""
}

variable "azs" {
  type                = list
  description         = "List of AZs should be equal to the default RF"
}

variable "bastion_host_ip" {
  type                = string
  description         = "the ip of a host on the public subnet"
}

variable "this_depends_on" {
  type                = any
  default             = null
}
