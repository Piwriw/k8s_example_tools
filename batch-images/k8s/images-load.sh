#!/bin/bash
set -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行images-load"
    echo "export INPUT_DIR=exported_images"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "INPUT_DIR="${INPUT_DIR}
    echo ""
}

doLoadImages(){
  # 遍历导出目录中的所有镜像文件
  for image_file in "$INPUT_DIR"/*.tar; do
     image_name_version=$(basename "$image_file" .tar)
     docker load -i "$image_file"
  done
}

if [ ${#INPUT_DIR} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doLoadImages