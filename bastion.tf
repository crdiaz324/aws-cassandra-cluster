resource "aws_instance" "bastion" {
  ami                    = "ami-043382c6421555804"
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.vpc_sg.id] # I need to add module.cassadra.cassandra_connectivity.id
  key_name               = aws_key_pair.ec2key.key_name
  source_dest_check      = "false"

  #lifecycle {
  #  ignore_changes = ["ami", "user_data"]
  #}

  tags = {
    Name          = var.tag_name
  }

  connection {
    host        = coalesce(self.public_ip, self.private_ip)
    type        = "ssh"
    user        = "centos"
    private_key = file(var.private_key_path)
  }

  provisioner "remote-exec" {
    inline = [
      # "echo '${file(var.private_key_path)}' > ~/.ssh/id_rsa",
      # "chmod 400 ~/.ssh/id_rsa",
      # "echo 'export TERM=xterm-256color' >> ~/.bash_profile",
      # "sudo yum update -y",
      # "sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
      # "sudo yum-config-manager --enable epel",
      # "sudo curl -L -o /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo",
      # "sudo yum install -y java-1.8.0-openjdk.x86_64 git chrony wireguard-dkms wireguard-tools iptables-services",
      # "echo '${file(var.wg_file_path)}' |sudo tee /etc/wireguard/wg0.conf",
      # "for CPUFREQ in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do     [ -f $CPUFREQ ] || continue;     echo -n performance > $CPUFREQ; done",
      # "sudo yum erase -y 'ntp*'",
      # "sudo systemctl enable iptables",
      # "sudo service chronyd start",
      # "sudo chkconfig chronyd on",
      # "echo 'net.ipv4.tcp_keepalive_time=60' |sudo tee -a /etc/sysctl.conf",
      # "echo 'net.ipv4.tcp_keepalive_probes=3' |sudo tee -a /etc/sysctl.conf",
      # "echo 'net.ipv4.tcp_keepalive_intvl=10' |sudo tee -a /etc/sysctl.conf",
      # "echo 'net.ipv4.conf.all.forwarding=1' |sudo tee -a /etc/sysctl.conf",
      # "echo 'net.ipv4.conf.all.rp_filter=1' | sudo tee -a /etc/sysctl.conf",
      # "sudo sysctl -p",
      # "echo '1       home' | sudo tee -a /etc/iproute2/rt_tables",
      # "sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE",
      # "sudo iptables-save | sudo tee /etc/sysconfig/iptables",
      "sudo wg-quick up wg0"
    ]
  }
}

