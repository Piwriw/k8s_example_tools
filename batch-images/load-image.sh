#!/bin/bash

input_dir="exported_images"

# 遍历导出目录中的所有镜像文件
for image_file in "$input_dir"/*.tar; do
   image_name_version=$(basename "$image_file" .tar)
   docker load -i "$image_file"
done
