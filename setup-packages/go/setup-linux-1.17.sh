#!/bin/bash
set -e

arch=$(uname -m)

url="https://studygolang.com/dl/golang/go1.17.linux-amd64.tar.gz"
filename=$(basename "$url")


installGo(){
if [ "$arch" == "arm64" ]; then
  url=$(echo "$url" | sed "s/amd64/arm64/")
  echo "当前系统 为 ARM64 Go安装完毕"
elif [ "$arch" == "x86_64" ]; then
  echo "当前系统Centos 为 AMD64 (x86_64) Docker安装完毕"
else
  echo "当前系统架构为 $arch"
  echo "目前不支持，这种架构的安装模式"
fi

filename=$(basename "$url")
yum install -y wget
wget $url
}

setupGo(){
 mkdir ~/go && cd ~/go
 tar -C /usr/local -zxvf ${filename}
 echo "export GOROOT=/usr/local/go" >> /etc/profile
 echo "export PATH=$PATH:$GOROOT/bin" >>  /etc/profile
 source /etc/profile

 # 更换代理源
export GOPROXY=https://proxy.golang.com.cn,direct
 # 开启go mod
 export GO111MODULE=on
 go version

 echo "如果不能输出go version 请执行 source /etc/profile"
}

installGo
setupGo