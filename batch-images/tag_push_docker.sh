#!/bin/bash
set -e
# 设置镜像文件所在目录和新的镜像名称前缀
IMAGE_DIR="./images" # 替换为实际镜像文件目录
NEW_TAG_PREFIX="swr.cn-east-3.myhuaweicloud.com/agilex" # 替换为新镜像的前缀

# 获取目录下所有 .tar 文件的数量
TOTAL_FILES=$(ls "$IMAGE_DIR"/*.tar 2>/dev/null | wc -l)

# 检查是否有镜像文件
if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "No .tar files found in directory $IMAGE_DIR"
    exit 1
fi

# 当前处理的文件计数器
FILE_COUNT=0
cleanImages() {
    local tagName=$1
    local loadImage=$2
    docker rmi "$tagName"
    docker rmi "$loadImage"
    echo "Progress: Cleaning image: $tagName $loadImag "
}

# 遍历目录下的所有 .tar 文件
for IMAGE_FILE in "$IMAGE_DIR"/*.tar; do
    if [ -f "$IMAGE_FILE" ]; then
        ((FILE_COUNT++))

        echo "Loading image from file: $IMAGE_FILE"
        # 加载镜像
        LOAD_OUTPUT=$(docker load -i "$IMAGE_FILE")

        # 从加载输出中提取镜像名称和标签
        IMAGE_NAME=$(echo "$LOAD_OUTPUT" | awk -F': ' '/Loaded image:/ {print $2}')

        if [ -n "$IMAGE_NAME" ]; then
            # 提取镜像的基础名称和标签
            IMAGE_BASENAME=$(echo "$IMAGE_NAME" | awk -F'[/:]' '{print $(NF-1)}')
            IMAGE_TAG=$(echo "$IMAGE_NAME" | awk -F'[/:]' '{print $(NF)}')

            NEW_TAG="${NEW_TAG_PREFIX}/${IMAGE_BASENAME}:${IMAGE_TAG}"

            echo "Tagging image: $IMAGE_NAME -> $NEW_TAG"
            docker tag "$IMAGE_NAME" "$NEW_TAG"

            # 推送镜像并显示进度
            echo "Pushing image: $NEW_TAG"
            docker push "$NEW_TAG"

            # 显示推送进度
            echo "Progress: $FILE_COUNT/${TOTAL_FILES// /} images processed. Current image: ${NEW_TAG}  "
            # 清理本地镜像
            cleanImages "$NEW_TAG" "$IMAGE_NAME"
        else
            echo "Failed to load image from $IMAGE_FILE"
        fi
    fi
done

echo "All images loaded, retagged, and pushed. All Task: $FILE_COUNT/${TOTAL_FILES// /} images processed. "

