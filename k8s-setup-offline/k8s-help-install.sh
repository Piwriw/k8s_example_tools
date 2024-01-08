#!/bin/bash
set -e
yum install --downloadonly  --downloaddir=/root/k8s kubelet-1.21.14 kubeadm-1.21.14 kubectl-1.21.14 ntpdate
yum localinstall -y ./package/k8s/centeros_x86/*.rpm --disablerepo=*
