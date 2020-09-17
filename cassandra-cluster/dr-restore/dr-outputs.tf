output "instance_public_ip_addresses" {
  value = {
    for instance in aws_instance.cassandra:
    instance.tags.node_number => instance.private_ip
  }
}

output "instance_az" {
  value = local.instance_az
}

output "inst_vol_to_set" {
  value = local.inst_vol_to_set
}

output "inst_vol" {
  value = local.inst_vol
}

output "instance_to_volume_map" {
  # value = local.instance_az[0]["us-east-1b"]["i-0818a39b13ef040cd"]
  value = merge(flatten(local.inst_vol)...)
}
