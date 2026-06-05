#!/bin/bash
# =========================================
# VPS 网络信息管理脚本（自动更新 + Telegram + 定时任务 + 卸载）
# =========================================

# ================== 配置 ==================
SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/toy/network.sh"
SCRIPT_PATH="/opt/vpsnetwork/vps_network.sh"
CONFIG_FILE="/opt/vpsnetwork/.vps_tgg_config"
OUTPUT_FILE="/tmp/vps_network_info.txt"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ================== 下载或更新脚本 ==================
download_script(){
    mkdir -p "$(dirname "$SCRIPT_PATH")"
    curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
}

# ================== Telegram 配置 ==================
setup_telegram(){
    # 只有在发送 Telegram 或设置任务时才提示配置
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "第一次使用 Telegram 功能，需要配置参数"
        read -rp "Bot Token: " TG_BOT_TOKEN
        read -rp "Chat ID: " TG_CHAT_ID
        read -rp "服务器名称: " SERVER_NAME
        cat > "$CONFIG_FILE" <<EOC
TG_BOT_TOKEN="$TG_BOT_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
SERVER_NAME="$SERVER_NAME"
EOC
        chmod 600 "$CONFIG_FILE"
        echo -e "${GREEN}✅ 配置已保存到 $CONFIG_FILE${RESET}"
    fi
    source "$CONFIG_FILE"
}


modify_config(){
    echo "修改 Telegram 配置:"
    read -rp "新的 Bot Token: " TG_BOT_TOKEN
    read -rp "新的 Chat ID: " TG_CHAT_ID
    read -rp "服务器名称: " SERVER_NAME
    cat > "$CONFIG_FILE" <<EOC
TG_BOT_TOKEN="$TG_BOT_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
SERVER_NAME="$SERVER_NAME"
EOC
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✅ 配置已更新${RESET}"
}

# ================== 收集网络信息 ==================
collect_network_info(){
    echo "收集网络信息..."
    {
        echo "================= VPS 网络信息 ================="
        echo "服务器: $SERVER_NAME"
        echo "日期: $(date)"
        echo "主机名: $(hostname)"
        echo ""
        echo "=== 系统信息 ==="
        if command -v hostnamectl >/dev/null 2>&1; then
            hostnamectl
        else
            cat /etc/os-release
        fi
        echo ""
    } > "$OUTPUT_FILE"

    echo "=== 网络接口信息 ===" >> "$OUTPUT_FILE"
    for IFACE in $(ls /sys/class/net/); do
        DESC="$IFACE"
        [ "$IFACE" = "lo" ] && DESC="$IFACE (回环接口)"
        [ "$IFACE" != "lo" ] && DESC="$IFACE (主网卡)"
        echo "------------------------" >> "$OUTPUT_FILE"
        echo "接口: $DESC" >> "$OUTPUT_FILE"

        IPV4=$(ip -4 addr show $IFACE | grep -oP 'inet \K[\d./]+')
        [ -n "$IPV4" ] && echo "IPv4: $IPV4" >> "$OUTPUT_FILE" || echo "IPv4: 无" >> "$OUTPUT_FILE"

        IPV6=$(ip -6 addr show $IFACE scope global | grep -oP 'inet6 \K[0-9a-f:]+/[0-9]+')
        [ -n "$IPV6" ] && echo "IPv6: $IPV6" >> "$OUTPUT_FILE" || echo "IPv6: 无" >> "$OUTPUT_FILE"

        LL6=$(ip -6 addr show $IFACE scope link | grep -oP 'inet6 \K[0-9a-f:]+/[0-9]+')
        [ -n "$LL6" ] && echo "链路本地 IPv6: $LL6" >> "$OUTPUT_FILE"

        MAC=$(cat /sys/class/net/$IFACE/address)
        echo "MAC: $MAC" >> "$OUTPUT_FILE"
    done
    echo "------------------------" >> "$OUTPUT_FILE"

    echo "" >> "$OUTPUT_FILE"
    echo "=== 默认路由 ===" >> "$OUTPUT_FILE"
    echo "IPv4 默认路由:" >> "$OUTPUT_FILE"
    ip route show default >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo "IPv6 默认路由:" >> "$OUTPUT_FILE"
    ip -6 route show default >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    echo "=== 网络连通性测试 ===" >> "$OUTPUT_FILE"
    ping -c 3 8.8.8.8 >> "$OUTPUT_FILE" 2>&1
    ping6 -c 3 google.com >> "$OUTPUT_FILE" 2>&1

    GATEWAY6=$(ip -6 route | grep default | awk '{print $3}')
    if [ -n "$GATEWAY6" ]; then
        ping6 -c 2 $GATEWAY6 >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "IPv6 网关 $GATEWAY6 可达" >> "$OUTPUT_FILE"
        else
            echo "⚠️ IPv6 网关 $GATEWAY6 不可达" >> "$OUTPUT_FILE"
        fi
    fi
}

# ================== 发送到 Telegram ==================
send_to_telegram(){
    [ ! -f "$OUTPUT_FILE" ] && collect_network_info
    source "$CONFIG_FILE"
    TG_MSG="📡 [$SERVER_NAME] VPS 网络信息\`\`\`$(cat $OUTPUT_FILE)\`\`\`"
    curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d parse_mode="Markdown" \
        -d text="$TG_MSG" >/dev/null 2>&1
    echo -e "${GREEN}✅ 信息已发送到 Telegram${RESET}"
    rm -f "$OUTPUT_FILE"
}

# ================== 定时任务管理 ==================
setup_cron_job(){
    enable_cron_service
    echo -e "${GREEN}===== 定时任务管理 =====${RESET}"
    echo -e "${GREEN}1) 每天0点${RESET}"
    echo -e "${GREEN}2) 每周一0点${RESET}"
    echo -e "${GREEN}3) 每月1号0点${RESET}"
    echo -e "${GREEN}4) 每5分钟一次${RESET}"
    echo -e "${GREEN}5) 每10分钟一次${RESET}"
    echo -e "${GREEN}6) 自定义时间(Cron表达式)${RESET}"
    echo -e "${GREEN}7) 删除任务${RESET}"
    echo -e "${GREEN}8) 查看当前任务${RESET}"
    echo -e "${GREEN}0) 返回菜单${RESET}"

    read -rp "$(echo -e ${GREEN}请选择: ${RESET})" cron_choice
    CRON_CMD="bash $SCRIPT_PATH send"

    case $cron_choice in
        1) CRON_TIME="0 0 * * *" ;;
        2) CRON_TIME="0 0 * * 1" ;;
        3) CRON_TIME="0 0 1 * *" ;;
        4) CRON_TIME="*/5 * * * *" ;;
        5) CRON_TIME="*/10 * * * *" ;;
        6)
            echo -e "${YELLOW}请输入 Cron 表达式 (分 时 日 月 周)${RESET}"
            read -rp "Cron: " CRON_TIME
            [ $(echo "$CRON_TIME" | awk '{print NF}') -ne 5 ] && echo -e "${RED}❌ 格式错误${RESET}" && return ;;
        7)
            crontab -l 2>/dev/null | grep -v "$CRON_CMD" | crontab -
            echo -e "${RED}❌ 已删除任务${RESET}"; return ;;
        8)
            crontab -l 2>/dev/null | grep "$CRON_CMD" || echo "暂无任务"; return ;;
        0) return ;;
        *) echo -e "${RED}无效选择${RESET}"; return ;;
    esac

    (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$CRON_TIME $CRON_CMD") | crontab -
    echo -e "${GREEN}✅ 定时任务设置成功: $CRON_TIME${RESET}"
}

# ================== 卸载脚本 ==================
uninstall_script(){
    echo -e "${YELLOW}正在卸载脚本、配置及定时任务...${RESET}"
    crontab -l 2>/dev/null | grep -v "bash $SCRIPT_PATH" | crontab -
    rm -rf "$SCRIPT_PATH" "$CONFIG_FILE" "$OUTPUT_FILE" /opt/vpsnetwork
    echo -e "${GREEN}✅ 卸载完成${RESET}"; exit 0
}

# ================== cron 服务检查 ==================
enable_cron_service(){
    command -v systemctl >/dev/null 2>&1 && (systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null)
    command -v service >/dev/null 2>&1 && (service cron start 2>/dev/null || service crond start 2>/dev/null)
}

# ================== 只查看网络信息 ==================
view_network_info(){
    collect_network_info
    cat "$OUTPUT_FILE"
}

# ================== 菜单 ==================
menu(){
    while true; do
        clear
        echo -e "${GREEN}===== VPS 网络管理菜单 =====${RESET}"
        echo -e "${GREEN}1) 查看网络信息${RESET}"
        echo -e "${GREEN}2) 发送网络信息到 Telegram${RESET}"
        echo -e "${GREEN}3) 修改Telegram配置${RESET}"
        echo -e "${GREEN}4) 设置定时任务${RESET}"
        echo -e "${GREEN}5) 卸载${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        read -rp "$(echo -e ${GREEN}请选择: ${RESET})" choice
        case $choice in
            1) view_network_info ;;
            2) setup_telegram; collect_network_info; send_to_telegram ;;
            3) modify_config ;;
            4) setup_telegram; setup_cron_job ;;
            5) uninstall_script ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选择${RESET}" ;;
        esac
        read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
    done
}


# ================== 命令行模式支持 send ==================
if [ "$1" == "send" ]; then
    setup_telegram
    collect_network_info
    send_to_telegram
    exit 0
fi

# ================== 初始化 ==================
download_script
menu
