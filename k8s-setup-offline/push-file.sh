#!/bin/bash
set -e
# 源文件路径
source_file="../k8s-setup-offline"

# 目标主机列表
target_hosts=(
  "root@10.10.103.79:/root"
  "root@10.10.103.80:/root"
  "root@10.10.103.81:/root"
)

# 循环迭代目标主机列表，并使用 scp 命令将文件复制到每个主机
for target_host in "${target_hosts[@]}"; do
  scp -r "$source_file" "$target_host"
done