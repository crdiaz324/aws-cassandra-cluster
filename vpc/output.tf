output "bastion_public_ip" {
  value = ["${aws_instance.bastion.public_ip}"]
} 

#output "cassandra_hosts" {
#  value = [module.cassandra_cluster.instance_public_ip_addresses]
#}

output "private_subnet_ids" {
  value = [aws_subnet.private_subnets.*.id]
}

output "vpc_id" {
  value = [aws_vpc.main.id]
}

output "security_group_ids" {
  value = [aws_security_group.vpc_sg.id]
}
