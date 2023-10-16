#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行setup_master"
    echo "export HOSTNAME=k8s-work01"
#    echo "export K8S_TOKEN=K8S_TOKEN"
    echo "DOCKER使用在线或者离线 安装 【 export DOCKER_MODEL=ONLINE | export DOCKER_MODEL=OFFLINE 】 "
    echo "备注："
    echo "当前DOCKER 只能指定为在线安装 "
    echo "DOCKER 离线安装指南： https://github.com/Piwriw/k8s_example_tools/tree/master/docker-setup-offline"
    echo ""
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME="${HOSTNAME}
    echo "DOCKER_MODEL="${DOCKER_MODEL}
#    echo "MASTER_IP="${MASTER_IP}
#    echo "K8S_VERSION="${K8S_VERSION}
#    echo "K8S_TOKEN="${K8S_TOKEN}
    echo ""
}

settime(){
  # 手动设置时间
# date -s "2023-09-20 15:46:00"
yum install ntpdate -y
ntpdate ntp3.aliyun.com
}

doScript(){
  if [ "${DOCKER_MODEL}" = "ONLINE" ]   ;then
    bash ./repo-setup.sh
    bash ./docker-install.sh
  fi

 bash ./homename-setup.sh ${HOSTNAME}
 bash ./docker-conf.sh
 bash ./load-image.sh "images/work"
 bash ./k8s-setup.sh
 echo "准备工作就绪，请执行Join"
 echo "Master 获取Token: kubeadm token create --print-join-command"
 echo "Example: kubeadm join 172.16.8.31:6443 --token whihg6.utknhvj4dg3ndsv1     --discovery-token-ca-cert-hash sha256:5d2939c6d23cde6507e621cf21d550a7e083efd4331a245c2250209bdb110b89"
}

settime

if [ ${#HOSTNAME} -eq 0 ] || [ ${#DOCKER_MODEL} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doScript
