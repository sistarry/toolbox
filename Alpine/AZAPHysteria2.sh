#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APHysteria2.sh"

install_Hysteria() {
    echo -e "${GREEN}正在安装 Hysteria2...${RESET}"
    bash <(curl -sL $SCRIPT_URL)
    pause
}

uninstall_Hysteria() {
    echo -e "${GREEN}正在卸载 Hysteria2...${RESET}"
    bash <(curl -sL $SCRIPT_URL) uninstall
    pause
}

pause() {
    read -p $'\033[32m按回车返回菜单...\033[0m'
    menu
}

menu() {
    clear
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN}        Hysteria2 管理工具      ${RESET}"
    echo -e "${GREEN}==============================${RESET}"
    echo -e "${GREEN} 1) 安装 Hysteria2${RESET}"
    echo -e "${GREEN} 2) 卸载 Hysteria2${RESET}"
    echo -e "${GREEN} 0) 退出${RESET}"
    read -p $'\033[32m 请选择: \033[0m' choice

    case $choice in
        1) install_Hysteria ;;
        2) uninstall_Hysteria ;;
        0) exit 0 ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            sleep 1
            menu
            ;;
    esac
}

menu