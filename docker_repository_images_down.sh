#!/bin/bash
# Usage: ./docker_repository_images_down.sh [image_name]
#   - Without arguments: saves all local images
#   - With image_name: saves only the specified image

if [ -n "$1" ]; then
  # 指定镜像名称
  IMAGE="$1"
  # 检查镜像是否存在
  if ! docker image inspect "$IMAGE" &>/dev/null; then
    echo "Error: Image '$IMAGE' not found locally"
    echo "Available images:"
    docker images --format "{{.Repository}}:{{.Tag}}"
    exit 1
  fi
  IMAGES="$IMAGE"
else
  # 下载所有镜像
  IMAGES=$(docker images --format "{{.Repository}}:{{.Tag}}")
fi

for IMAGE in $IMAGES
do
  IMAGE_NAME=$(echo $IMAGE | tr ':' '_' | tr '/' '_')
  echo "Saving: $IMAGE -> ${IMAGE_NAME}.tar"
  docker save -o "${IMAGE_NAME}.tar" $IMAGE
  echo "Done: ${IMAGE_NAME}.tar"
done
