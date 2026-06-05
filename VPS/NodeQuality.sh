#!/bin/bash

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# 默认设置为国外
IS_CN=false

# 获取国家代码 (CN)
COUNTRY=$(curl -s --max-time 5 ipinfo.io/country)

if [ "$COUNTRY" = "CN" ]; then
    IS_CN=true
fi

# 根据地理位置执行对应的安装命令
if [ "$IS_CN" = true ]; then
   
    wget -N https://gitlab.com/dabao/nodequality-proxy/-/raw/main/nodequality-proxy.sh && bash nodequality-proxy.sh ghproxy
else

    # 执行官方安装
    bash <(curl -sL https://run.NodeQuality.com)
fi