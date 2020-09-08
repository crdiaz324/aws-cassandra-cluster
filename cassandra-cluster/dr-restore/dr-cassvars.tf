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

locals {
  common_tags = {
    Product       = var.tag_product
    SubProduct    = var.tag_sub_product
    Contact       = var.tag_contact
    CostCode      = var.tag_cost_code
    Environment   = var.tag_environment
    Orchestration = var.tag_orchestration
  }
  # snapshot_ids = compact(concat(coalescelist(data.aws_ebs_snapshot.data_vols.*.snapshot_id), list("")))
  # snapshots = zipmap(
  #   tolist(data.aws_ebs_snapshot.data_vols.*.snapshot_id), 
  #   tolist(data.aws_ebs_snapshot.data_vols.*.tags.availability_zone)
  # )
  # ec2_instances = zipmap(
  #   tolist(aws_instance.cassandra.*.id),
  #   tolist(aws_instance.cassandra.*.availability_zone)
  # )
  # ec2_object = [
  #   for instance in aws_instance.cassandra: {
  #     instance_id = instance.id
  #     instance_az = instance.availability_zone
  #   }
  # ]

  # This local variable creates tuple of maps of maps of strings
  instance_az = [
    flatten([for instance in aws_instance.cassandra: 
      map(
        instance.availability_zone,
        zipmap(
          matchkeys(
            tolist(aws_instance.cassandra.*.id),
            tolist(aws_instance.cassandra.*.availability_zone),  
            [instance.availability_zone]
          ),
          matchkeys(
            tolist(aws_ebs_volume.data.*.id),
            tolist(aws_ebs_volume.data.*.availability_zone),        
            [instance.availability_zone]
          )
        )
      )
    ])
  ]

  # Create a set of tupes of objects
  inst_vol_to_set = {
    s = toset(local.instance_az[0])
  }
  
  # This takes the set and creates a map of instance_ids => volume_ids
  inst_vol = [
    flatten([for s in lookup(local.inst_vol_to_set, "s"): [
      for key in keys(s): [
        for idx, v in keys(s[key]): {
          "${v}" = lookup(s[key], v)
        }

      ]
    ]])
  ]

  # inst_vol = [
  #   for s in lookup(local.inst_vol2, "s"): [
  #     for key in keys(s): {
  #       map = s[key]
  #       values = values(s[key])
  #       keys = keys(s[key])
  #     }
  #   ]
  # ]

  # inst_vol = [
  #   for s in lookup(local.inst_vol2, "s"): [
  #     for key in keys(s): [
  #       for k, v in keys(s[key]): {
  #         "${k}" = v
  #       }

  #     ]
  #   ]
  # ]




  # I want to do something like this:
  # association-list = {
  #   for s in lookup(local.inst_vol2, "s"):
  #     {
  #       s => s[key]
  #     }
  #     # k => {      
  #     #   for key in keys(k[v]):
  #     #      v => ...
  #     # }
  # }

  # lookup(local.inst_vol, "s")
  #   for i, iv in local.instance_az: [
  #     for key in keys(iv): [
  #       for inst, vol in iv[key]: {
  #         instance = inst
  #         volume = vol 
  #       }
  #     ]
  #   ]
  # ] 
  

  # volume_az =  [
  #   for instance in aws_instance.cassandra: {
  #     az = instance.availability_zone
  #     vol_id = matchkeys(
  #       tolist(aws_ebs_volume.data.*.id),
  #       tolist(aws_ebs_volume.data.*.availability_zone),        
  #       [instance.availability_zone]
  #     )
  #   }
  # ]

  # instance_az = [
  #   for vol in aws_ebs_volume.data: [
  #     for instance in aws_instance.cassandra: {
  #     az = vol.availability_zone
  #     ec2_id = matchkeys(
  #       tolist(aws_instance.cassandra.*.id),
  #       tolist(aws_instance.cassandra.*.availability_zone),  
  #       [vol.availability_zone]
  #     )
  #   }]
  # ]
  # instance_to_volume = flatten([
  #   for az in local.instance_az.*.az:  [
  #     for instance in local.instance_az.[az].ec2_id: {
  #       instance_id = instance.ec2_id[1]
  #       volume_id = local.volume_az[az].vol_id[1]
  #     }
  #   ]
  # ])
}
# locals {
#   local.admin_bindings_additive = merge({
#     for role, members in local.admin_bindings : {
#       for member in members : {
#         role => member
#       }
#     }
#   })
# }