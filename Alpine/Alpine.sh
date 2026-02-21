#!/bin/bash
# ========================================
# Alpine/Ubuntu/Debian/CentOS 系统管理菜单
# 支持永久快捷键 A/a + 自调用循环菜单
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"
BOLD="\033[1m"
ORANGE='\033[38;5;208m'

# ================== 脚本路径 ==================
SCRIPT_PATH="/root/Alpine.sh"
SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/Alpine.sh"
BIN_LINK_DIR="/usr/local/bin"

# ================== 首次运行自动安装 ==================
if [ ! -f "$SCRIPT_PATH" ]; then
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    if [ $? -ne 0 ]; then
        echo -e "${RED}安装失败，请检查网络或 URL${RESET}"
        exit 1
    fi
    chmod +x "$SCRIPT_PATH"

    # 创建快捷键 A/a
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/A"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/a"

    echo -e "${GREEN}✅ 安装完成${RESET}"
    echo -e "${GREEN}✅ 快捷键已添加：A 或 a 可快速启动${RESET}"
fi

# ================== 菜单函数 ==================
menu() {
    clear
    echo -e "${ORANGE}===Alpine系统管理菜单===${RESET}"
    echo -e "${YELLOW}[01] 系统更新${RESET}"
    echo -e "${YELLOW}[02] 修改SSH端口${RESET}"
    echo -e "${YELLOW}[03] 防火墙管理${RESET}"
    echo -e "${YELLOW}[04] Fail2Ban${RESET}"
    echo -e "${YELLOW}[05] 更换系统源${RESET}"
    echo -e "${YELLOW}[06] 系统清理${RESET}"
    echo -e "${YELLOW}[07] 切换字体${RESET}"
    echo -e "${YELLOW}[08] 修改主机名${RESET}"
    echo -e "${YELLOW}[09] Docker管理${RESET}"
    echo -e "${YELLOW}[10] 代理协议${RESET}"
    echo -e "${YELLOW}[11] 3XUI面板${RESET}"
    echo -e "${YELLOW}[12] Realm转发${RESET}"
    echo -e "${YELLOW}[13] 应用商店${RESET}"
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${YELLOW}[00] 退出${RESET}"
    echo -ne "${RED}请输入操作编号: ${RESET}"
    read choice
    case "$choice" in
        1) apk update && apk add --no-cache bash curl wget vim tar sudo git 2>/dev/null \
              || (apt update && apt install -y curl wget vim tar sudo git) \
              || (yum install -y curl wget vim tar sudo git) ;;
        2) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apsdk.sh) ;;
        3) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apfeew.sh) ;;
        4) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apFail2Ban.sh) ;;
        5) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/aphuanyuan.sh) ;;
        6) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apql.sh) ;;
        7) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apcn.sh) ;;
        8) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/aphome.sh) ;;
        9) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apdocker.sh) ;;
        10) wget -O vless-server.sh https://raw.githubusercontent.com/Chil30/vless-all-in-one/main/vless-server.sh && chmod +x vless-server.sh && bash vless-server.sh ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/3xuiAlpine.sh) ;;
        12) wget -qO- https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install ;;
        13) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/Store.sh) ;;
        88)
            echo -e "${YELLOW}🔄 正在更新脚本...${RESET}"
            curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL" || {
                echo -e "${RED}❌ 更新失败，请检查网络${RESET}"
                break
            }
            chmod +x "$SCRIPT_PATH"

            # 重新确保快捷键存在
            ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/A"
            ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/a"

            echo -e "${GREEN}✅ 脚本已更新，可继续使用 A/a 启动${RESET}"
            exec "$SCRIPT_PATH"
            ;;
        99) 
            rm -f "$SCRIPT_PATH" "$BIN_LINK_DIR/A" "$BIN_LINK_DIR/a"
            echo -e "${RED}✅ 卸载完成${RESET}"
            exit 0 ;;
      00|0) exit 0 ;;
        *) echo -e "${RED}无效选择，请重新输入!${RESET}" ;;
    esac
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    menu
}


# ================== 主循环 ==================
menu
