#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行setup_master"
    echo "export HOSTNAME=k8s-work"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME="${HOSTNAME}
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

settime

if [ ${#HOSTNAME} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doScript
