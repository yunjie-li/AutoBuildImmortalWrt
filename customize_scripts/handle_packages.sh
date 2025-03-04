#!/bin/bash
# 文件路径: files/scripts/handle_packages.sh
# 功能: 处理外部包，包括下载和解压 nikki 包

set -e

# 目标目录
PACKAGES_DIR="/home/build/immortalwrt/packages"
TEMP_DIR="/tmp/package_processing"

# 确保目录存在
mkdir -p "$PACKAGES_DIR"
mkdir -p "$TEMP_DIR"

# 处理 external-package-urls.txt 中的 URL
process_urls() {
  local url_file="$1"
  
  if [ ! -f "$url_file" ]; then
    echo "错误: URL 文件不存在: $url_file"
    return 1
  fi
  
  echo "处理 URL 文件: $url_file"
  
  while read -r url; do
    # 跳过空行和注释行
    if [ -z "$url" ] || [[ "$url" == \#* ]]; then
      continue
    fi
    
    echo "处理 URL: $url"
    
    # 如果是 nikki 压缩包
    if [[ "$url" == *"nikki_x86_64-openwrt"*".tar.gz" ]]; then
      process_nikki_tarball "$url"
    else
      # 直接下载 IPK 文件
      filename=$(basename "$url")
      echo "下载 $filename..."
      wget -q "$url" -O "$PACKAGES_DIR/$filename"
    fi
  done < "$url_file"
}

# 处理 nikki 压缩包
process_nikki_tarball() {
  local url="$1"
  local tarball="$TEMP_DIR/nikki.tar.gz"
  local extract_dir="$TEMP_DIR/nikki_extracted"
  
  echo "下载 nikki 压缩包..."
  wget -q "$url" -O "$tarball"
  
  echo "解压 nikki 压缩包..."
  mkdir -p "$extract_dir"
  tar -xzf "$tarball" -C "$extract_dir"
  
  echo "复制 nikki IPK 文件到 $PACKAGES_DIR..."
  find "$extract_dir" -name "*.ipk" -exec cp {} "$PACKAGES_DIR" \;
  
  # 列出复制的文件
  echo "已复制以下 nikki 包:"
  find "$extract_dir" -name "*.ipk" -exec basename {} \; | sort
  
  # 清理临时文件
  rm -rf "$extract_dir"
  rm -f "$tarball"
}

# 主程序
echo "开始处理外部包..."

# 处理 external-package-urls.txt
URL_FILE="/home/build/immortalwrt/files/external-package-urls.txt"
if [ -f "$URL_FILE" ]; then
  process_urls "$URL_FILE"
else
  echo "警告: URL 文件不存在: $URL_FILE"
fi

# 列出所有下载的包
echo "所有下载的包:"
ls -la "$PACKAGES_DIR"

echo "外部包处理完成"
