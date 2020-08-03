#! /bin/bash

echo '${file(var.private_key_path)}' >> ~/.ssh/id_rsa
chmod 400 ~/.ssh/id_rsa
echo 'export TERM=xterm-256color' >> ~/.bash_profile
sudo yum install -y java-1.8.0-openjdk.x86_64
sudo yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm",
sudo yum-config-manager --enable epel
sudo curl -L -o /etc/yum.repos.d/wireguard.repo https://copr.fedorainfracloud.org/coprs/jdoss/wireguard/repo/epel-7/jdoss-wireguard-epel-7.repo
sudo yum install -y java-1.8.0-openjdk.x86_64 git chrony htop
sudo yum erase -y 'ntp*'
sudo service chronyd start
sudo chkconfig chronyd on

# --- these settings are for my personal vpn tunnel to the vpc --- #
echo 'net.ipv4.conf.all.forwarding=1' |sudo tee -a /etc/sysctl.conf
echo 'net.ipv4.conf.all.rp_filter=1' | sudo tee -a /etc/sysctl.conf
echo '1       home' | sudo tee -a /etc/iproute2/rt_tables
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables-save | sudo tee /etc/sysconfig/iptables
sudo sysctl -p