resource "aws_security_group" "cassandra_connectivity" {
  name            = "cassandra_connectivity"
  vpc_id          = var.vpc_id

    # Promethius for monitoring
  ingress {
    from_port     = 9090
    to_port       = 9090
    protocol      = "tcp"
    cidr_blocks   = [var.vpc_cidr]
  }

  # CQL access from the VPC
  ingress {
    from_port     = 9042
    to_port       = 9042
    protocol      = "tcp"
    cidr_blocks   = [var.vpc_cidr]
  }

  # internode communication from the VPC
  ingress {
    from_port     = 7000
    to_port       = 7000
    protocol      = "tcp"
    cidr_blocks   = [var.vpc_cidr]
  }

  # jmx communication from VPC
  ingress {
    from_port     = 7199
    to_port       = 7199
    protocol      = "tcp"
    cidr_blocks   = [var.vpc_cidr]
  }  
}