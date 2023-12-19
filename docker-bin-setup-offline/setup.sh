#!/bin/bash -x
set -e
bashpath=$(cd `dirname $0`; pwd)


tar xf $bashpath/$1 -C /usr/bin/ --strip-components 1
cp $bashpath/docker.service /etc/systemd/system/
chmod +x /etc/systemd/system/docker.service


systemctl daemon-reload
systemctl enable docker && systemctl restart docker
#docker login
echo "Docker安装完毕"