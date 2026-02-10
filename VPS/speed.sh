#!/bin/bash

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== 三网测速与延迟测试菜单 ===${RESET}"
    echo -e "${GREEN}1) 国外机三网测速${RESET}"
    echo -e "${GREEN}2) 国外机三网延迟测试${RESET}"
    echo -e "${GREEN}3) 国内机三网测速${RESET}"
    echo -e "${GREEN}4) 国内机三网延迟测试${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            bash <(wget -qO- bash.spiritlhl.net/ecs-net)
            pause
            ;;
        2)
            bash <(wget -qO- bash.spiritlhl.net/ecs-ping)
            pause
            ;;
        3)
            bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-net.sh)
            pause
            ;;
        4)
            bash <(wget -qO- --no-check-certificate https://cdn.spiritlhl.net/https://raw.githubusercontent.com/spiritLHLS/ecsspeed/main/script/ecsspeed-ping.sh)
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
