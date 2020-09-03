resource "aws_security_group" "vpc_sg" {  
  name            = "vpc_sg"
  vpc_id          = aws_vpc.main.id

#------------------ SSH access from the VPC---------------------#
  # Allow connections from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 51821 for wireguard
  ingress {
    from_port   = 51821
    to_port     = 51821
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ping
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }

  # outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

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
