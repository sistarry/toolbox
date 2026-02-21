#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== Realm 转发管理 ===${RESET}"
    echo -e "${GREEN}1) 国外安装 Realm 转发${RESET}"
    echo -e "${GREEN}2) 国内安装 Realm 转发${RESET}"
    echo -e "${GREEN}3) 国外安装 端口流量狗${RESET}"
    echo -e "${GREEN}4) 国内安装 端口流量狗${RESET}"
    echo -e "${GREEN}5) Zelay Realm转发面板${RESET}"
    echo -e "${GREEN}6) Realm转发(Web面板)${RESET}"
    echo -e "${GREEN}7) EZRealm转发${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在国外环境安装 Realm 转发...${RESET}"
            wget -qO- https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install
            pause
            ;;
        2)
            echo -e "${GREEN}正在国内环境安装 Realm 转发...${RESET}"
            wget -qO- https://v6.gh-proxy.org/https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install
            pause
            ;;
        3)
            echo -e "${GREEN}正在国外环境安装 端口流量狗...${RESET}"
            wget -O port-traffic-dog.sh https://raw.githubusercontent.com/zywe03/realm-xwPF/main/port-traffic-dog.sh && chmod +x port-traffic-dog.sh && ./port-traffic-dog.sh
            pause
            ;;
        4)
            echo -e "${GREEN}正在国内环境安装 端口流量狗...${RESET}"
            wget -O port-traffic-dog.sh https://v6.gh-proxy.org/https://raw.githubusercontent.com/zywe03/realm-xwPF/main/port-traffic-dog.sh && chmod +x port-traffic-dog.sh && ./port-traffic-dog.sh
            pause
            ;;
        5)
            echo -e "${GREEN}正在Zelay Realm转发面板...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ZelayRealm.sh)
            ;;
        6)
            echo -e "${GREEN}正在Realm转发(Web面板)...${RESET}"
            bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh)
            pause
            ;;
        7)
            echo -e "${GREEN}正在EZRealm转发...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Realm.sh)
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
