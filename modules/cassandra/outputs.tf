output "instance_public_ip_addresses" {
  value = {
    for instance in aws_instance.cassandra:
    instance.tags.node_number => instance.private_ip
  }
}

output "instance_availability_zones" {
  value = {
    for instance in aws_instance.cassandra:
    instance.tags.node_number => instance.availability_zone 
  }
}

output "admin_user_password"{
  value = var.admin_role_password
}
