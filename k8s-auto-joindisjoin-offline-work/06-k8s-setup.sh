#!/bin/bash
set -e


prepareK8s(){
    # Extract the docker file
    mkdir -p  $EDGESTACK_TEMP_DIR/k8s
    tar -xf package/k8s/centeros-amd64.tar.gz  -C $EDGESTACK_TEMP_DIR/k8s
}

installK8s(){
  # 卸载旧版本
  yum remove -y kubelet kubeadm kubectl

  # 安装kubelet、kubeadm、kubectl
  yum localinstall -y  $EDGESTACK_TEMP_DIR/k8s/centeros_x86/*.rpm --disablerepo=*
  #rpm -Uvh --force --nodeps ./k8s//centeros_x86/*.rpm
  systemctl enable kubelet && systemctl start kubelet
}
prepareK8s
installK8s

