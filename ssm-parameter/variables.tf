variable region {
  type    =string
  default = "us-east-1"
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

variable admin_user_password {
  type      = string
}

variable application_user_password {
  type      = string
}

variable monitor_user_password {
  type      = string
}