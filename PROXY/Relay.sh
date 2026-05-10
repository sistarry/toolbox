#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

PANEL_URL="https://raw.githubusercontent.com/0xUnixIO/relay/main/install.sh"
NODE_URL="https://raw.githubusercontent.com/0xUnixIO/relay/main/install-node.sh"

install_panel() {
    echo -e "${GREEN}正在安装 Relay 面板管理...${RESET}"
    bash <(curl -fsSL $PANEL_URL)
    pause
}

update_node() {
    echo -e "${GREEN}正在升级 Relay 节点...${RESET}"
    bash <(curl -fsSL $NODE_URL)
    pause
}

uninstall_node() {
    echo -e "${GREEN}正在卸载 Relay 节点...${RESET}"
    bash <(curl -fsSL $NODE_URL) --uninstall
    pause
}

pause() {
    read -p $'\033[32m按回车返回菜单...\033[0m'
    menu
}

menu() {
    clear
    echo -e "${GREEN}=================================${RESET}"
    echo -e "${GREEN}        Relay 转发管理          ${RESET}"
    echo -e "${GREEN}=================================${RESET}"
    echo -e "${GREEN} 1) 安装 Relay 面板${RESET}"
    echo -e "${GREEN} 2) 升级 Relay 节点${RESET}"
    echo -e "${GREEN} 3) 卸载 Relay 节点${RESET}"
    echo -e "${GREEN} 0) 退出${RESET}"
    read -p $'\033[32m 请选择: \033[0m' choice

    case $choice in
        1) install_panel ;;
        2) update_node ;;
        3) uninstall_node ;;
        0) exit 0 ;;
        *)
            echo -e "${RED}输入错误，请重新选择${RESET}"
            sleep 1
            menu
            ;;
    esac
}

menu