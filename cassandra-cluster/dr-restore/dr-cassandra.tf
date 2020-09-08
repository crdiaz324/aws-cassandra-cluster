

data "aws_ami" "base_ami" {
  most_recent        = true
  name_regex         = "tio_base_centos7-*"
  owners             = ["702267635140"]
}

data "aws_subnet_ids" "private_ids" {
  vpc_id = var.vpc_id

  filter {
    name          = "tag:Tier"
    values        = ["Private"]
  }

}

data "aws_ebs_snapshot_ids" "data_vols" {
  owners            = ["self"]
  # prob need most recent flag
  filter {
    name   = "tag:Name"
    values = ["data-vol-*"]
  }
}

data "aws_ebs_snapshot" "data_vols" {
  count             = var.instance_count
  most_recent       = true
  owners            = ["self"]
  snapshot_ids      = [
    element(data.aws_ebs_snapshot_ids.data_vols.ids, count.index)
  ]

  filter {
    name   = "tag:Name"
    values = ["data-vol-*"]
  }
}

resource "aws_ebs_volume" "data" {
  count              = var.instance_count
  #size               = var.data_ebs_volume_size
  type               = "gp2"
  # availability_zone  = tolist(aws_instance.cassandra.*.availability_zone)[count.index]
  availability_zone = values(
                        zipmap(data.aws_ebs_snapshot.data_vols.*.snapshot_id, 
                        data.aws_ebs_snapshot.data_vols.*.tags.availability_zone
                        )
                      )[count.index]
  # availability_zone  = concat(var.azs, var.azs)[count.index]
  # snapshot_id = "snap-09ba744348f9ef8a0"
  #snapshot_id        = tolist(data.aws_ebs_snapshot.data_vols.*.snapshot_id)[count.index]
  # snapshot_id = element(
  #     matchkeys(
  #       tolist(data.aws_ebs_snapshot.data_vols.*.snapshot_id)
  #       ,tolist(data.aws_ebs_snapshot.data_vols.*.tags.availability_zone)
  #       # ,list(concat(var.azs, var.azs)[count.index]))
  #       ,list(aws_instance.cassandra.*.availability_zone)[count.index])
  #       ,1
  # )
  # Commenting out the following tag because the volumes already have
  # an attribute that ids the AZ
  # tags = { "availability_zone" = values(
  #                       zipmap(data.aws_ebs_snapshot.data_vols.*.snapshot_id, 
  #                       data.aws_ebs_snapshot.data_vols.*.tags.availability_zone
  #                       )
  #                     )[count.index]
  #         }

  snapshot_id = keys(zipmap(data.aws_ebs_snapshot.data_vols.*.snapshot_id, 
                            data.aws_ebs_snapshot.data_vols.*.tags.availability_zone
                            )
                    )[count.index]
}

resource "aws_volume_attachment" "data" {
  count       = var.instance_count

  device_name = "/dev/sdd"
  # volume_id   = tolist(aws_ebs_volume.data.*.id)[count.index]
  volume_id = lookup(merge(flatten(local.inst_vol)...), tolist(aws_instance.cassandra.*.id)[count.index])
  instance_id = tolist(aws_instance.cassandra.*.id)[count.index]
}

resource "aws_ebs_volume" "customlog" {
  count               = var.instance_count
  size               = var.customlog_ebs_volume_size
  type               = "gp2"
  availability_zone  = tolist(aws_instance.cassandra.*.availability_zone)[count.index]

  # tags = merge({
  #   Name                  = "customlog-vol-${count.index}"
  #   Description           = var.tag_description
  #   node_number           = count.index
  #   instance_private_ip   = tolist(aws_instance.cassandra.*.private_ip)[count.index]
  #   availability_zone     = tolist(aws_instance.cassandra.*.availability_zone)[count.index]
  # }, local.common_tags )
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
  ami                    = data.aws_ami.base_ami.id
  instance_type          = var.instance_type
  key_name               = var.ec2key_name
  subnet_id              = tolist(sort(data.aws_subnet_ids.private_ids.ids))[count.index%length(var.azs)]
  #user_data              = var.user_data_file_path
  vpc_security_group_ids = var.vpc_security_group_ids

  root_block_device {
    volume_type = "gp2"
    volume_size = 100
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
      "echo 'export TERM=xterm-256color' >> ~/.bash_profile",
      "sudo yum install -y java-1.8.0-openjdk.x86_64",
      "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      "sudo yum-config-manager --enable epel",
      "sudo curl -L -o /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo",
      "sudo yum install -y java-1.8.0-openjdk.x86_64 git chrony htop",
      "sudo yum erase -y 'ntp*'",
      "sudo service chronyd start",
      "sudo chkconfig chronyd on",
      #"for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do     [ -f $CPUFREQ ] || continue;     echo -n performance > $CPUFREQ; done",
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
      "sudo yum update -y",
      "sudo tee -a /etc/yum.repos.d/cassandra.repo >/dev/null <<EOT",
      "[cassandra]",
      "name=Apache Cassandra ",
      "baseurl=https://downloads.apache.org/cassandra/redhat/311x/",
      "gpgcheck=1",
      "repo_gpgcheck=1",
      "gpgkey=https://downloads.apache.org/cassandra/KEYS",
      "EOT",
      "sudo yum install -y libaio cassandra",
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
    aws_volume_attachment.customlog
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
      echo 'cassandra - memlock unlimited' | sudo tee -a /etc/security/limits.d/cass.conf
      echo 'cassandra - nofile 1048576' | sudo tee -a /etc/security/limits.d/cass.conf
      echo 'cassandra - nproc 32768' | sudo tee -a /etc/security/limits.d/cass.conf
      echo 'cassandra - as unlimited' | sudo tee -a /etc/security/limits.d/cass.conf
      sudo sed -i -e 's/#-Xms4G.*/-Xms31G/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/#-Xmx4G.*/-Xmx31G/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+UseParNewGC.*/#-XX:+UseParNewGC/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+UseConcMarkSweepGC.*/#-XX:+UseConcMarkSweepGC/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+CMSParallelRemarkEnabled.*/#-XX:+CMSParallelRemarkEnabled/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:SurvivorRatio=8.*/#-XX:SurvivorRatio=8/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:MaxTenuringThreshold=1.*/#-XX:MaxTenuringThreshold=1/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:CMSInitiatingOccupancyFraction=75.*/#-XX:CMSInitiatingOccupancyFraction=75/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+UseCMSInitiatingOccupancyOnly.*/#-XX:+UseCMSInitiatingOccupancyOnly/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:CMSWaitDuration=10000.*/#-XX:CMSWaitDuration=10000/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+CMSParallelInitialMarkEnabled.*/#-XX:+CMSParallelInitialMarkEnabled/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+CMSEdenChunksRecordAlways.*/#-XX:+CMSEdenChunksRecordAlways/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/ some JVMs will fill up their heap when accessed via JMX, see CASSANDRA-6541.*/# some JVMs will fill up their heap when accessed via JMX, see CASSANDRA-6541/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/-XX:+CMSClassUnloadingEnabled.*/#-XX:+CMSClassUnloadingEnabled/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/#-XX:+UseG1GC.*/-XX:+UseG1GC/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/#-XX:G1RSetUpdatingPauseTimePercent=5.*/-XX:G1RSetUpdatingPauseTimePercent=5/g' /etc/cassandra/conf/jvm.options
      sudo sed -i -e 's/#-XX:MaxGCPauseMillis=500.*/-XX:MaxGCPauseMillis=500/g' /etc/cassandra/conf/jvm.options
      
      # Create Data Volume
      while [ `file -s /dev/sdd |grep nvm > /dev/null; echo $?` -eq 1 ]; do
        sleep 5
        echo "Waiting for /dev/sdd symlink"
      done
      echo "Found $(file -s /dev/sdd |grep nvm)"
      dvol=$(file -s /dev/sdd |awk '{print $5}' |tr -d '`'|tr -d \')
      echo 'sudo blockdev --setra 8 /dev/$dvol' | sudo tee -a /etc/rc.local
      sudo chmod +x /etc/rc.local
      sudo mkdir /cassandra
      sudo mkdir /cassandra/data
      echo `sudo blkid | grep -i $dvol| awk '{print $2}' | tr -d '\"'` /cassandra/data xfs defaults,noatime 1 1 | sudo tee -a /etc/fstab
      sudo mount -a && sudo chown -R cassandra:cassandra /cassandra/data

      # Create Log volume
      while [ `file -s /dev/sdl |grep nvm > /dev/null; echo $?` -eq 1 ]; do
        sleep 5
        echo "Waiting for /dev/sdl symlink"
      done
      echo "Found $(file -s /dev/sdl |grep nvm)"
      lvol=$(file -s /dev/sdl |awk '{print $5}' |tr -d '`'|tr -d \')
      sudo mkfs.xfs -f /dev/$lvol
      echo 'sudo blockdev --setra 8 /dev/$lvol' | sudo tee -a /etc/rc.local
      sudo mkdir /cassandra/logs
      echo `sudo blkid | grep -i $lvol| awk '{print $2}' | tr -d '\"'` /cassandra/logs xfs defaults,noatime 1 1 | sudo tee -a /etc/fstab
      sudo mount -a && sudo chown -R cassandra:cassandra /cassandra/logs

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
      sudo sed -ci 's/authorizer: AllowAllAuthorizer/authorizer: CassandraAuthorizer/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/concurrent_reads: 32/concurrent_reads: 64/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/concurrent_writes: 32/concurrent_writes: 64/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/compaction_throughput_mb_per_sec: 16/compaction_throughput_mb_per_sec: 64/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/phi_convict_threshold: 8/phi_convict_threshold: 11/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci "s/rack=rack1/rack=${tolist(aws_instance.cassandra.*.availability_zone)[count.index]}/g" /etc/cassandra/conf/cassandra-rackdc.properties
      sudo sed -ci "s/dc=dc1/dc=us-east/g" /etc/cassandra/conf/cassandra-rackdc.properties
      echo 'JVM_OPTS="$JVM_OPTS -Dcassandra.consistent.rangemovement=false"' |sudo tee -a /etc/cassandra/conf/cassandra-env.sh
      sudo sed -ci 's/\/var\/lib\/cassandra\/data/\/cassandra\/data/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/\/var\/lib\/cassandra\/commitlog/\/cassandra\/logs\/commitlog/g' /etc/cassandra/conf/cassandra.yaml
      sudo sed -ci 's/\/var\/lib\/cassandra\/saved_caches/\/cassandra\/logs\/saved_caches/g' /etc/cassandra/conf/cassandra.yaml
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
       "sudo rm -rf /cassandra/data/saved_caches",
       "sudo service cassandra start",
    ]
  }
}

resource "null_resource" "start_cluster" {
  count                  = var.instance_count
  # Changes to any instance of the cluster will trigger a restart of the node
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
      sudo rm -rf /cassandra/data/saved_caches
      sudo service cassandra start
      EOF
    ]
  }
}