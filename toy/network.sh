#!/bin/bash
# =========================================
# VPS 网络信息管理脚本（自动初始化 + Telegram + 定时任务 + 卸载）
# =========================================

# ================== 配置 ==================
SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/toy/network.sh"  # 脚本下载地址
SCRIPT_PATH="/opt/vpsnetwork/vps_network.sh"  # 脚本存放路径
CONFIG_FILE="/opt/vpsnetwork/.vps_tgg_config"
OUTPUT_FILE="/tmp/vps_network_info.txt"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
RESET='\033[0m'

# ================== 自动下载与初始化 ==================
initialize_script() {
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo -e "${GREEN}首次运行：安装设置权限...${RESET}"
        mkdir -p "$(dirname "$SCRIPT_PATH")"
        curl -sSL "$SCRIPT_URL" -o "$SCRIPT_PATH"
        chmod +x "$SCRIPT_PATH"
    fi
}

# ================== Telegram 配置 ==================
setup_telegram() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "第一次运行，需要配置 Telegram 参数"
        read -rp "Bot Token: " TG_BOT_TOKEN
        read -rp "Chat ID: " TG_CHAT_ID
        echo "TG_BOT_TOKEN=\"$TG_BOT_TOKEN\"" > "$CONFIG_FILE"
        echo "TG_CHAT_ID=\"$TG_CHAT_ID\"" >> "$CONFIG_FILE"
        chmod 600 "$CONFIG_FILE"
        echo -e "${GREEN}✅ 配置已保存到 $CONFIG_FILE${RESET}"
    fi
    source "$CONFIG_FILE"
}

modify_config() {
    echo "修改 Telegram 配置:"
    read -rp "新的 Bot Token: " TG_BOT_TOKEN
    read -rp "新的 Chat ID: " TG_CHAT_ID
    echo "TG_BOT_TOKEN=\"$TG_BOT_TOKEN\"" > "$CONFIG_FILE"
    echo "TG_CHAT_ID=\"$TG_CHAT_ID\"" >> "$CONFIG_FILE"
    chmod 600 "$CONFIG_FILE"
    echo -e "${GREEN}✅ 配置已更新${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
}

# ================== 收集网络信息 ==================
collect_network_info() {
    echo "收集网络信息..."
    {
    echo "================= VPS 网络信息 ================="
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
send_to_telegram() {
    if [ ! -f "$OUTPUT_FILE" ]; then
        echo "⚠️ 文件 $OUTPUT_FILE 不存在，请先收集网络信息。"
        read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
        return
    fi
    source "$CONFIG_FILE"
    TG_MSG="📡 VPS 网络信息\`\`\`$(cat $OUTPUT_FILE)\`\`\`"
    curl -s -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d parse_mode="Markdown" \
        -d text="$TG_MSG" >/dev/null
    echo -e "${GREEN}✅ 信息已发送到 Telegram${RESET}"
    rm -f "$OUTPUT_FILE"
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
}

# ================== 删除临时文件 ==================
delete_file() {
    [ -f "$OUTPUT_FILE" ] && rm -f "$OUTPUT_FILE" && echo -e "${GREEN}✅ 删除临时文件${RESET}"
    read -p "按回车返回菜单..."
}

# ================== 定时任务管理 ==================
setup_cron_job() {
    enable_cron_service

    echo -e "${GREEN}===== 定时任务管理 =====${RESET}"
    echo -e "${GREEN}1) 每天 0点${RESET}"
    echo -e "${GREEN}2) 每周一 0点${RESET}"
    echo -e "${GREEN}3) 每月 1号 0点${RESET}"
    echo -e "${GREEN}4) 每5分钟一次${RESET}"
    echo -e "${GREEN}5) 每10分钟一次${RESET}"
    echo -e "${GREEN}6) 自定义时间 (Cron表达式) ⭐${RESET}"
    echo -e "${GREEN}7) 删除任务${RESET}"
    echo -e "${GREEN}8) 查看当前任务${RESET}"
    echo -e "${GREEN}0) 返回菜单${RESET}"

    read -p "$(echo -e ${GREEN}请选择: ${RESET}) " cron_choice

    CRON_CMD="bash $SCRIPT_PATH --cron"

    case $cron_choice in
        1) CRON_TIME="0 0 * * *" ;;
        2) CRON_TIME="0 0 * * 1" ;;
        3) CRON_TIME="0 0 1 * *" ;;
        4) CRON_TIME="*/5 * * * *" ;;
        5) CRON_TIME="*/10 * * * *" ;;

        6)
            echo -e "${YELLOW}请输入 Cron 表达式 (分 时 日 月 周)${RESET}"
            echo -e "${YELLOW}示例: 30 3 * * *  → 每天03:30${RESET}"
            read -rp "Cron: " CRON_TIME
            count=$(echo "$CRON_TIME" | awk '{print NF}')
            if [ "$count" -ne 5 ]; then
                echo -e "${RED}❌ 格式错误，必须5段${RESET}"
                read -p "回车继续..."
                return
            fi
            ;;

        7)
            crontab -l 2>/dev/null | grep -v "$CRON_CMD" | crontab -
            echo -e "${RED}❌ 已删除任务${RESET}"
            read -p "回车继续..."
            return
            ;;

        8)
            echo -e "${YELLOW}当前任务:${RESET}"
            crontab -l 2>/dev/null | grep "$CRON_CMD" || echo "暂无任务"
            read -p "回车继续..."
            return
            ;;

        0) return ;;
        *) echo -e "${RED}无效选择${RESET}"; return ;;
    esac

    (crontab -l 2>/dev/null | grep -v "$CRON_CMD"; echo "$CRON_TIME $CRON_CMD") | crontab -

    echo -e "${GREEN}✅ 定时任务设置成功: $CRON_TIME${RESET}"
    read -p "$(echo -e ${GREEN}按回车返回菜单${RESET})"
}


# ================== 卸载脚本 ==================
uninstall_script() {
    echo -e "${YELLOW}正在卸载脚本并清理定时任务...${RESET}"

    # 清理定时任务（存在才处理）
    if crontab -l >/dev/null 2>&1; then
        crontab -l | grep -v "bash $SCRIPT_PATH" | crontab -
    fi

    # 删除文件和目录
    rm -rf "$SCRIPT_PATH" "$CONFIG_FILE" "$OUTPUT_FILE" /opt/vpsnetwork

    echo -e "${GREEN}✅ 脚本已卸载完成${RESET}"
    exit 0
}


# ================== 确保 cron 服务 ==================
enable_cron_service(){
  if command -v systemctl >/dev/null 2>&1; then
    systemctl enable --now cron 2>/dev/null || systemctl enable --now crond 2>/dev/null
  elif command -v service >/dev/null 2>&1; then
    service cron start 2>/dev/null || service crond start 2>/dev/null
  fi
}

# ================== 菜单 ==================
menu() {
    while true; do
        clear
        echo -e "${GREEN}===== VPS 网络管理菜单 =====${RESET}"
        echo -e "${GREEN}1) 查看并发送网络信息到 Telegram${RESET}"
        echo -e "${GREEN}2) 修改 Telegram 配置${RESET}"
        echo -e "${GREEN}3) 删除临时文件${RESET}"
        echo -e "${GREEN}4) 定时任务管理${RESET}"
        echo -e "${GREEN}5) 卸载${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        read -p "$(echo -e ${GREEN}请选择: ${RESET})" choice
        case $choice in
            1) setup_telegram; collect_network_info; send_to_telegram ;;
            2) modify_config ;;
            3) delete_file ;;
            4) setup_cron_job ;;
            5) uninstall_script ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选择${RESET}"; read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})" ;;
        esac
    done
}

# ================== 支持 --cron 参数 ==================
if [ "$1" == "--cron" ]; then
    setup_telegram
    collect_network_info
    send_to_telegram
    exit 0
fi

# ================== 初始化脚本 ==================
initialize_script
setup_telegram

# ================== 启动菜单 ==================
menu
