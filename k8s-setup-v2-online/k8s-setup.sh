#!/bin/bash
set -e
# 卸载旧版本
yum remove -y kubelet kubeadm kubectl

# 安装kubelet、kubeadm、kubectl
yum install -y kubelet-1.21.4 kubeadm-1.21.4 kubectl-1.21.4

systemctl enable kubelet && systemctl start kubelet