#!/bin/bash
set  -e

usage() {
    echo "使用说明："
    echo "导入以下参数再执行images-push"
    echo "export HARBOR_USERNAME=admin"
    echo "export HARBOR_PASSWORD=Harbor12345"
    echo "export HARBOR_ADDR=192.168.10.10"
    echo ""
}

printEnv() {
    echo "已设置环境变量参数："
    echo "HARBOR_USERNAME="${HARBOR_USERNAME}
    echo "HARBOR_PASSWORD="${HARBOR_PASSWORD}
    echo "HARBOR_ADDR="${HARBOR_ADDR}
    echo ""
}

doPushImages(){
# 登录到Docker仓库
docker login -u "$HARBOR_USERNAME" -p $HARBOR_PASSWORD $HARBOR_ADDR

# 循环遍历镜像列表，并推送到Docker仓库
docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
    tm=$(echo "$image" | rev | cut -d '/' -f 1 )
    tag=$(echo "$tm" |rev| cut -d ':' -f 2)
    name=$(echo "$tm" |rev| cut -d ':' -f 1)
#    image_name=$(basename "$repository")  # 保留最右侧的名称部分
#    new_tag="${image_name}:${tag}"
  docker push  "$HARBOR_ADDR/library/$name:$tag"
  echo "Push $HARBOR_ADDR/library/$name:$tag"
done

# 登出Docker仓库
docker logout
}

if [ ${#HARBOR_USERNAME} -eq 0 ] ||  [ ${#HARBOR_PASSWORD} -eq 0 ]  || [ ${#HARBOR_ADDR} -eq 0 ] ; then
    usage
    echo -e "\033[31;1m缺少环境变量参数 \033[0m"
    printEnv
    exit 1
fi

doPushImages
