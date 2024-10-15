#!/bin/bash

curl -fsSL https://get.docker.com -o get-docker.sh
# --mirror Aliyun 使用阿里云镜像
sh get-docker.sh --version 20.10 --mirror Aliyun
