#!/bin/bash
set -e


bashpath=$(cd `dirname $0`; pwd)

isExistEdgecore(){
    set +e
    edgecore -h > /dev/null 2>&1
    edgecore_check=$?
    # Exit if Docker is running
    if [[ $edgecore_check -eq 0 ]]; then
        exit 0
    fi
    set -e
    prepareEdgecore
}

prepareEdgecore(){
    # 强制clear edgecore work dir
    rm -rf /etc/kubeedge
    # 生成edgecore工作目录
    mkdir -p /etc/kubeedge
    # Extract the edgecore file
    tar -xf "${bashpath}/dependence/edgecore.tar.gz" -C $EDGESTACK_TEMP_DIR

    # Move the edgecore file
    mv $EDGESTACK_TEMP_DIR/edgecore /usr/local/bin/edgecore
    rm -f $EDGESTACK_TEMP_DIR/edgecore

    # Set executable permissions
    chmod 0755 /usr/local/bin/edgecore

    # Move the edgecore.service file
    mv $EDGESTACK_TEMP_DIR/edgecore.service /etc/systemd/system/edgecore.service

    echo "EdgeCore Install.......OK"
}

#下载对应Edgecore安装包
#installEdgecore(){
#  isExistEdgecore
#  formatted_arch=$(uname -m)
#  if [[ $formatted_arch == "x86_64" || $formatted_arch == "amd64" ]]; then
#      formatted_arch="x86"
#  elif [[ $formatted_arch == "aarch64" ]]; then
#      formatted_arch="arm64"
#  fi
#  edgecore_filename="edgecore_${formatted_arch}_${KUBEEDGE_VERSION}.tar.gz"
#
#  # Ensure destination directory exists
#  mkdir -p /opt/edgecore
#
#  # Download docker file from minio
#  wget -O /opt/edgecore.tar.gz "${MINIO_PATH}/edgestack-setup-v2/edgecore/${edgecore_filename}"
#
#  chmod 0644 "/opt/edgecore.tar.gz"
#}


#if [ ${#MINIO_PATH} -eq 0 ] ||  [ ${#KUBEEDGE_VERSION} -eq 0 ] ; then
#    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
#    printEnv
#    exit 1
#fi

isExistEdgecore