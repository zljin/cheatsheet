#!/bin/bash

# 简化版 Maven 缓存清理脚本
echo "开始清理 Maven 缓存..."

MAVEN_REPO="$HOME/.m2/repository"

if [ ! -d "$MAVEN_REPO" ]; then
    echo "错误: Maven 仓库不存在: $MAVEN_REPO"
    exit 1
fi

# 清理不完整的下载
echo "清理不完整下载..."
find "$MAVEN_REPO" -name "*.lastUpdated" -exec sh -c '
    for file; do
        dir=$(dirname "$file")
        echo "删除: $(basename "$(dirname "$dir")")/$(basename "$dir")"
        rm -rf "$dir"
    done
' sh {} +

# 清理空目录
echo "清理空目录..."
find "$MAVEN_REPO" -type d -empty -delete

echo "Maven 缓存清理完成!