#!/bin/bash -x
set -e
bashpath=$(cd `dirname $0`; pwd)

mkdir -p /usr/local/share/oci-umount/oci-umount.d
mkdir -p /etc/crio
mkdir -p /etc/crio/crio.conf.d
mkdir -p /usr/local/lib/systemd/system

mkdir -p  /var/lib/crio/

tar xf $bashpath/$1 -C $bashpath
cp $bashpath/registries.conf /etc/containers/registries.conf

cd $bashpath/cri-o
./install


systemctl daemon-reload

systemctl enable crio && systemctl restart crio

echo "CRI-O安装完毕"
