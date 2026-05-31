#!/bin/bash
# ========================================
# Alpine系统管理菜单
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
    echo -e "${ORANGE}╔════════════════════════════╗${RESET}"
    echo -e "${ORANGE}   Alpine工具箱(快捷指令:A/a)  ${RESET}"
    echo -e "${ORANGE}╚════════════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] 系统更新${RESET}"
    echo -e "${YELLOW}[02] 系统信息${RESET}"
    echo -e "${YELLOW}[03] 系统清理${RESET}"
    echo -e "${YELLOW}[04] 系统重启${RESET}"
    echo -e "${YELLOW}[05] 修改SSH端口${RESET}"
    echo -e "${YELLOW}[06] 修改root密码${RESET}"
    echo -e "${YELLOW}[07] SSH密钥登录${RESET}"
    echo -e "${YELLOW}[08] 防火墙管理${RESET}"
    echo -e "${YELLOW}[09] Fail2Ban${RESET}"
    echo -e "${YELLOW}[10] 更换系统源${RESET}"
    echo -e "${YELLOW}[11] 切换字体${RESET}"
    echo -e "${YELLOW}[12] 修改主机名${RESET}"
    echo -e "${YELLOW}[13] DNS设置${RESET}"
    echo -e "${YELLOW}[14] Docker管理${RESET}"
    echo -e "${YELLOW}[15] 反向代理${RESET}"
    echo -e "${YELLOW}[16] Shadowsocks${RESET}"
    echo -e "${YELLOW}[17] Reality${RESET}"
    echo -e "${YELLOW}[18] Hysteria2${RESET}"
    echo -e "${YELLOW}[19] Anytls${RESET}"
    echo -e "${YELLOW}[20] Anytls+Reality${RESET}"
    echo -e "${YELLOW}[21] Tuicv5${RESET}"
    echo -e "${YELLOW}[22] MTProto${RESET}"
    echo -e "${YELLOW}[23] Socks5${RESET}"
    echo -e "${YELLOW}[24] NaïveProxy${RESET}"
    echo -e "${YELLOW}[25] Xray-Argo${RESET}"
    echo -e "${YELLOW}[26] Vmess-ws${RESET}"
    echo -e "${YELLOW}[27] Vless-httpupgrade${RESET}"
    echo -e "${YELLOW}[28] Vless-Reality-xhttp${RESET}"
    echo -e "${YELLOW}[29] Vless-Encryption${RESET}"
    echo -e "${YELLOW}[30] Vless-Encryption-Reality${RESET}"
    echo -e "${YELLOW}[31] F佬Sing-box${RESET}"
    echo -e "${YELLOW}[32] vless-all-in-one${RESET}"
    echo -e "${YELLOW}[33] 3X-UI面板${RESET}"
    echo -e "${YELLOW}[34] Realm-xwPF${RESET}"
    echo -e "${YELLOW}[35] Emby反代${RESET}"
    echo -e "${YELLOW}[36] 卸载探针${RESET}"
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${YELLOW}[00] 退出${RESET}"
    echo -ne "${RED}请输入操作编号: ${RESET}"
    read choice
    case "$choice" in
        1) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/update.sh) ;;
        2) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/vpsinfo.sh) ;;
        3) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APClear.sh) ;;
        4) sudo reboot ;;
        5) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APSSHDK.sh) ;;
        6) sudo passwd root ;;
        7) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APSSHKey.sh) ;;
        8) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APfirewall.sh) ;;
        9) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APFail2Ban.sh) ;;
        10) bash <(curl -sSL https://linuxmirrors.cn/main.sh) ;;
        11) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APZT.sh) ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/home.sh) ;;
        13) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APDNS.sh) ;;
        14) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APDocker.sh) ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APFD.sh) ;;
        16) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APShadowsocks-Rust.sh) ;;
        17) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APRealityX.sh) ;;
        18) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APHy2S.sh) ;;
        19) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APAnyTLSS.sh) ;;
        20) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APAnyRealityS.sh) ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APTuicv5S.sh) ;;
        22) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APMTProto.sh) ;;
        23) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APSocks5X.sh) ;;
        24) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APNaiveProxyS.sh) ;;
        25) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/2go.sh) ;;
        26) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APVmesswsS.sh) ;;
        27) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APVlesshttpupgradeX.sh) ;;
        28) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APVlessRealityxhttpX.sh) ;;
        29) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APVlessEncryptionX.sh) ;;
        30) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/APVlessEncryptionRalityX.sh) ;;
        31) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) ;;
        32) wget -O vless-server.sh https://raw.githubusercontent.com/Zyx0rx/vless-all-in-one/main/vless-server.sh && chmod +x vless-server.sh && ./vless-server.sh ;;
        33) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/AP3X-UI.sh) ;;
        34) wget -qO- https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install ;;
        35) curl -fsSL -o install.sh https://raw.githubusercontent.com/admintors/emby-proxy-alpine-lite/main/install.sh && bash install.sh ;;
        36) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/toy/unagent.sh) ;;
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

            echo -e "${GREEN}✅ 脚本已更新${RESET}"
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
}


# ================== 主循环 ==================
while true; do
    menu
done
