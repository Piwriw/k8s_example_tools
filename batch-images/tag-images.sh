#!/bin/bash
# 需要传递harbor  hostname:ip  h
harbor="$1"

if [ -z "$harbor" ]; then
    echo "没有提供参数。"
    exit 1  # 退出脚本，并返回非零退出状态
fi

# 获取所有的Docker镜像列表，并遍历每个镜像
docker images --format "{{.Repository}}:{{.Tag}}" | while read -r image; do
    tm=$(echo "$image" | rev | cut -d '/' -f 1 )
    tag=$(echo "$tm" |rev| cut -d ':' -f 2)
    name=$(echo "$tm" |rev| cut -d ':' -f 1)
#    image_name=$(basename "$repository")  # 保留最右侧的名称部分
#    new_tag="${image_name}:${tag}"
  docker tag "$image" "$harbor/library/$name:$tag"
  echo "Tagged $image  ---  $harbor/library/$name:$tag"
done