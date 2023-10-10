#!/bin/bash
set -e
# 卸载旧版本
yum remove -y kubelet kubeadm kubectl

# 安装kubelet、kubeadm、kubectl
yum localinstall -y ./package/k8s/centeros_x86/*.rpm --disablerepo=*

systemctl enable kubelet && systemctl start kubelet