#!/bin/bash
# ========================================
# qBittorrent 一键管理脚本
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
RED="\033[31m"
YELLOW="\033[33m"
APP_NAME="qbittorrent"
COMPOSE_DIR="/opt/qbittorrent"
COMPOSE_FILE="$COMPOSE_DIR/docker-compose.yml"

get_public_ip() {
    local ip
    for cmd in "curl -4s --max-time 5" "wget -4qO- --timeout=5"; do
        for url in "https://api.ipify.org" "https://ip.sb" "https://checkip.amazonaws.com"; do
            ip=$($cmd "$url" 2>/dev/null) && [[ -n "$ip" ]] && echo "$ip" && return
        done
    done
    for cmd in "curl -6s --max-time 5" "wget -6qO- --timeout=5"; do
        for url in "https://api64.ipify.org" "https://ip.sb"; do
            ip=$($cmd "$url" 2>/dev/null) && [[ -n "$ip" ]] && echo "$ip" && return
        done
    done
    echo "无法获取公网 IP 地址。"
}

function menu() {
    clear
    echo -e "${GREEN}=== qBittorrent 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 卸载(含数据)${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 重启${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice
    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) uninstall_app ;;
        4) view_logs ;;
        5) restart_app ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
    esac
}

function install_app() {
    read -p "请输入 Web UI 端口 [默认:8082]: " input_port
    WEB_PORT=${input_port:-8082}

    read -p "请输入 Torrent 传输端口 [默认:6881]: " input_tport
    TORRENT_PORT=${input_tport:-6881}

    mkdir -p "$COMPOSE_DIR/config" "$COMPOSE_DIR/downloads"

    cat > "$COMPOSE_FILE" <<EOF
services:
  qbittorrent:
    image: linuxserver/qbittorrent
    container_name: qbittorrent
    restart: unless-stopped
    ports:
      - "${TORRENT_PORT}:${TORRENT_PORT}"
      - "${TORRENT_PORT}:${TORRENT_PORT}/udp"
      - "${WEB_PORT}:8080"
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Shanghai
    volumes:
      - ${COMPOSE_DIR}/config:/config
      - ${COMPOSE_DIR}/downloads:/downloads
EOF

    cd "$COMPOSE_DIR"
    docker compose up -d

    SERVER_IP=$(get_public_ip)
    echo -e "${GREEN}✅ qBittorrent 已启动${RESET}"
    echo -e "${YELLOW}🌐 本机访问地址:  http://${SERVER_IP}:$WEB_PORT${RESET}"
    echo -e "${GREEN}🌐 账号/密码:查看日志${RESET}"
    echo -e "${GREEN}📂 配置目录: $COMPOSE_DIR/config${RESET}"
    echo -e "${GREEN}📂 下载目录: $COMPOSE_DIR/downloads${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$COMPOSE_DIR" || exit
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ qBittorrent 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function restart_app() {
    cd "$COMPOSE_DIR" || exit
    docker compose restart
    echo -e "${GREEN}✅ qBittorrent 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$COMPOSE_DIR" || exit
    docker compose down -v
    rm -rf "$COMPOSE_DIR"
    echo -e "${GREEN}✅ qBittorrent 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f qbittorrent
    read -p "按回车返回菜单..."
    menu
}

menu
