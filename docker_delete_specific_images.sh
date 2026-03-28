#!/bin/bash

# 获取所有未使用的镜像ID
IMAGES=$(docker images -q)

# 检查是否有未使用的镜像
if [ -z "$IMAGES" ]; then
  echo "没有未使用的镜像需要删除。"
  exit 0
fi

# 删除所有未使用的镜像
for IMAGE in $IMAGES
do
  echo "正在删除镜像: $IMAGE"
  docker rmi $IMAGE -f
done

echo "所有未使用的镜像已删除。"