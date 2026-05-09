#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

INSTALL_URL="https://raw.githubusercontent.com/arloor/iptablesUtils/master/natcfg.sh"
UNINSTALL_URL="https://raw.githubusercontent.com/arloor/iptablesUtils/master/dnat-uninstall.sh"

install_dnat() {
    echo -e "${GREEN}正在安装 iptables DDNS 转发...${RESET}"
    bash <(curl -fsSL $INSTALL_URL)
    pause
}

uninstall_dnat() {
    echo -e "${GREEN}正在卸载 iptables DDNS 转发...${RESET}"
    bash <(curl -SsLf $UNINSTALL_URL)
    pause
}

show_logs() {
    echo -e "${GREEN}正在查看 dnat 日志...${RESET}"
    journalctl -exu dnat
    pause
}

pause() {
    read -p $'\033[32m按回车返回菜单...\033[0m'
    menu
}

menu() {
    clear
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}    iptables DDNS 转发管理         ${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN} 1) 安装 DDNS 转发${RESET}"
    echo -e "${GREEN} 2) 卸载 DDNS 转发${RESET}"
    echo -e "${GREEN} 3) 查看 dnat 日志${RESET}"
    echo -e "${GREEN} 0) 退出${RESET}"
    read -p $'\033[32m 请选择: \033[0m' choice

    case $choice in
        1) install_dnat ;;
        2) uninstall_dnat ;;
        3) show_logs ;;
        0) exit 0 ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            sleep 1
            menu
            ;;
    esac
}

menu