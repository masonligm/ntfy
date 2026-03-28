#!/bin/bash

# 检查是否提供了路径参数
if [ -z "$1" ]; then
  echo "请提供包含 tar 文件的目录路径作为参数。"
  echo "用法: $0 <path_to_tar_files>"
  exit 1
fi

# 获取传入的目录路径
TAR_PATH=$1

# 检查目录是否存在
if [ ! -d "$TAR_PATH" ]; then
  echo "目录 $TAR_PATH 不存在。"
  exit 1
fi

# 遍历指定目录中的 tar 文件并加载
TAR_FILES="$TAR_PATH/*.tar"

for TAR_FILE in $TAR_FILES
do
  if [ -f "$TAR_FILE" ]; then
    echo "加载 $TAR_FILE"
    docker load -i $TAR_FILE
  else
    echo "在目录 $TAR_PATH 中没有找到 tar 文件。"
    exit 1
  fi
done

echo "所有 tar 文件已加载完成。"

