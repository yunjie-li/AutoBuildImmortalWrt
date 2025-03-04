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
EXCLUDE_PATTERN="(lucky|nikki|mosdns|luci-app-mosdns)"

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
  
  # 检查是否找到了所需的包，如果没找到则保留原有链接
  if ! $FOUND_LUCI_APP_LUCKY; then
    echo "警告: 未找到 luci-app-lucky 包，保留原有链接"
    grep "luci-app-lucky_" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 luci-app-lucky 链接"
  fi
  
  if ! $FOUND_LUCI_I18N_LUCKY; then
    echo "警告: 未找到 luci-i18n-lucky-zh-cn 包，保留原有链接"
    grep "luci-i18n-lucky-zh-cn_" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 luci-i18n-lucky-zh-cn 链接"
  fi
  
  if ! $FOUND_LUCKY; then
    echo "警告: 未找到 lucky 包，保留原有链接"
    grep "/lucky_.*_Openwrt_x86_64\.ipk" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 lucky 链接"
  fi
}

#################################################
# 函数: 更新 mosdns 相关包链接
#################################################
update_mosdns_packages() {
  echo "获取 luci-app-mosdns 最新版本信息..."
  MOSDNS_REPO="sbwml/luci-app-mosdns"
  MOSDNS_RELEASE_INFO=$(curl -s "https://api.github.com/repos/$MOSDNS_REPO/releases/latest")
  
  # 提取版本号
  MOSDNS_VERSION=$(echo "$MOSDNS_RELEASE_INFO" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
  echo "mosdns 最新版本: $MOSDNS_VERSION"
  
  # 初始化标志
  FOUND_LUCI_APP_MOSDNS=false
  FOUND_LUCI_I18N_MOSDNS=false
  FOUND_MOSDNS=false
  FOUND_V2DAT=false
  
  # 解析所有资源并添加到临时文件
  while read -r url; do
    if [[ "$url" == *"/luci-app-mosdns_"*".ipk" ]] && ! $FOUND_LUCI_APP_MOSDNS; then
      echo "找到 luci-app-mosdns: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_LUCI_APP_MOSDNS=true
    elif [[ "$url" == *"/luci-i18n-mosdns-zh-cn_"*".ipk" ]] && ! $FOUND_LUCI_I18N_MOSDNS; then
      echo "找到 luci-i18n-mosdns-zh-cn: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_LUCI_I18N_MOSDNS=true
    elif [[ "$url" == *"/mosdns_"*"_x86_64.ipk" ]] && ! $FOUND_MOSDNS; then
      echo "找到 mosdns: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_MOSDNS=true
    elif [[ "$url" == *"/v2dat_"*"_x86_64.ipk" ]] && ! $FOUND_V2DAT; then
      echo "找到 v2dat: $url"
      echo "$url" >> "$TEMP_FILE"
      FOUND_V2DAT=true
    fi
  done <<< "$(echo "$MOSDNS_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*' | cut -d'"' -f4)"
  
  # 检查是否找到了所需的包，如果没找到则保留原有链接
  if ! $FOUND_LUCI_APP_MOSDNS; then
    echo "警告: 未找到 luci-app-mosdns 包，保留原有链接"
    grep "luci-app-mosdns_" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 luci-app-mosdns 链接"
  fi
  
  if ! $FOUND_LUCI_I18N_MOSDNS; then
    echo "警告: 未找到 luci-i18n-mosdns-zh-cn 包，保留原有链接"
    grep "luci-i18n-mosdns-zh-cn_" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 luci-i18n-mosdns-zh-cn 链接"
  fi
  
  if ! $FOUND_MOSDNS; then
    echo "警告: 未找到 mosdns 包，保留原有链接"
    grep "/mosdns_.*_x86_64\.ipk" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 mosdns 链接"
  fi
  
  if ! $FOUND_V2DAT; then
    echo "警告: 未找到 v2dat 包，保留原有链接"
    grep "/v2dat_" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 v2dat 链接"
  fi
}

#################################################
# 函数: 更新 nikki 相关包链接
#################################################
update_nikki_packages() {
  echo "获取 nikki 最新版本信息..."
  
  NIKKI_REPO="nikkinikki-org/OpenWrt-nikki"
  NIKKI_RELEASE_INFO=$(curl -s "https://api.github.com/repos/$NIKKI_REPO/releases/latest")
  NIKKI_TARBALL_URL=$(echo "$NIKKI_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*nikki_x86_64-openwrt-23.05.tar.gz[^"]*' | cut -d'"' -f4)
  
  if [ -z "$NIKKI_TARBALL_URL" ]; then
    echo "警告: 未找到 nikki_x86_64-openwrt-23.05.tar.gz 压缩包，保留原有链接"
    grep "nikki_x86_64-openwrt-23.05.tar.gz" "$URL_FILE" >> "$TEMP_FILE" || echo "注意: 没有找到之前的 nikki 链接"
  else
    echo "找到 nikki 压缩包: $NIKKI_TARBALL_URL"
    echo "$NIKKI_TARBALL_URL" >> "$TEMP_FILE"
  fi
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
update_lucky_packages || echo "更新 lucky 包失败，但继续执行"
update_mosdns_packages || echo "更新 mosdns 包失败，但继续执行"
update_nikki_packages || echo "更新 nikki 包失败，但继续执行"

# 替换原始文件
mv "$TEMP_FILE" "$URL_FILE"

echo "更新后的 external-package-urls.txt 内容:"
cat "$URL_FILE"
