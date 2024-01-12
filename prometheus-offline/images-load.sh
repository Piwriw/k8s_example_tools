#!/bin/bash
set -e

INPUT_DIR= exported_images

doLoadImages(){
  # 遍历导出目录中的所有镜像文件
  for image_file in "$INPUT_DIR"/*.tar; do
     image_name_version=$(basename "$image_file" .tar)
     docker load -i "$image_file"
  done
}



doLoadImages