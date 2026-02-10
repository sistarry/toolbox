#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

menu() {
    clear
    echo -e "${GREEN}=== VPSTG 通知管理 ===${RESET}"
    echo -e "${GREEN}1) 系统信息${RESET}"
    echo -e "${GREEN}2) 网卡信息${RESET}"
    echo -e "${GREEN}3) Docker信息${RESET}"
    echo -e "${GREEN}4) 流量日报管理工具${RESET}"
    echo -e "${GREEN}5) VPS遥控器${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}正在运行系统信息脚本...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/vpsx.sh)
            pause
            ;;
        2)
            echo -e "${GREEN}正在运行网卡信息脚本...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/vpsw.sh)
            pause
            ;;
        3)
            echo -e "${GREEN}正在运行Docker信息脚本...${RESET}"
            bash <(curl -sL https://raw.githubusercontent.com/Polarisiu/toy/main/vpsd.sh)
            pause
            ;;
        4)
            echo -e "${GREEN}正在运行流量日报管理工具...${RESET}"
            bash -c "$(curl -L https://raw.githubusercontent.com/SumMoonYou/vps_traffic/refs/heads/main/vps_vnstat_telegram.sh)" @ install
            pause
            ;;
        5)
            echo -e "${GREEN}正在运行VPS遥控器...${RESET}"
            curl -fsSL https://raw.githubusercontent.com/MEILOI/VPS_BOT_X/main/vps_bot-x/install.sh -o install.sh && chmod +x install.sh && bash install.sh
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
