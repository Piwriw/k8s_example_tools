#!/bin/bash
set -e

bashpath=$(cd `dirname $0`; pwd)

ARCH=$1
# 检查docker是否存在
isExistedDocker(){
  set +e
  docker ps > /dev/null 2>&1
  docker_check=$?
  # Exit if Docker is running
  if [[ $docker_check -eq 0 ]]; then
      exit 0
  fi
  echo "Docker不存在，进入安装Docker……"
  set -e
  prepareDocker
}


# 解压Docker安装包
prepareDocker(){

  # Extract the docker file
  mkdir -p  $EDGESTACK_TEMP_DIR/docker
  tar -xf ${bashpath}/dependence/docker.tar.gz -C $EDGESTACK_TEMP_DIR/docker

  # Change owner and group of docker_setup
  chown root:root $EDGESTACK_TEMP_DIR/docker/setup.sh

  chmod 0755 $EDGESTACK_TEMP_DIR/docker/setup.sh

# Check if setup.sh exists and is executable
if [[ -x $EDGESTACK_TEMP_DIR/docker/setup.sh ]]; then
    setup_script=1
else
    setup_script=0
fi

# Run setup.sh to install Docker
if [[ $setup_script -eq 1 ]]; then
#    formatted_arch=$(uname -m)
#    if [[ $formatted_arch == "x86_64" || $formatted_arch == "amd64" ]]; then
#        formatted_arch="x86"
#    elif [[ $formatted_arch == "aarch64" ]]; then
#        formatted_arch="arm64"
#    fi
    docker_filename="docker_20_${ARCH}.tar.gz"


    bash $EDGESTACK_TEMP_DIR/docker/setup.sh $docker_filename
    setup_result=$?
    if [[ $setup_result -eq 0 ]]; then
        echo "Docker installation completed"
    else
        echo "Docker installation failed"
    fi
fi

}

##下载对应Docker安装包
#installDocker(){
#  isExistedDocker
#  formatted_arch=$(uname -m)
#  if [[ $formatted_arch == "x86_64" || $formatted_arch == "amd64" ]]; then
#      formatted_arch="x86"
#  elif [[ $formatted_arch == "aarch64" ]]; then
#      formatted_arch="arm64"
#  fi
#  docker_filename="docker_$(lsb_release -is | tr '[:upper:]' '[:lower:]')_${formatted_arch}.tar.gz"
#
#  # Ensure destination directory exists
#  mkdir -p /opt/docker
#
#}



#if [ ${#MINIO_PATH} -eq 0 ] ; then
#    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
#    printEnv
#    exit 1
#fi

isExistedDocker