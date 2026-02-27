#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== Realm 转发管理 ===${RESET}"
    echo -e "${GREEN}1) Realm-xwPF${RESET}"
    echo -e "${GREEN}2) ZelayRealm转发面板${RESET}"
    echo -e "${GREEN}3) Realm转发(Web面板)${RESET}"
    echo -e "${GREEN}4) EZRealm转发${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在安装 Realm-xwPF...${RESET}"
            wget -qO- https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install
            pause
            ;;
        2)
            echo -e "${GREEN}正在Zelay Realm转发面板...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ZelayRealm.sh)
            ;;
        3)
            echo -e "${GREEN}正在Realm转发(Web面板)...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh)
            pause
            ;;
        4)
            echo -e "${GREEN}正在EZRealm转发...${RESET}"
            wget -N https://raw.githubusercontent.com/qqrrooty/EZrealm/main/realm.sh && chmod +x realm.sh && ./realm.sh
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
