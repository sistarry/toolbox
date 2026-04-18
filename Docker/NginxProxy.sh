#!/bin/bash
# ========================================
# Nginx Proxy Manager 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
RESET="\033[0m"
YELLOW="\033[33m"
RED="\033[31m"
APP_NAME="nginx"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
CONFIG_FILE="$APP_DIR/config.env"


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

# 获取公网 IP
SERVER_IP=$(get_public_ip)

function menu() {
    clear
    echo -e "${GREEN}=== Nginx Proxy Manager 管理菜单 ===${RESET}"
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
    # 自定义管理端口，默认 81
    read -p "请输入 管理端口 [默认:81]: " input_admin
    ADMIN_PORT=${input_admin:-81}

    # 创建统一文件夹
    mkdir -p "$APP_DIR/data" "$APP_DIR/letsencrypt"

    # 生成 docker-compose.yml
    cat > "$COMPOSE_FILE" <<EOF
services:
  nginx:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx
    restart: unless-stopped
    ports:
      - '80:80'       # HTTP 固定
      - '${ADMIN_PORT}:81'  # 管理端口可自定义
      - '443:443'     # HTTPS 固定
    volumes:
      - $APP_DIR/data:/data
      - $APP_DIR/letsencrypt:/etc/letsencrypt
EOF

    # 保存配置
    echo "ADMIN_PORT=$ADMIN_PORT" > "$CONFIG_FILE"

    # 启动容器
    cd "$APP_DIR"
    docker compose up -d

    echo -e "${GREEN}✅ Nginx Proxy Manager 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: http://${SERVER_IP}:$ADMIN_PORT${RESET}"
    echo -e "${GREEN}   初始用户名: admin@example.com${RESET}"
    echo -e "${GREEN}   初始密码: changeme${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    echo -e "${GREEN}🔐 Let's Encrypt 目录: $APP_DIR/letsencrypt${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录，请先安装"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Nginx Proxy Manager 已更新并重启完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function uninstall_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${GREEN}✅ Nginx Proxy Manager 已卸载，数据已删除${RESET}"
    read -p "按回车返回菜单..."
    menu
}

function view_logs() {
    docker logs -f nginx
    read -p "按回车返回菜单..."
    menu
}

function restart_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ Nginx Proxy Manager 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

menu
