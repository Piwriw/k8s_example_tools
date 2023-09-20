#!/bin/bash
set -e
# 需要传递harbor  hostname:ip  h
hostname="$1"
initYum(){
  yum install -y wget
  mkdir /etc/yum.repos.d/bak && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
  wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo
  wget -O /etc/yum.repos.d/epel.repo http://mirrors.cloud.tencent.com/repo/epel-7.repo
  yum clean all && yum makecache
}
setHostname(){
  hostnamectl set-hostname $hostname
  echo "`ip -4 addr show scope global | awk '/inet/ {print $2; exit}' | cut -d '/' -f1` $hostname" >> /etc/hosts
  /etc/init.d/network restart
}
setupdocker(){

  curl -k -fsSL https://get.docker.com -o get-docker.sh
  sh get-docker.sh --version 20.10
  systemctl start docker
  systemctl enable docker
    touch /etc/docker/daemon.json
    echo '{ "exec-opts": ["native.cgroupdriver=systemd"] }' > /etc/docker/daemon.json
      systemctl restart docker
}
setupK8s(){
    bash ./k8s-setup.sh
    # 不使用可能会出现 sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables
    modprobe  br_netfilter
    yum install -y kubeadm-1.20.4 kubelet-1.20.4 kubectl-1.20.4
    systemctl start kubelet
    systemctl enable kubelet
    # 需要修改
    kubeadm join 10.10.101.158:6443 --token m6ygdj.wrlffvuvofffj2c5 --discovery-token-ca-cert-hash sha256:fb74344fe281551bf7c32e1959a1d5a5439a8fa8a5ee209adb4eab0a568b8990
}

if [ -z "$hostname" ]; then
    echo "没有提供参数 需要hostname"
    exit 1  # 退出脚本，并返回非零退出状态
fi

initYum
setHostname
setupdocker
setupK8s