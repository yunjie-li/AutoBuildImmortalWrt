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
EXCLUDE_PATTERN="(lucky|nikki)"

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
  
  # 调试: 输出API返回的原始数据
  echo "API返回数据预览(前500字符):"
  echo "$LUCKY_RELEASE_INFO" | head -c 500
  echo -e "\n"
  
  # 提取版本号
  LUCKY_VERSION=$(echo "$LUCKY_RELEASE_INFO" | grep -o '"tag_name": "[^"]*' | cut -d'"' -f4)
  echo "lucky 最新版本: $LUCKY_VERSION"
  
  # 输出所有下载链接，用于调试
  echo "所有下载链接:"
  ALL_URLS=$(echo "$LUCKY_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*' | cut -d'"' -f4)
  echo "$ALL_URLS"
  echo -e "\n"
  
  # 解析所有资源并添加到临时文件
  FOUND_LUCI_APP_LUCKY=false
  FOUND_LUCI_I18N_LUCKY=false
  FOUND_LUCKY=false
  
  echo "$LUCKY_RELEASE_INFO" | grep -o '"browser_download_url": "[^"]*' | cut -d'"' -f4 | while read -r url; do
    # 使用精确的匹配模式
    if [[ "$url" == *"/luci-app-lucky_"*".ipk" ]] && ! $FOUND_LUCI_APP_LUCKY; then
      echo "找到 luci-app-lucky: $url"
      echo "luci-app-lucky $url" >> "$TEMP_FILE"
      FOUND_LUCI_APP_LUCKY=true
    elif [[ "$url" == *"/luci-i18n-lucky-zh-cn_"*".ipk" ]] && ! $FOUND_LUCI_I18N_LUCKY; then
      echo "找到 luci-i18n-lucky-zh-cn: $url"
      echo "luci-i18n-lucky-zh-cn $url" >> "$TEMP_FILE"
      FOUND_LUCI_I18N_LUCKY=true
    elif [[ "$url" == *"/lucky_"*"_Openwrt_x86_64.ipk" ]] && ! $FOUND_LUCKY; then
      echo "找到 lucky: $url"
      echo "lucky $url" >> "$TEMP_FILE"
      FOUND_LUCKY=true
    fi
  done
  
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
# 函数: 更新 luci-app-nikki 和 nikki 包链接
#################################################
update_nikki_packages() {
  echo "获取 kenzok8/compile-package 的 tag 信息..."
  NIKKI_REPO="kenzok8/compile-package"
  
  # 获取所有 releases (按时间排序，最新的在前)
  RELEASES_INFO=$(curl -s "https://api.github.com/repos/$NIKKI_REPO/releases?per_page=10")
  
  # 调试: 输出API返回的原始数据
  echo "API返回数据预览(前500字符):"
  echo "$RELEASES_INFO" | head -c 500
  echo -e "\n"
  
  # 获取 releases 数量
  RELEASES_COUNT=$(echo "$RELEASES_INFO" | jq '. | length')
  echo "获取到 $RELEASES_COUNT 个 releases"
  
  # 初始化标志，表示是否找到了所需的包
  FOUND_LUCI_APP_NIKKI=false
  FOUND_NIKKI=false
  
  # 从 JSON 数组中提取每个 release 的信息
  echo "$RELEASES_INFO" | jq -c '.[]' | while read -r release; do
    # 如果已经找到了所有需要的包，跳出循环
    if $FOUND_LUCI_APP_NIKKI && $FOUND_NIKKI; then
      break
    fi
    
    # 提取 tag 名称
    TAG=$(echo "$release" | jq -r '.tag_name')
    
    # 只处理包含 x86_64 的 tag
    if [[ "$TAG" == *"x86_64"* ]]; then
      echo "检查 tag: $TAG"
      
      # 提取该 tag 的所有下载链接
      ASSETS=$(echo "$release" | jq -r '.assets[].browser_download_url')
      
      # 输出所有下载链接，用于调试
      echo "Tag $TAG 的所有下载链接:"
      echo "$ASSETS"
      echo -e "\n"
      
      # 检查是否包含我们需要的文件
      for url in $ASSETS; do
        # 使用精确的匹配模式
        if [[ "$url" == *"/luci-app-nikki_"*".ipk" ]] && ! $FOUND_LUCI_APP_NIKKI; then
          echo "找到 luci-app-nikki: $url"
          echo "luci-app-nikki $url" >> "$TEMP_FILE"
          FOUND_LUCI_APP_NIKKI=true
        elif [[ "$url" == *"/nikki_"*"_x86_64.ipk" ]] && ! $FOUND_NIKKI; then
          echo "找到 nikki: $url"
          echo "nikki $url" >> "$TEMP_FILE"
          FOUND_NIKKI=true
        fi
        
        # 如果已经找到了所有需要的包，跳出循环
        if $FOUND_LUCI_APP_NIKKI && $FOUND_NIKKI; then
          break
        fi
      done
    fi
  done
  
  # 检查是否找到了所需的包
  if ! $FOUND_LUCI_APP_NIKKI; then
    echo "警告: 未找到 luci-app-nikki 包"
  fi
  
  if ! $FOUND_NIKKI; then
    echo "警告: 未找到 nikki 包"
  fi
}

#################################################
# 主程序: 调用各个更新函数
#################################################

# 检查是否安装了 jq (用于解析 JSON)
if ! command -v jq &> /dev/null; then
  echo "安装 jq 工具用于解析 JSON..."
  apt-get update && apt-get install -y jq
fi

# 更新 lucky 相关包
update_lucky_packages

# 更新 nikki 相关包
update_nikki_packages

# 在这里可以添加更多软件包的更新函数调用
# update_another_package()

# 替换原始文件
mv "$TEMP_FILE" "$URL_FILE"

echo "更新后的 external-package-urls.txt 内容:"
cat "$URL_FILE"
