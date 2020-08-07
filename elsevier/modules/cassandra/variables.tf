variable cluster_name {
	type 				        = string
  default             = "default_cluster_name"
}

################ EC2 CONFIGURATIONS ################
variable root_volume_size {
  type    = number
  default = 100
}
variable ebs_volume_size {
  type    = number
  default = 1024
}
variable instance_type {
  type = string
}
variable instance_count {
  type  = number
}
variable private_key_path {
  type                = string
  description         = "the private key that will be used for inter-node logins"
}
variable ec2key_name {
  type                = string
  description         = "the puplic key that will be placed on all the nodes"
}
variable ami {
  type                = string
}

################ VPC, SECURITY GROUPS ################
variable vpc_id {
  type                = string
}
variable vpc_cidr {
  type = list
}
variable vpc_security_group_ids {
  type                = list
}
variable azs {
  type                = list
  description         = "List of AZs should be equal to the default RF"
}
variable seed_nodes{
  type      = list(number)
  default   = [0,1,2]
}

################ TAG CONFIGURATIONS ################
variable tag_name {
  type  = string
}
variable tag_description {
  type      = string
  default   = "Cassandra cluster nodes"
}
variable tag_product {
  type      = string
  default   = "REPLACE_ME"
}
variable tag_sub_product {
  type      = string
  default   = "REPLACE_ME"
} 
variable tag_contact  {
  type      = string
  default   = "REPLACE_ME"
}            
variable tag_cost_code {
  type      = string
  default   = "REPLACE_ME"
}
variable tag_environment {
   type      = string
   default   = "REPLACE_ME"
}  
variable tag_orchestration {
    type      = string
    default   = "REPLACE_ME"
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

variable this_depends_on {
  type                = any
  default             = null
}
