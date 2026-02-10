#!/bin/bash

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
NC="\033[0m"  # 无颜色

# 系统检查部分
echo -e "\033[1;36m系统检查\033[0m"
echo -e "\033[38;5;81m────────────────────────\033[0m"

# 检查 telnet 并安装
echo -n "✓ Telnet......... "
if command -v telnet &> /dev/null; then
    echo -e "${GREEN}已安装${NC}"
else
    echo -e "${RED}未安装${NC}"
    echo "正在安装 telnet..."

    if command -v apt-get &> /dev/null; then
        apt-get update && apt-get install -y telnet
    elif command -v yum &> /dev/null; then
        yum install -y telnet
    elif command -v dnf &> /dev/null; then
        dnf install -y telnet
    elif command -v apk &> /dev/null; then
        apk add --no-cache busybox-extras
    else
        echo -e "${RED}无法自动安装 telnet，请手动安装${NC}"
    fi

    if command -v telnet &> /dev/null; then
        echo -e "安装完成 ${GREEN}已安装${NC}"
    else
        echo -e "${RED}安装失败${NC}"
    fi
fi

# 端口检测
echo -e "\n\033[1;36m端口检测\033[0m"
echo -e "\033[38;5;81m────────────────────────\033[0m"

port=25
timeout=3
host="smtp.qq.com"

if command -v telnet &> /dev/null; then
    telnet_output=$( (echo quit | timeout $timeout telnet $host $port) 2>&1 )
    echo "$telnet_output" | grep -E "Connected|Connection"

    if echo "$telnet_output" | grep -qE "Connected|Escape character"; then
        echo -e "✓ 端口 $port........ ${GREEN}当前可用${NC}"
    else
        echo -e "✗ 端口 $port........ ${RED}当前不可用${NC}"
    fi
else
    echo -e "✗ Telnet 未安装，无法检测端口"
fi
