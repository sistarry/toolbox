#!/bin/bash

# 颜色定义
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

while true; do
    clear
    echo -e "${GREEN}=====网络质量体检脚本=====${RESET}"
    echo -e "${GREEN}1. IP解锁-IPv4${RESET}"
    echo -e "${GREEN}2. IP解锁-IPv6${RESET}"
    echo -e "${GREEN}3. 网络质量-IPv4${RESET}"
    echo -e "${GREEN}4. 网络质量-IPv6${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -ne "${GREEN}请选择操作: ${RESET}"
    read choice

    case $choice in
        1) bash <(curl -Ls https://IP.Check.Place) -4 ;;
        2) bash <(curl -Ls https://IP.Check.Place) -6 ;;
        3) bash <(curl -Ls https://Net.Check.Place) -4 ;;
        4) bash <(curl -Ls https://Net.Check.Place) -6 ;;
        0) exit 0 ;;
        *) echo -e "${YELLOW}无效选择，请重新输入${RESET}" ;;
    esac

    # 回车提示
    echo -e "${GREEN}按回车键返回菜单...${RESET}"
    read
done
