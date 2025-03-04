#!/bin/bash
echo "编译固件大小为: $PROFILE MB"
echo "Include Docker: $INCLUDE_DOCKER"

# 处理外部包
echo "处理外部包..."
mkdir -p /home/build/immortalwrt/packages
if [ -f "/home/build/immortalwrt/customize_scripts/handle_packages.sh" ]; then
  chmod +x /home/build/immortalwrt/customize_scripts/handle_packages.sh
  /home/build/immortalwrt/customize_scripts/handle_packages.sh
fi

echo "Start oh-my-zsh Config !"
echo "Current Path: $PWD"
mkdir -p $PWD/files/root/.oh-my-zsh
ROOT=$PWD/files/root
ZSH=$ROOT/.oh-my-zsh
ZSH_CUSTOM=$ZSH/custom
git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git $ZSH
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
cp $ZSH/templates/zshrc.zsh-template $ROOT/.zshrc
sed -i "s/ZSH_THEME=\".\+\"/ZSH_THEME=\"ys\"/" $ROOT/.zshrc
sed -i "s/plugins=.\+/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/" $ROOT/.zshrc

echo "Create pppoe-settings"
mkdir -p  /home/build/immortalwrt/files/etc/config

# 创建pppoe配置文件 yml传入环境变量ENABLE_PPPOE等 写入配置文件 供99-custom.sh读取
cat << EOF > /home/build/immortalwrt/files/etc/config/pppoe-settings
enable_pppoe=${ENABLE_PPPOE}
pppoe_account=${PPPOE_ACCOUNT}
pppoe_password=${PPPOE_PASSWORD}
EOF

echo "cat pppoe-settings"
cat /home/build/immortalwrt/files/etc/config/pppoe-settings
# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."



# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES git"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-filebrowser-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
PACKAGES="$PACKAGES luci-i18n-opkg-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
PACKAGES="$PACKAGES luci-app-nikki"
PACKAGES="$PACKAGES luci-app-lucky"
PACKAGES="$PACKAGES luci-app-netdata"
PACKAGES="$PACKAGES luci-app-mosdns"
# zsh 终端
PACKAGES="$PACKAGES zsh"
# Vim 完整版，带语法高亮
PACKAGES="$PACKAGES vim-fuller"

# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
