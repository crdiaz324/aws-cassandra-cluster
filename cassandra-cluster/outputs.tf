
output "cassandra_hosts" {
  value = [module.cassandra_cluster.instance_public_ip_addresses]
}

output "cassandra_availability_zones" {
  value = [module.cassandra_cluster.instance_availability_zones]
}


