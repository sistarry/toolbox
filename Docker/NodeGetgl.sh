#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== NodeGet 监控管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装 NodeGet${RESET}"
    echo -e "${GREEN}2) 安装 NodeGet(PostgreSQL)${RESET}"
    echo -e "${GREEN}3) 管理 NodeGet Agent${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 NodeGet...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/NodeGet.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装 NodeGet(PostgreSQL) ...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/NodeGetPo.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}管理 NodeGet Agent...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/NodeGetAgent.sh)
            pause
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${RESET}"
            sleep 1
            menu
            ;;
    esac
}

pause() {
    read -p $'\033[32m按回车键返回菜单...\033[0m'
    menu
}

menu