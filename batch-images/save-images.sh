#!/bin/bash

output_dir="exported_images"

# 创建输出目录
mkdir -p "$output_dir"

# 获取所有的Docker镜像列表，并遍历每个镜像
docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
      tm=$(echo "$image" | rev | cut -d '/' -f 1 )
      name=$(echo "$tm" |rev |cut -d ':' -f 1)
      tag=$(echo "$tm" |rev| cut -d ':' -f 2)
   output_file="$output_dir/${name}_${tag}.tar"
   docker save -o "$output_file" "$image"
done
