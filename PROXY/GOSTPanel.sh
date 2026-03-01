#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== GOSTPanel ===${RESET}"
    echo -e "${GREEN}1) 安装面板${RESET}"
    echo -e "${GREEN}2) 卸载节点${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/GostPaneldocker.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在卸载...${RESET}"
            bash <(curl -sSL https://raw.githubusercontent.com/code-gopher/gostPanel/master/scripts/install_node.sh) uninstall
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
