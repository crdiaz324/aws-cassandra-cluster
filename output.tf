
output "bastion_public_ip" {
  value = ["${aws_instance.bastion.public_ip}"]
} 

output "cassandra_hosts" {
  value = [module.cassandra_cluster.instance_public_ip_addresses]
}

output "cassandra_availability_zones" {
  value = [module.cassandra_cluster.instance_availability_zones]
}
