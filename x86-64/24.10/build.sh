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

# echo "Start oh-my-zsh Config !"
# echo "Current Path: $PWD"
# mkdir -p $PWD/files/root/.oh-my-zsh
# ROOT=$PWD/files/root
# ZSH=$ROOT/.oh-my-zsh
# ZSH_CUSTOM=$ZSH/custom
# git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git $ZSH
# git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
# git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
# cp $ZSH/templates/zshrc.zsh-template $ROOT/.zshrc
# sed -i "s/ZSH_THEME=\".\+\"/ZSH_THEME=\"ys\"/" $ROOT/.zshrc
# sed -i "s/plugins=.\+/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/" $ROOT/.zshrc

# # Start Clash Core Download
# echo "Start Clash Core Download !"
# echo "Current Path: $PWD"

# mkdir -p /home/build/immortalwrt/files/etc/openclash/core
# cd /home/build/immortalwrt/files/etc/openclash/core || (echo "Clash core path does not exist! " && exit)

# # Clash Dev
# wget https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-amd64.tar.gz
# tar -zxvf clash-linux-amd64.tar.gz
# rm -rf clash-linux-amd64.tar.gz
# mv clash clash_dev

# # Clash TUN
# VERSION=$(curl -sS https://raw.githubusercontent.com/vernesong/OpenClash/core/dev/core_version | awk 'NR==2')
# wget https://raw.githubusercontent.com/vernesong/OpenClash/core/master/premium/clash-linux-amd64-$VERSION.gz
# gzip -d clash-linux-amd64-$VERSION.gz
# rm -rf clash-linux-amd64-$VERSION.gz
# mv clash-linux-amd64-$VERSION clash_tun

# # Clash Meta
# wget https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz
# tar -zxvf clash-linux-amd64.tar.gz
# rm -rf clash-linux-amd64.tar.gz
# mv clash clash_meta

# # Use clash_dev as default core
# mv clash_dev clash



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

# # customize
# sed -i 's/192.168.1.1/192.168.2.253/g' /home/build/immortalwrt/package/base-files/files/bin/config_generate
# # TTYD 免登录
# sed -i 's|/bin/login|/bin/login -f root|g' /home/build/immortalwrt/feeds/packages/utils/ttyd/files/ttyd.config

# 输出调试信息
echo "$(date '+%Y-%m-%d %H:%M:%S') - 开始编译..."

# 定义所需安装的包列表 下列插件你都可以自行删减
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES git"
PACKAGES="$PACKAGES luci"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-diskman-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
# 服务——FileBrowser 用户名admin 密码admin
PACKAGES="$PACKAGES luci-i18n-filebrowser-go-zh-cn"
PACKAGES="$PACKAGES luci-app-argon-config"
PACKAGES="$PACKAGES luci-i18n-argon-config-zh-cn"
#24.10
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-i18n-ttyd-zh-cn"
# PACKAGES="$PACKAGES luci-i18n-passwall-zh-cn"
PACKAGES="$PACKAGES luci-app-openclash"
# PACKAGES="$PACKAGES luci-i18n-homeproxy-zh-cn"
# PACKAGES="$PACKAGES openssh-sftp-server"
# 增加几个必备组件 方便用户安装iStore
# PACKAGES="$PACKAGES fdisk"
# PACKAGES="$PACKAGES script-utils"
# PACKAGES="$PACKAGES luci-i18n-samba4-zh-cn"
#customize
PACKAGES="$PACKAGES luci-i18n-upnp-zh-cn"
PACKAGES="$PACKAGES luci-app-adguardhome"
PACKAGES="$PACKAGES luci-app-nikki"
PACKAGES="$PACKAGES luci-app-lucky"
# zsh 终端
PACKAGES="$PACKAGES zsh"
# Vim 完整版，带语法高亮
PACKAGES="$PACKAGES vim-fuller"
# Netdata 系统监控界面
PACKAGES="$PACKAGES netdata"


# 判断是否需要编译 Docker 插件
if [ "$INCLUDE_DOCKER" = "yes" ]; then
    PACKAGES="$PACKAGES luci-i18n-dockerman-zh-cn"
    echo "Adding package: luci-i18n-dockerman-zh-cn"
fi

# 构建镜像
echo "$(date '+%Y-%m-%d %H:%M:%S') - Building image with the following packages:"
echo "$PACKAGES"

make image PROFILE="generic" GRUB_BIOS_PARTSIZE=4 PACKAGES="$PACKAGES" FILES="/home/build/immortalwrt/files" ROOTFS_PARTSIZE=$PROFILE

if [ $? -ne 0 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Error: Build failed!"
    exit 1
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') - Build completed successfully."
