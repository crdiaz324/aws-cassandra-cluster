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