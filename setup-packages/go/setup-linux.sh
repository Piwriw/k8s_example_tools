#!/bin/bash
set -e

arch=$(uname -m)
version=$1


installGo(){
if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
  arch="arm64"
  echo "当前系统为 ARM64，Go安装完毕"
elif [[ "$arch" == "x86_64" || "$arch" == "amd64" ]]; then
  arch="amd64"
  echo "当前系统Centos为 AMD64 (x86_64)，Go安装完毕"
else
  echo "当前系统架构为 $arch"
  echo "目前不支持该架构的安装模式"
fi


url="https://studygolang.com/dl/golang/go$version.linux-$arch.tar.gz"
filename=$(basename "$url")
curl -OL $url
}

setupGo(){
 mkdir -p  ~/go
 tar -C /usr/local -zxvf ${filename}
 echo "export GOROOT=/usr/local/go" >> /etc/profile
  source /etc/profile
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
~