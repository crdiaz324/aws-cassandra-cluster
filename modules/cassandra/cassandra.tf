
data "aws_subnet_ids" "private_ids" {
  vpc_id = var.vpc_id

  filter {
    name          = "tag:Tier"
    values        = ["Private"]
  }

}


# Spin up cassandra instances
resource "aws_instance" "cassandra" {
  count                  = var.instance_count
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.ec2key_name
  subnet_id              = tolist(sort(data.aws_subnet_ids.private_ids.ids))[count.index%length(var.azs)]
  user_data              = var.user_data_file_path
  vpc_security_group_ids = var.vpc_security_group_ids


  root_block_device {
    volume_type = "gp2"
    volume_size = 100
  }

  ebs_block_device {
    device_name = "/dev/sdb"
    volume_type = "gp2"
    volume_size = 1024
    encrypted   = true
  }

  
  tags = {
      # DO NOT DELET THIS TAG!
      node_type = "cassandra"
      #######################
      node_number         = count.index
      name                = var.tag_name
  }
  
  connection {
    type             = "ssh"
    user             = "centos"
    host             = self.private_ip
    private_key      = file(var.private_key_path)
    bastion_host     = var.bastion_host_ip
    bastion_user     = "centos"
    bastion_host_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${file(var.private_key_path)}' > ~/.ssh/id_rsa",
      "chmod 400 ~/.ssh/id_rsa",
      "for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do     [ -f $CPUFREQ ] || continue;     echo -n performance > $CPUFREQ; done",
      "echo 'net.ipv4.tcp_keepalive_time=60' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.tcp_keepalive_probes=3' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.tcp_keepalive_intvl=10' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.core.rmem_max=16777216'|sudo tee -a /etc/sysctl.conf",
      "echo 'net.core.wmem_max=16777216' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.core.rmem_default=16777216' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.core.wmem_default=16777216' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.core.optmem_max=40960' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.tcp_rmem=4096 87380 16777216' |sudo tee -a /etc/sysctl.conf",
      "echo 'net.ipv4.tcp_wmem=4096 65536 16777216'  |sudo tee -a /etc/sysctl.conf",
      "echo 'vm.max_map_count = 1048575'  |sudo tee -a /etc/sysctl.conf",
      "echo 'vm.dirty_background_bytes = 10485760'  |sudo tee -a /etc/sysctl.conf",
      "echo 'vm.dirty_bytes = 1073741824'  |sudo tee -a /etc/sysctl.conf",
      "echo 'vm.zone_reclaim_mode = 0'  |sudo tee -a /etc/sysctl.conf",
      "sudo sysctl -p",
      "echo 'cassandra - memlock unlimited' | sudo tee -a /etc/security/limits.d/cassandra.conf",
      "echo 'cassandra - nofile 1048576' | sudo tee -a /etc/security/limits.d/cassandra.conf",
      "echo 'cassandra - nproc 32768' | sudo tee -a /etc/security/limits.d/cassandra.conf",
      "echo 'cassandra - as unlimited' | sudo tee -a /etc/security/limits.d/cassandra.conf",
      "echo never | sudo tee -a /sys/kernel/mm/transparent_hugepage/defrag",
      "sudo mkfs.xfs -f /dev/sdb",
      "echo 'sudo blockdev --setra 8 /dev/sdb' | sudo tee -a /etc/rc.local",
      "sudo chmod +x /etc/rc.local",
      "sudo mkdir /var/lib/cassandra",
      "echo '/dev/sdb  /var/lib/cassandra  xfs  defaults,noatime 1 1' |sudo tee -a /etc/fstab",
      "sudo mount -a",
      "sudo chown -R cassandra:cassandra /var/lib/cassandra",
      "sudo tee -a /etc/yum.repos.d/cassandra.repo >/dev/null <<EOF",
      "[cassandra]",
      "name=Apache Cassandra ",
      "baseurl=https://downloads.apache.org/cassandra/redhat/311x/",
      "gpgcheck=1",
      "repo_gpgcheck=1",
      "gpgkey=https://downloads.apache.org/cassandra/KEYS",
      "EOF",
      "sudo yum install -y libaio cassandra",
      "sudo yum update -y",
    ]
  }
}

data "aws_instances" "seeds" {

  filter {
    name = "tag:node_type"
    values = ["cassandra"]
  }

  filter {
    name = "tag:node_number"
    values = [0,1,2]
  }

  instance_state_names = ["pending", "running", "stopped"]

  depends_on = [
    aws_instance.cassandra
  ]
}


resource "null_resource" "configure_cassandra" {
  count                  = var.instance_count
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.cassandra.*.id)}"
  }

  depends_on = [
    aws_instance.cassandra
  ]

  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    private_key      = file(var.private_key_path)
    bastion_host     = var.bastion_host_ip
    bastion_user     = "centos"
    bastion_host_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [<<EOF
      sudo sed -ci "s/cluster_name: 'Test Cluster'/cluster_name: '${var.cluster_name}'/g" /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/num_tokens: 256/num_tokens: 8/g' /etc/cassandra/conf/cassandra.yaml
      export ip=`hostname -I` && sudo sed -ci "s/listen_address: localhost/listen_address: $ip/g" /etc/cassandra/conf/cassandra.yaml
      export ip=`hostname -I` && sudo sed -ci "s/rpc_address: localhost/rpc_address: $ip/g" /etc/cassandra/conf/cassandra.yaml
      export ip=`hostname -I` && sudo sed -ci "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: GossipingPropertyFileSnitch/g" /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/seeds:.*/seeds: "${replace(join(",", (data.aws_instances.seeds.private_ips)), "'", "")}"/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci "s/rack=rack1/rack=${tolist(aws_instance.cassandra.*.availability_zone)[count.index]}/g" /etc/cassandra/conf/cassandra-rackdc.properties
      sudo sed -ci "s/dc=dc1/dc=us-east/g" /etc/cassandra/conf/cassandra-rackdc.properties
      sudo chkconfig cassandra on
      EOF
    ]
  }
}


resource "null_resource" "start_seed" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.cassandra.*.id)}"
  }

  depends_on = [
    null_resource.configure_cassandra
  ]

  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[0]
    private_key      = file(var.private_key_path)
    bastion_host     = var.bastion_host_ip
    bastion_user     = "centos"
    bastion_host_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service cassandra start"
    ]
  }
}

resource "null_resource" "start_cluster" {
  count                  = var.instance_count
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.cassandra.*.id)}"
  }

  depends_on = [
    null_resource.start_seed
  ]

  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    private_key      = file(var.private_key_path)
    bastion_host     = var.bastion_host_ip
    bastion_user     = "centos"
    bastion_host_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [<<EOF
      sudo service cassandra start
      EOF
    ]
  }
}

