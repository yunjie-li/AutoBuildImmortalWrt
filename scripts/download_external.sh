#!/bin/bash
# 文件路径: scripts/download_nikki.sh
# 功能: 下载和处理 nikki 包

set -e

# 创建临时目录用于存放下载的包
TEMP_DIR="/tmp/nikki_packages"
TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
  echo "错误: 未指定目标目录"
  echo "用法: $0 <目标目录>"
  exit 1
fi

# 确保目标目录存在
mkdir -p "$TARGET_DIR"

echo "开始下载 nikki 包..."

# 获取最新版本的 nikki 压缩包 URL
NIKKI_REPO="nikkinikki-org/OpenWrt-nikki"
NIKKI_RELEASE_INFO=$(curl -s "https://api.github.com/repos/$NIKKI_REPO/releases/latest")
NIKKI_TARBALL_URL=$(echo "$NIKKI_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*nikki_x86_64-openwrt-24.10.tar.gz[^"]*' | cut -d'"' -f4)

if [ -z "$NIKKI_TARBALL_URL" ]; then
  echo "警告: 未找到 nikki_x86_64-openwrt-24.10.tar.gz 压缩包"
  exit 1
fi

echo "找到 nikki 压缩包: $NIKKI_TARBALL_URL"

# 创建并清理临时目录
rm -rf "$TEMP_DIR" 2>/dev/null || true
mkdir -p "$TEMP_DIR"

# 下载并解压
echo "下载 nikki 压缩包..."
wget -q "$NIKKI_TARBALL_URL" -O "$TEMP_DIR/nikki.tar.gz"

echo "解压 nikki 压缩包..."
mkdir -p "$TEMP_DIR/extracted"
tar -xzf "$TEMP_DIR/nikki.tar.gz" -C "$TEMP_DIR/extracted"

# 复制 ipk 文件到目标目录
echo "复制 ipk 文件到目标目录..."
find "$TEMP_DIR/extracted" -name "*.ipk" -exec cp {} "$TARGET_DIR" \;

# 列出复制的文件
echo "已复制以下文件到 $TARGET_DIR:"
ls -la "$TARGET_DIR"

# 清理临时目录
echo "清理临时文件..."
rm -rf "$TEMP_DIR"

echo "nikki 包下载和处理完成"
