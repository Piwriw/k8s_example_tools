#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行setup_master"
    echo "export HOSTNAME=k8s-master"
    echo "export MASTER_IP=10.10.102.88"
    echo "export K8S_VERSION=v1.21.14"
    echo "export POD_SUBNET=192.168.0.0/16"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME="${HOSTNAME}
    echo "MASTER_IP="${MASTER_IP}
    echo "K8S_VERSION="${K8S_VERSION}
    echo "POD_SUBNET="${POD_SUBNET}
    echo ""
}

settime(){
  # 手动设置时间
# date -s "2023-09-20 15:46:00"
yum install ntpdate -y
ntpdate ntp3.aliyun.com
}

doScript(){
 bash ./repo-setup.sh
 bash ./homename-setup.sh ${HOSTNAME}
 bash ./docker-install.sh
 bash ./docker-conf.sh
 bash ./k8s-setup.sh
}

setupMaster(){
kubeadm init --apiserver-advertise-address=${MASTER_IP}  --image-repository registry.aliyuncs.com/google_containers --kubernetes-version ${K8S_VERSION} --service-cidr=10.96.0.0/12 --pod-network-cidr=${POD_SUBNET}
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 使用calico网络
kubectl apply -f https://docs.projectcalico.org/v3.10/manifests/calico.yaml
kubectl get po -A
}


if [ ${#HOSTNAME} -eq 0 ] || [ ${#MASTER_IP} -eq 0 ]||[ ${#POD_SUBNET} -eq 0 ]||[ ${#K8S_VERSION} -eq 0 ]; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi
settime

doScript
setupMaster