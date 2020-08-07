resource "aws_key_pair" "ec2key" {
  key_name   = "ec2PublicKey"
  public_key = file(var.public_key_path)
}

module "cassandra_cluster" {
  # referring to the module via relative path
  source                      = "./modules/cassandra"

  vpc_id                      = var.vpc_id
  vpc_cidr                    = var.vpc_cidr

  cluster_name                = var.cluster_name
  instance_count              = var.instance_count
  azs                         = var.azs
  ami                         = data.aws_ami.base_ami.id
  instance_type               = var.instance_type
  ec2key_name                 = aws_key_pair.ec2key.key_name
  
  vpc_security_group_ids      = [aws_security_group.vpc_sg.id]
  private_key_path            = var.private_key_path

  # tags
  tag_name                    = var.tag_name
  tag_contact                 = var.tag_contact   
  tag_cost_code               = var.tag_cost_code 
  tag_description             = var.tag_description
  tag_environment             = var.tag_environment
  tag_orchestration           = var.tag_orchestration
  tag_product                 = var.tag_product
  tag_sub_product             = var.tag_sub_product
}