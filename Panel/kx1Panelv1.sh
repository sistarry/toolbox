#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== 1Panel v1 开心版 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装部署 v1${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载 1Panel v1${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装部署 1Panel v1 开心版...${RESET}"
            curl -sSL https://resource.1panel.sb/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
            pause
            ;;
        2)
            echo -e "${GREEN}正在更新...${RESET}"
            curl https://resource.1panel.sb/1panel/package/update.sh|bash
            pause
            ;;
        3)
            echo -e "${GREEN}正在卸载 1Panel v1 开心版...${RESET}"
            1pctl uninstall
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
