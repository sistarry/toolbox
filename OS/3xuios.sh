#!/bin/bash

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"


# 获取操作系统 ID
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi

# 安装逻辑判断
case "$OS" in
    alpine)
        # 执行 Alpine 适配版脚本
        bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/3xuiAlpine.sh)
        ;;
    debian|ubuntu|centos|rocky|almalinux|fedora)
        # 执行原版脚本
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        ;;
    *)
        bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
        ;;
esac