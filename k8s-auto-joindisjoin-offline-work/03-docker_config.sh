#!/bin/bash
set -e



# 检查docker config.json是否存在
isExistedDocker() {
  docker_config_path="/etc/docker/daemon.json"

  # 检查文件是否存在
  if [ -e "$docker_config_path" ]; then
    echo "daemon.json文件已存在"
     ./utils/docker_daemon_utils
  else
    echo "daemon.json文件不存在，正在创建..."
    if [ ! -d "/etc/docker" ]; then
        mkdir -p /etc/docker
    fi
    echo '{}' > /etc/docker/daemon.json
     ./utils/docker_daemon_utils
    echo "daemon.json文件已创建"
  fi
}


startDocker(){
# Start docker service
systemctl daemon-reload
systemctl restart docker

# Login to Harbor
docker login -u "$HARBOR_USER" -p "$HARBOR_PASSWD" "$HARBOR_ADDR"
echo "Connect Harbor Success"
}




isExistedDocker
startDocker