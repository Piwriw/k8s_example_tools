#!/bin/bash
set -e

EDGESTACK_TEMP_DIR=$(mktemp -d)
export EDGESTACK_TEMP_DIR="$EDGESTACK_TEMP_DIR"
WORK_MODEL=$1

usage() {
    echo "使用说明："
    echo "导入以下参数再执行setup_master"
    echo "export HOSTNAME=k8s-work01"
    echo "DOCKER使用在线或者离线 安装 【 export DOCKER_MODEL=ONLINE | export DOCKER_MODEL=OFFLINE 】 "
    echo "export MASTERIP=172.16.8.31:6443"
    echo "export TOKEN=xxx"
    echo "export DISCOVERY_TOKEN_CA_CERT_HASH=sha256xx"
    echo  "export HARBOR_ADDR=https://10.10.124.19:30003"
    echo  "export HARBOR_USER=admin"
    echo  "export HARBOR_PASSWD=Harbor12345"
    echo ""
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HOSTNAME=""${HOSTNAME}"
    echo "DOCKER_MODEL=""${DOCKER_MODEL}"
    echo "MASTERIP=""${MASTERIP}"
    echo "TOKEN=""${TOKEN}"
    echo "DISCOVERY_TOKEN_CA_CERT_HASH=""${DISCOVERY_TOKEN_CA_CERT_HASH}"
    echo  "HARBOR_ADDR=""${HARBOR_ADDR}"
    echo  "HARBOR_USER=""${HARBOR_USER}"
    echo  "HARBOR_PASSWD=""${HARBOR_PASSWD}"

    echo ""
}

settime(){
# 手动设置时间
# date -s "2023-09-20 15:46:00"
yum install ntpdate -y
ntpdate ntp3.aliyun.com
}

doScript(){
    if [ "$WORK_MODEL" = "join" ]; then
        if [ "${DOCKER_MODEL}" = "ONLINE" ]   ;then
          bash ./repo-setup.sh
          bash ./docker-install.sh
        fi
        bash ./02-docker_install.sh
        bash ./03-docker_config.sh
        bash ./04-homename_setup.sh ${HOSTNAME}
        bash ./05-load-image.sh "images/work"
        bash ./06-k8s-setup.sh
        bash ./07-work-join.sh
        bash ./09-stopwalld.sh
     elif [ "$WORK_MODEL" = "disjoin"  ]; then
        bash ./08-work-disjoin.sh
      else
        echo "NO Command ,$WORK_MODEL"
    fi
}

#settime

if [ ${#HARBOR_USER} -eq 0 ]  || [ ${#HARBOR_ADDR} -eq 0 ] ||
    [ ${#HARBOR_PASSWD} -eq 0 ] || [ ${#HOSTNAME} -eq 0 ] || [ ${#DOCKER_MODEL} -eq 0 ] || [ ${#MASTERIP} -eq 0 ] || [ ${#TOKEN} -eq 0 ] ||  [ ${#DISCOVERY_TOKEN_CA_CERT_HASH} -eq 0 ]; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doScript
