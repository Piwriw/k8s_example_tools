#!/bin/bash
set  -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行images-tag"
    echo "export HARBOR_ADDR=192.168.10.10"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HARBOR_ADDR="${HARBOR_ADDR}
    echo ""
}

doTagImages(){
# 获取所有的Docker镜像列表，并遍历每个镜像
docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
    tm=$(echo "$image" | rev | cut -d '/' -f 1 )
    tag=$(echo "$tm" |rev| cut -d ':' -f 2)
    name=$(echo "$tm" |rev| cut -d ':' -f 1)
  docker tag "$image" "$HARBOR_ADDR/library/$name:$tag"
  echo "Tagged $image  ---  $HARBOR_ADDR/library/$name:$tag"
done
}

if [ ${#HARBOR_ADDR} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doTagImages
