#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== NodePass ===${RESET}"
    echo -e "${GREEN}1) 安装面板${RESET}"
    echo -e "${GREEN}2) 主控管理${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/NodePassDash.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在卸载...${RESET}"
            bash <(wget -qO- https://run.nodepass.eu/np.sh)
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