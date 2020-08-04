variable "aws_access_key_id" {
    type 		         = string
    description 	   = "Aws acess key"
}

variable "aws_secret_access_key" {
    type 		         = string
    description 	   = "aws secret access key"
}

#---------- Region Specific Settings ---------------#
variable "region" {
  default 		       = "us-east-1"
}

variable "azs" {
  type 			         = list
  default 		       = ["us-east-1a", "us-east-1b", "us-east-1c"]
}


#-------------------- Networking Settings ---------------#
variable "vpc_cidr" {
  default 		       = "10.1.0.0/16"
}

variable "private_subnet_cidrs" {
  type			         = list
  default 		       = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
}

variable "public_subnet_cidr" {
  default 		       = "10.1.0.0/24"
}


#-------------------Tags -------------------------#
variable "tag_name" {
  type 			         = string
  default 		       = "Carlos"
}

#------------------ Files ------------------------#
variable "public_key_path" {
  description        = "Public key path"
  default            = "~/.ssh/aws_rsa.pub"
}

variable "private_key_path" {
  description        = "Private key"
  default            = "~/.ssh/aws_rsa"
}

variable "user_data_file_path"  {
  description        = "Path to user_data file"
  default            = "./user_data.sh"
}

variable "wg_file_path" {
  description = "WG config path"
  default     = "~/.aws/wg0.conf"
}


#---------------- EC2 Instance Settings -------------#
# Base AMI
data "aws_ami" "base_ami" {
  most_recent        = true
  name_regex         = "tio_base_centos7-*"
  owners             = ["702267635140"]
}

variable  "instance_type" {
  description        = "the type of instances to use for this deployment"
  type               = string
  default            = "m5.large"
}

#-------------- Used for module dependencies --------------#
variable "this_depends_on" {
  type    = any
  default = null
}