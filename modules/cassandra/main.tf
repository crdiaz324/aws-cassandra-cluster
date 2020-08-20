resource "aws_ebs_volume" "data" {
  count              = var.instance_count

  size               = var.data_ebs_volume_size
  type               = "gp2"
  availability_zone  = tolist(aws_instance.cassandra.*.availability_zone)[count.index]

  tags = merge({
    Name                  = "data-vol-${count.index}"
    Description           = var.tag_description
    node_number           = count.index
    instance_private_ip   = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    availability_zone     = tolist(aws_instance.cassandra.*.availability_zone)[count.index]
  }, local.common_tags)
}

 resource "aws_ebs_volume" "customlog" {
  count               = var.instance_count

  size               = var.customlog_ebs_volume_size
  type               = "gp2"
  availability_zone  = tolist(aws_instance.cassandra.*.availability_zone)[count.index]

  tags = merge({
    Name                  = "customlog-vol-${count.index}"
    Description           = var.tag_description
    node_number           = count.index
    instance_private_ip   = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    availability_zone     = tolist(aws_instance.cassandra.*.availability_zone)[count.index]
  }, local.common_tags)
 }

resource "aws_volume_attachment" "data" {
  count       = var.instance_count

  device_name = "/dev/sdd"
  volume_id   = tolist(aws_ebs_volume.data.*.id)[count.index]
  instance_id = tolist(aws_instance.cassandra.*.id)[count.index]
}

resource "aws_volume_attachment" "customlog" {
  count       = var.instance_count

  device_name = "/dev/sdl"
  volume_id   = tolist(aws_ebs_volume.customlog.*.id)[count.index]
  instance_id = tolist(aws_instance.cassandra.*.id)[count.index]
}

# Spin up cassandra instances
resource "aws_instance" "cassandra" {
  count                  = var.instance_count

  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.ec2key_name
  subnet_id              = tolist(sort(data.aws_subnet_ids.private_ids.ids))[count.index%length(var.azs)]
  vpc_security_group_ids = var.vpc_security_group_ids


  root_block_device {
    volume_type = "gp2"
    volume_size = var.root_volume_size
  }

  tags = merge({
      Name                = "${var.tag_environment}.${var.tag_sub_product}.${count.index}"
      Description         = var.tag_description
      node_type           = "cassandra"
      node_number         = count.index
    }, local.common_tags)
  
  connection {
    type             = "ssh"
    user             = "centos"
    host             = self.private_ip
    private_key      = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "echo '${file(var.private_key_path)}' > ~/.ssh/id_rsa",
      "chmod 400 ~/.ssh/id_rsa",
      "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      "sudo yum-config-manager --enable epel",
      "sudo yum install -y java-1.8.0-openjdk.x86_64 git htop",
      "sudo yum erase -y 'ntp*'",
      "sudo service chronyd start",
      "sudo chkconfig chronyd on",
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
      "echo never | sudo tee /sys/kernel/mm/transparent_hugepage/defrag",
      "sudo tee -a /etc/yum.repos.d/cassandra.repo >/dev/null <<EOF",
      "[cassandra]",
      "name=Apache Cassandra ",
      "baseurl=https://downloads.apache.org/cassandra/redhat/311x/",
      "gpgcheck=1",
      "repo_gpgcheck=1",
      "gpgkey=https://downloads.apache.org/cassandra/KEYS",
      "EOF",
      "sudo yum install -y libaio cassandra",
      "echo 'cassandra - memlock unlimited' | sudo tee -a /etc/security/limits.d/cass.conf",
      "echo 'cassandra - nofile 1048576' | sudo tee -a /etc/security/limits.d/cass.conf",
      "echo 'cassandra - nproc 32768' | sudo tee -a /etc/security/limits.d/cass.conf",
      "echo 'cassandra - as unlimited' | sudo tee -a /etc/security/limits.d/cass.conf",
      "sudo sed -i -e 's/#-Xms4G.*/-Xms31G/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/#-Xmx4G.*/-Xmx31G/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+UseParNewGC.*/#-XX:+UseParNewGC/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+UseConcMarkSweepGC.*/#-XX:+UseConcMarkSweepGC/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+CMSParallelRemarkEnabled.*/#-XX:+CMSParallelRemarkEnabled/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:SurvivorRatio=8.*/#-XX:SurvivorRatio=8/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:MaxTenuringThreshold=1.*/#-XX:MaxTenuringThreshold=1/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:CMSInitiatingOccupancyFraction=75.*/#-XX:CMSInitiatingOccupancyFraction=75/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+UseCMSInitiatingOccupancyOnly.*/#-XX:+UseCMSInitiatingOccupancyOnly/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:CMSWaitDuration=10000.*/#-XX:CMSWaitDuration=10000/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+CMSParallelInitialMarkEnabled.*/#-XX:+CMSParallelInitialMarkEnabled/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+CMSEdenChunksRecordAlways.*/#-XX:+CMSEdenChunksRecordAlways/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/ some JVMs will fill up their heap when accessed via JMX, see CASSANDRA-6541.*/# some JVMs will fill up their heap when accessed via JMX, see CASSANDRA-6541/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/-XX:+CMSClassUnloadingEnabled.*/#-XX:+CMSClassUnloadingEnabled/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/#-XX:+UseG1GC.*/-XX:+UseG1GC/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/#-XX:G1RSetUpdatingPauseTimePercent=5.*/-XX:G1RSetUpdatingPauseTimePercent=5/g' /etc/cassandra/conf/jvm.options",
      "sudo sed -i -e 's/#-XX:MaxGCPauseMillis=500.*/-XX:MaxGCPauseMillis=500/g' /etc/cassandra/conf/jvm.options",
      "sudo yum install xfsprogs",
      "sudo yum update -y",
    ]
  }
}

resource "null_resource" "post_volume_attachment"{
  
  count                   = var.instance_count
  depends_on              = [aws_volume_attachment.data]

  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    private_key      = file(var.private_key_path)
  }

 # TODO: Here the device link name hardcoded, this something we tried with device name but did not seems to work. Hence hardcoded.
 # Tried the link https://binx.io/blog/2019/01/26/how-to-mount-an-ebs-volume-on-nvme-based-instance-types/ -- but no luck 
 provisioner "remote-exec" {
    inline = [
              "sudo mkfs.xfs -f /dev/nvme1n1",
              "echo 'sudo blockdev --setra 8 /dev/nvme1n1' | sudo tee -a /etc/rc.local",
              "sudo chmod +x /etc/rc.local",
              "sudo mkdir /cassandra",
              "sudo mkdir /cassandra/data",
              "echo `sudo blkid | grep -i nvme1n1 | awk '{print $2}' | tr -d '\"'` /cassandra/data xfs defaults,noatime 1 1 | sudo tee -a /etc/fstab",
              "sudo mount -a && sudo chown -R cassandra:cassandra /cassandra/data",
              
              "sudo mkfs.xfs -f /dev/nvme2n1",
              "echo 'sudo blockdev --setra 8 /dev/nvme2n1' | sudo tee -a /etc/rc.local",
              "sudo mkdir /cassandra/logs",
              "echo `sudo blkid | grep -i nvme2n1 | awk '{print $2}' | tr -d '\"'` /cassandra/logs xfs defaults,noatime 1 1 | sudo tee -a /etc/fstab",
              "sudo mount -a && sudo chown -R cassandra:cassandra /cassandra/logs"
    ]
  }
}

resource "null_resource" "configure_cassandra" {
  count                  = var.instance_count
  
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.cassandra.*.id)}"
  }

  depends_on = [ aws_instance.cassandra ]

  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    private_key      = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [<<EOF
      while [ ! -f /etc/cassandra/conf/cassandra.yaml ]
      do
        sleep 10
      done
        sudo sed -ci "s/cluster_name: 'Test Cluster'/cluster_name: '${var.cluster_name}'/g" /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/num_tokens: 256/num_tokens: 8/g' /etc/cassandra/conf/cassandra.yaml
        export ip=`hostname -I` && sudo sed -ci "s/listen_address: localhost/listen_address: $ip/g" /etc/cassandra/conf/cassandra.yaml
        export ip=`hostname -I` && sudo sed -ci "s/rpc_address: localhost/rpc_address: $ip/g" /etc/cassandra/conf/cassandra.yaml
        export ip=`hostname -I` && sudo sed -ci "s/endpoint_snitch: SimpleSnitch/endpoint_snitch: GossipingPropertyFileSnitch/g" /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/seeds:.*/seeds: "${replace(join(", ", (data.aws_instances.seeds.private_ips)), "'", "")}"/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/authenticator: AllowAllAuthenticator/authenticator: PasswordAuthenticator/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/concurrent_reads: 32/concurrent_reads: 64/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/concurrent_writes: 32/concurrent_writes: 64/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/compaction_throughput_mb_per_sec: 16/compaction_throughput_mb_per_sec: 64/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci 's/phi_convict_threshold: 8/phi_convict_threshold: 11/g' /etc/cassandra/conf/cassandra.yaml
        sudo sed -ci "s/rack=rack1/rack=${tolist(aws_instance.cassandra.*.availability_zone)[count.index]}/g" /etc/cassandra/conf/cassandra-rackdc.properties
        sudo sed -ci "s/dc=dc1/dc=us-east/g" /etc/cassandra/conf/cassandra-rackdc.properties
        echo 'JVM_OPTS="$JVM_OPTS -Dcassandra.consistent.rangemovement=false"' |sudo tee -a /etc/cassandra/conf/cassandra-env.sh

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
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service cassandra start"
    ]
  }
}

resource "null_resource" "start_cluster" {
  count                  = var.instance_count
  # Changes to any instance of the cluster will trigger a restart of the node
  triggers = {
    cluster_instance_ids = "${join(",", aws_instance.cassandra.*.id)}"
  }

  depends_on = [ null_resource.start_seed ]
  
  connection {
    type             = "ssh"
    user             = "centos"
    host             = tolist(aws_instance.cassandra.*.private_ip)[count.index]
    private_key      = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      "sudo service cassandra start"
    ]
  }
}