terraform {
  required_version  		= "= 0.12.28"

  backend "s3" {
    encrypt 			= "false"
    region  			= "us-east-1"
    bucket  			= "carlos-tf"
    key     			= "terraform/terraform2.tfstate"
  }
}

provider "aws" {
  version    			= "~> 2.68"
  #version         = "~> 3.0"
  region     			= var.region
}

resource "aws_vpc" "main" {
  cidr_block 			= var.vpc_cidr
  tags	= {
    Name 			= var.tag_name
    Location 			= var.region
  }  
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  	= aws_vpc.main.id
  cidr_block              	= var.public_subnet_cidr
  map_public_ip_on_launch 	= "true"
  availability_zone		= element(var.azs, 0)

  tags = {
    Name          	  	= "public-${element(var.azs, 0)}-${var.tag_name}"
    Tier                = "Pupblic"
  }
}

resource "aws_subnet" "private_subnets" {
  count 			= length(var.azs) 
  vpc_id            		= aws_vpc.main.id
  cidr_block        		= element(var.private_subnet_cidrs, count.index)
  availability_zone		= element(var.azs, count.index)

  tags = {
    Name          		= "private-${element(var.azs, count.index)}-${var.tag_name}"
    Tier              = "Private"
  }
}

resource "aws_key_pair" "ec2key" {
  key_name   = "ec2PublicKey"
  public_key = file(var.public_key_path)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name          = var.tag_name
  }
}

resource "aws_eip" "nat_eip" {
  vpc = true

  tags = {
    Name          = var.tag_name
  }
}

resource "aws_route_table" "rtb_public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name          = var.tag_name
  }
}

resource "aws_route_table" "rtb_private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  route {
    cidr_block  = "192.168.99.0/24"
    instance_id = aws_instance.bastion.id
  }

  tags = {
    Name          = var.tag_name
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.subnet_public.id

  tags = {
    Name          = var.tag_name
  }
}

resource "aws_route_table_association" "rta_subnet_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.rtb_public.id
}

resource "aws_route_table_association" "rta_subnet_private" {
  count             = length(aws_subnet.private_subnets)
  subnet_id         = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id    = aws_route_table.rtb_private.id
}