#!/bin/bash

# 颜色定义
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# 默认设置为国外
IS_CN=false

# 获取国家代码(CN)
COUNTRY=$(curl -s --max-time 5 ipinfo.io/country)
    
if [ "$COUNTRY" = "CN" ]; then
    IS_CN=true
fi

# 根据地理位置执行对应的安装命令
if [ "$IS_CN" = true ]; then
    
    # 执行国内加速安装
    bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/CN/CNShellCrash.sh)
else
    # 执行官方安装
    bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ShellCrash.sh)
fi