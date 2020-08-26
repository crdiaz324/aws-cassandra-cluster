data "aws_subnet_ids" "private_ids" {
  vpc_id = var.vpc_id

  filter {
    name          = "tag:role"
    values        = ["private_subnet"]
  }
}

data "aws_instances" "seeds" {

  filter {
    name = "tag:node_type"
    values = ["cassandra"]
  }

  filter {
    name = "tag:node_number"
    values = var.seed_nodes
  }

  instance_state_names = ["pending", "running", "stopped"]

  depends_on = [ aws_instance.cassandra ]
}


data "aws_ebs_snapshot" "data_vols" {
  count             = var.instance_count
  most_recent       = true
  owners            = ["self"]

  # filter {
  #   name   = "tag:AZ"
  #   values = ["us-east-1b"]
  # }

  filter {
    name   = "tag:Name"
    values = ["data-vol-*"]
  }
}