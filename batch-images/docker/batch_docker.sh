#!/bin/bash
set -e

# 设置镜像文件所在目录和新的镜像名称前缀
NEW_TAG_PREFIX="e/f" # 替换为新镜像的前缀

# 需要从远程仓库拉取的镜像列表
REMOTE_IMAGES=(
    "a/b/c:test"
)

# 计数器
FILE_COUNT=0
TOTAL_COUNT=${#REMOTE_IMAGES[@]}

cleanImages() {
    local tagName=$1
    local loadImage=$2
    docker rmi "$tagName" >/dev/null 2>&1
    docker rmi "$loadImage" >/dev/null 2>&1
    echo "Progress[$FILE_COUNT/$TOTAL_COUNT]: Cleaning image: $tagName $loadImage"
}

pullImages() {
    for IMAGE_NAME in "${REMOTE_IMAGES[@]}"; do
        echo "Pulling image[$FILE_COUNT/$TOTAL_COUNT]: $IMAGE_NAME "
        docker pull "$IMAGE_NAME"
    done
}

reTagImages() {
    for IMAGE_NAME in "${REMOTE_IMAGES[@]}"; do
        ((FILE_COUNT++))
        IMAGE_BASENAME=$(echo "$IMAGE_NAME" | awk -F'[/:]' '{print $(NF-1)}')
        IMAGE_TAG=$(echo "$IMAGE_NAME" | awk -F'[/:]' '{print $(NF)}')

        NEW_TAG="${NEW_TAG_PREFIX}/${IMAGE_BASENAME}:${IMAGE_TAG}"

        echo "Tagging image[$FILE_COUNT/$TOTAL_COUNT]: $IMAGE_NAME -> $NEW_TAG"
        docker tag "$IMAGE_NAME" "$NEW_TAG"

        echo "Pushing image[$FILE_COUNT/$TOTAL_COUNT]: $NEW_TAG "
#        docker push "$NEW_TAG" >/dev/null 2>&1

        echo "Progress[$FILE_COUNT/$TOTAL_COUNT]: images processed. Current image: ${NEW_TAG}"
#        cleanImages "$NEW_TAG" "$IMAGE_NAME"
    done
}

pullImages
reTagImages
echo "All images loaded, retagged, and pushed. All Task:  $FILE_COUNT/$TOTAL_COUNT images processed. "

