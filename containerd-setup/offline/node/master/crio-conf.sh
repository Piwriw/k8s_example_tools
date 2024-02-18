#!/bin/bash

 kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=10.10.101.123 --image-repository registry.aliyuncs.com/google_containers --service-cidr=10.96.0.0/12 --kubernetes-version=v1.25.14 --cri-socket=unix:///var/run/crio/crio.sock --v=6