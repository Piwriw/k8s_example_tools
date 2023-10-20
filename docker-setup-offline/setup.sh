#!/bin/bash
set -e
arch=$(uname -m)

setupCentos(){
if [ "$arch" == "arm64" ]; then
  yum localinstall -y ./centos/arm64/*.rpm --disablerepo=*
  echo "当前系统Centos 为 ARM64 Docker安装完毕"
elif [ "$arch" == "x86_64" ]; then
  yum localinstall -y ./centos/x86_64/*.rpm --disablerepo=*
  echo "当前系统Centos 为 AMD64 (x86_64) Docker安装完毕"
else
  echo "当前系统架构为 $arch"
  echo "目前不支持，这种架构的安装模式"
fi
}

setupUbuntu(){
  if [[ "$arch" == "arm64" || "$arch" == "aarch64" ]]; then
  sudo  dpkg -i  ./ubuntu/arm64/*.deb
  echo "当前系统Ubuntu 为 ARM64 Docker安装完毕"
elif [ "$arch" == "x86_64" ]; then
  sudo  dpkg -i ./ubuntu/x86_64/*.deb
  echo "当前系统Ubuntu 为 x86_64 Docker安装完毕"
else
  echo "当前系统架构为 $arch"
  echo "目前不支持，这种架构的安装模式"
fi
}

os_release=$(cat /etc/os-release)

if [[ ${os_release} == *"Ubuntu"* ]]; then
    setupUbuntu
    echo "Ubuntu"
elif [[ ${os_release} == *"CentOS"* ]]; then
    setupCentos
    echo "CentOS"
else
    echo "Unknown"
fi