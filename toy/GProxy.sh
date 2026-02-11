#!/usr/bin/env bash
# ==================================================
# GProxy 一键管理脚本
# 安装 / SSH密钥 / 加速测试 / 更新 / 卸载
# ==================================================

set -e

# ========= 基础配置 =========
BASE_DIR="/opt/gproxy-manager"
GPROXY_DIR="/opt/gproxy-tool"
SCRIPT_PATH="$BASE_DIR/gproxy.sh"

SSH_SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/ssh.sh"
GPROXY_REPO="https://github.com/xtianowner/gproxy-tool.git"

mkdir -p "$BASE_DIR"

# ========= 颜色 =========
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# ========= 通用函数 =========
pause(){
    read -p "$(echo -e ${GREEN}按回车返回菜单${RESET})"
}

line(){
    echo -e "${GREEN}----------------------------------------${RESET}"
}

# ========= SSH 密钥配置 =========
setup_ssh(){
    echo -e "${YELLOW}正在配置 SSH 密钥...${RESET}"
    bash <(curl -fsSL "$SSH_SCRIPT_URL")
}

# ========= 安装 =========
install_gproxy(){

    if [[ -d "$GPROXY_DIR" ]]; then
        echo -e "${YELLOW}已安装，跳过${RESET}"
        return
    fi

    echo -e "${GREEN}开始安装 GProxy...${RESET}"

    apt update -y
    apt install -y git curl

    git clone "$GPROXY_REPO" "$GPROXY_DIR"

    cd "$GPROXY_DIR"
    sudo sh install.sh

    echo -e "${GREEN}安装完成 ✔${RESET}"
}

# ========= 首次测试 =========
test_gproxy(){
    echo -e "${GREEN}运行加速测试...${RESET}"
    gproxy curl -I https://www.google.com || true
}

# ========= 更新 =========
update_gproxy(){

    if [[ ! -d "$GPROXY_DIR" ]]; then
        echo -e "${RED}未安装${RESET}"
        return
    fi

    echo -e "${GREEN}更新中...${RESET}"

    cd "$GPROXY_DIR"
    git pull
    sudo sh install.sh

    echo -e "${GREEN}更新完成 ✔${RESET}"
}

# ========= 卸载 =========
uninstall_gproxy(){

    read -rp "确认卸载 GProxy？(y/N): " yn
    [[ ! "$yn" =~ ^[Yy]$ ]] && return

    if [[ -f "$GPROXY_DIR/uninstall.sh" ]]; then
        sudo sh "$GPROXY_DIR/uninstall.sh"
    fi

    rm -rf "$GPROXY_DIR"

    echo -e "${RED}已卸载完成${RESET}"
}

# ========= 菜单 =========
menu(){

while true
do
clear
echo -e "${GREEN}GProxy SSH 隧道加速管理器${RESET}"
echo -e "${GREEN}1. SSH密钥自动配置${RESET}"
echo -e "${GREEN}2. 安装 GProxy${RESET}"
echo -e "${GREEN}3. 加速测试 (curlGoogle)${RESET}"
echo -e "${GREEN}4. 更新 GProxy${RESET}"
echo -e "${GREEN}5. 卸载 GProxy${RESET}"
echo -e "${GREEN}0. 退出${RESET}"
read -p "$(echo -e ${GREEN}请选择操作: ${RESET})" num
case "$num" in
1) setup_ssh ; pause ;;
2) install_gproxy ; pause ;;
3) test_gproxy ; pause ;;
4) update_gproxy ; pause ;;
5) uninstall_gproxy ; pause ;;
0) exit 0 ;;
*) echo -e "${GREEN}无效选项${RESET}" ; sleep 1 ;;
esac

done
}

menu
