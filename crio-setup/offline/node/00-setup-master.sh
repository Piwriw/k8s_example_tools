#!/bin/bash
set -e
bashpath=$(cd `dirname $0`; pwd)

usage() {
    echo "使用说明："
    echo "导入以下参数再执行01-setup_master"
    echo "export HOSTNAME=k8s-master"
    echo "export MASTER_IP=10.10.102.88"
    echo "export K8S_VERSION=v1.25.14"
    echo "export POD_SUBNET=192.168.0.0/16"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME="${HOSTNAME}
    echo "MASTER_IP="${MASTER_IP}
    echo "K8S_VERSION="${K8S_VERSION}
    echo "POD_SUBNET="${POD_SUBNET}
    echo "DOCKER_MODEL="${DOCKER_MODEL}
    echo ""
}

settime(){
  # 手动设置时间
# date -s "2023-09-20 15:46:00"
yum install ntpdate -y
ntpdate ntp2.aliyun.com
}

doScript(){

 bash $bashpath/homename-setup.sh ${HOSTNAME}
 bash $bashpath/02-close-firewalld.sh
 bash $bashpath/load-image.sh "images/master"
}

setupMaster(){
kubeadm init --apiserver-advertise-address=${MASTER_IP}  --image-repository registry.aliyuncs.com/google_containers \
--kubernetes-version ${K8S_VERSION} --service-cidr=10.96.0.0/12 --pod-network-cidr=${POD_SUBNET} \
--cri-socket=unix:///var/run/crio/crio.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 使用calico网络，关闭了EBPF的挂载路径，需要升级内核才能使用
kubectl apply -f $bashpath/yaml/calico-3.10.yaml
kubectl get po -A
}

# modprobe  br_netfilter
# 如果出现
#sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-ip6tables: No such file or directory
#sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables: No such file or directory

if [ ${#HOSTNAME} -eq 0 ] || [ ${#MASTER_IP} -eq 0 ]||[ ${#POD_SUBNET} -eq 0 ]||[ ${#K8S_VERSION} -eq 0 ] || [ ${#DOCKER_MODEL} -eq 0 ]; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

settime
doScript
setupMaster