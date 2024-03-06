#!/bin/bash
set -e
bashpath=$(cd `dirname $0`; pwd)

usage() {
    echo "使用说明："
    echo "导入以下参数再执行setup_master"
    echo "export HOSTNAME=k8s-work01"
#    echo "export K8S_TOKEN=K8S_TOKEN"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME="${HOSTNAME}
#    echo "MASTER_IP="${MASTER_IP}
#    echo "K8S_VERSION="${K8S_VERSION}
#    echo "K8S_TOKEN="${K8S_TOKEN}
    echo ""
}


doScript(){


 bash $bashpath/01-close-firewalld.sh
 bash $bashpath/02-homename-setup.sh  ${HOSTNAME}
 bash $bashpath/03-load-image.sh $bashpath/../images/work
 bash $bashpath/04-install-crio.sh

 echo "准备工作就绪，请执行Join"
 echo "Master 获取Token: kubeadm token create --print-join-command"
 echo "Example: kubeadm join 172.16.8.31:6443 --token whihg6.utknhvj4dg3ndsv1     --discovery-token-ca-cert-hash sha256:5d2939c6d23cde6507e621cf21d550a7e083efd4331a245c2250209bdb110b89"
}


if [ ${#HOSTNAME} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doScript
