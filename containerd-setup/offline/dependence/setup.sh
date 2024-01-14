#!/bin/bash -x
set -e
bashpath=$(cd `dirname $0`; pwd)


tar xf $bashpath/$1 -C /usr/bin/ --strip-components 1
cp $bashpath/containerd.service /etc/systemd/system/
chmod +x /etc/systemd/system/containerd.service


systemctl daemon-reload
systemctl enable containerd && systemctl restart containerd


echo "containerd安装完毕"

unix:///var/run/containerd/containerd.sock,