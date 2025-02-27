#!/bin/bash
# 文件路径: scripts/update_external_urls.sh
# 功能: 更新外部软件包的下载链接

set -e

# 文件路径
URL_FILE="files/external-package-urls.txt"

# 确保目录存在
mkdir -p $(dirname "$URL_FILE")

# 如果文件不存在，创建空文件
if [ ! -f "$URL_FILE" ]; then
  touch "$URL_FILE"
fi

# 临时文件
TEMP_FILE=$(mktemp)

# 保存需要排除的包名，用正则表达式格式
EXCLUDE_PATTERN="(lucky|nikki|adguardhome|luci-app-adguardhome)"

# 复制不包含排除包名的内容到临时文件
grep -v -E "$EXCLUDE_PATTERN" "$URL_FILE" > "$TEMP_FILE" || true

echo "正在更新外部包链接..."

#################################################
# 函数: 更新 luci-app-lucky 和 lucky 包链接
#################################################
update_lucky_packages() {
  echo "获取 luci-app-lucky 最新版本信息..."
  LUCKY_REPO="gdy666/luci-app-lucky"
  LUCKY_RELEASE_INFO=$(curl -s "https://api.github.com/repos/$LUCKY_REPO/releases/latest")
  
  # 提取版本号
  LUCKY_VERSION=$(echo "$LUCKY_RELEASE_INFO" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
  echo "lucky 最新版本: $LUCKY_VERSION"
  
  # 初始化标志
  FOUND_LUCI_APP_LUCKY=false
  FOUND_LUCI_I18N_LUCKY=false
  FOUND_LUCKY=false
  
  # 解析所有资源并添加到临时文件
  while read -r url; do
    if [[ "$url" == *"/luci-app-lucky_"*".ipk" ]] && ! $FOUND_LUCI_APP_LUCKY; then
      echo "找到 luci-app-lucky: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_LUCI_APP_LUCKY=true
    elif [[ "$url" == *"/luci-i18n-lucky-zh-cn_"*".ipk" ]] && ! $FOUND_LUCI_I18N_LUCKY; then
      echo "找到 luci-i18n-lucky-zh-cn: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_LUCI_I18N_LUCKY=true
    elif [[ "$url" == *"/lucky_"*"_Openwrt_x86_64.ipk" ]] && ! $FOUND_LUCKY; then
      echo "找到 lucky: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_LUCKY=true
    fi
  done <<< "$(echo "$LUCKY_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*' | cut -d'"' -f4)"
  
  # 检查是否找到了所需的包
  if ! $FOUND_LUCI_APP_LUCKY; then
    echo "警告: 未找到 luci-app-lucky 包"
  fi
  
  if ! $FOUND_LUCI_I18N_LUCKY; then
    echo "警告: 未找到 luci-i18n-lucky-zh-cn 包"
  fi
  
  if ! $FOUND_LUCKY; then
    echo "警告: 未找到 lucky 包"
  fi
}

#################################################
# 函数: 更新 adguardhome 相关包链接
#################################################
update_adguardhome_packages() {
  echo "获取 adguardhome 最新版本信息..."
  
  # 基础 URL
  BASE_URL="https://op.dllkids.xyz/packages/x86_64"
  
  # 获取目录列表
  DIR_LISTING=$(curl -s "$BASE_URL/")
  
  # 查找最新的 adguardhome 和 luci-app-adguardhome 包
  ADGUARDHOME_IPK=$(echo "$DIR_LISTING" | grep -o 'adguardhome_[^"]*_x86_64\.ipk' | sort -V | tail -n 1)
  LUCI_ADGUARDHOME_IPK=$(echo "$DIR_LISTING" | grep -o 'luci-app-adguardhome_[^"]*\.ipk' | sort -V | tail -n 1)
  
  if [ -z "$ADGUARDHOME_IPK" ]; then
    echo "警告: 未找到 adguardhome 包"
  else
    echo "找到 adguardhome 包: $ADGUARDHOME_IPK"
    echo "$BASE_URL/$ADGUARDHOME_IPK" >> "$TEMP_FILE"
  fi
  
  if [ -z "$LUCI_ADGUARDHOME_IPK" ]; then
    echo "警告: 未找到 luci-app-adguardhome 包"
  else
    echo "找到 luci-app-adguardhome 包: $LUCI_ADGUARDHOME_IPK"
    echo "$BASE_URL/$LUCI_ADGUARDHOME_IPK" >> "$TEMP_FILE"
  fi
}

#################################################
# 函数: 更新 nikki 相关包链接
#################################################
update_nikki_packages() {
  echo "获取 nikki 最新版本信息..."
  
  NIKKI_REPO="nikkinikki-org/OpenWrt-nikki"
  NIKKI_RELEASE_INFO=$(curl -s "https://api.github.com/repos/$NIKKI_REPO/releases/latest")
  NIKKI_TARBALL_URL=$(echo "$NIKKI_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*nikki_x86_64-openwrt-24.10.tar.gz[^"]*' | cut -d'"' -f4)
  
  if [ -z "$NIKKI_TARBALL_URL" ]; then
    echo "警告: 未找到 nikki_x86_64-openwrt-24.10.tar.gz 压缩包"
    return 1
  fi
  
  echo "找到 nikki 压缩包: $NIKKI_TARBALL_URL"
  echo "$NIKKI_TARBALL_URL" >> "$TEMP_FILE"
}

#################################################
# 主程序: 调用各个更新函数
#################################################

# 检查是否安装了必要的工具
for tool in curl grep sort tail; do
  if ! command -v $tool &> /dev/null; then
    echo "安装必要的工具: $tool"
    apt-get update && apt-get install -y $tool
  fi
done

# 更新各类包
update_lucky_packages
update_adguardhome_packages
update_nikki_packages

# 替换原始文件
mv "$TEMP_FILE" "$URL_FILE"

echo "更新后的 external-package-urls.txt 内容:"
cat "$URL_FILE"
