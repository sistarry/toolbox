#!/bin/bash
# ========================================
# AIClient-2 API 一键管理脚本
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="aiclient2api"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}未检测到 Docker，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | bash
    fi
    if ! docker compose version &>/dev/null; then
        echo -e "${RED}未检测到 Docker Compose v2，请升级 Docker${RESET}"
        exit 1
    fi
}

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

menu() {
    while true; do
        clear
        echo -e "${GREEN}=== AIClient-2 API 管理菜单 ===${RESET}"
        echo -e "${GREEN}1) 安装启动${RESET}"
        echo -e "${GREEN}2) 更新${RESET}"
        echo -e "${GREEN}3) 重启${RESET}"
        echo -e "${GREEN}4) 查看日志${RESET}"
        echo -e "${GREEN}5) 查看状态${RESET}"
        echo -e "${GREEN}6) 卸载${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice

        case $choice in
            1) install_app ;;
            2) update_app ;;
            3) restart_app ;;
            4) view_logs ;;
            5) check_status ;;
            6) uninstall_app ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选择${RESET}"; sleep 1 ;;
        esac
    done
}

install_app() {
    check_docker
    mkdir -p "$APP_DIR/configs"

    if [ -f "$COMPOSE_FILE" ]; then
        echo -e "${YELLOW}检测到已安装，是否覆盖安装？(y/n)${RESET}"
        read confirm
        [[ "$confirm" != "y" ]] && return
    fi

    # 只自定义第一个主端口
    read -p "请输入主访问端口 [默认:3180]: " input_port
    MAIN_PORT=${input_port:-3180}

    read -p "请输入 ARGS 参数 (可留空): " ARGS_VALUE

    cat > "$COMPOSE_FILE" <<EOF
services:
  aiclient-api:
    image: justlikemaki/aiclient-2-api:latest
    container_name: aiclient2api
    restart: unless-stopped
    ports:
      - "${MAIN_PORT}:3000"
      - "8085-8087:8085-8087"
      - "1455:1455"
      - "19876-19880:19876-19880"
    volumes:
      - ./configs:/app/configs
    environment:
      - ARGS=${ARGS_VALUE}
    healthcheck:
      test: ["CMD", "node", "healthcheck.js"]
      interval: 30s
      timeout: 3s
      start_period: 5s
      retries: 3
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    
    SERVER_IP=$(get_public_ip)
    echo
    echo -e "${GREEN}✅ AIClient-2 API 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: http://${SERVER_IP}:${MAIN_PORT}${RESET}"
    echo -e "${YELLOW}🌐 密码: admin123 ${RESET}"
    echo -e "${GREEN}📂 安装目录: $APP_DIR${RESET}"
    read -p "按回车返回菜单..."
}

update_app() {
    cd "$APP_DIR" || return
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ AIClient-2 API 更新完成${RESET}"
    read -p "按回车返回菜单..."
}

restart_app() {
    docker restart aiclient2api
    echo -e "${GREEN}✅ AIClient-2 API 已重启${RESET}"
    read -p "按回车返回菜单..."
}

view_logs() {
    echo -e "${YELLOW}按 Ctrl+C 退出日志${RESET}"
    docker logs -f aiclient2api
}

check_status() {
    docker ps | grep aiclient2api
    read -p "按回车返回菜单..."
}

uninstall_app() {
    cd "$APP_DIR" || return
    docker compose down
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ AIClient-2 API 已卸载${RESET}"
    read -p "按回车返回菜单..."
}

menu
