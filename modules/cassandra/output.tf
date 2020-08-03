locals {
  this_availability_zone            = "${compact(concat(coalescelist(aws_instance.cassandra.*.availability_zone), list("")))}"
  this_key_name                     = "${compact(concat(coalescelist(aws_instance.cassandra.*.key_name), list("")))}"
  this_public_dns                   = "${compact(concat(coalescelist(aws_instance.cassandra.*.public_dns), list("")))}"
  this_public_ip                    = "${compact(concat(coalescelist(aws_instance.cassandra.*.public_ip), list("")))}"
  this_primary_network_interface_id = "${compact(concat(coalescelist(aws_instance.cassandra.*.primary_network_interface_id), list("")))}"
  this_private_dns                  = "${compact(concat(coalescelist(aws_instance.cassandra.*.private_dns), list("")))}"
  this_private_ip                   = "${compact(concat(coalescelist(aws_instance.cassandra.*.private_ip), list("")))}"
  this_vpc_security_group_ids       = "${compact(concat(coalescelist(flatten(aws_instance.cassandra.*.vpc_security_group_ids)), list("")))}"
  this_subnet_id                    = "${compact(concat(coalescelist(aws_instance.cassandra.*.subnet_id), list("")))}"
  this_tags                         = "${coalescelist(flatten(aws_instance.cassandra.*.tags))}"
  this_name                         = "${compact(concat(coalescelist(aws_instance.cassandra.*.tags.node_number)))}"
}


output "private_ip" {
  description = "List of private IP addresses assigned to the Cassandra instances"
  value       = ["${local.this_private_ip}"]
}

output "vpc_security_group_ids" {
  description = "List of associated security groups of instances, if running in non-default VPC"
  value       = ["${local.this_vpc_security_group_ids}"]
}

output "availability_zone" {
  description = "List of availability zones of instances"
  value       = ["${local.this_availability_zone}"]
}

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