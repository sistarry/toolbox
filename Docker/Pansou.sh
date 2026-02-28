#!/bin/bash
# ========================================
# Pansou-Web 一键管理脚本
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="pansou"
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

check_port() {
    if ss -tlnp | grep -q ":$1 "; then
        echo -e "${RED}端口 $1 已被占用，请更换端口！${RESET}"
        return 1
    fi
}

menu() {
    while true; do
        clear
        echo -e "${GREEN}=== Pansou 管理菜单 ===${RESET}"
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
    mkdir -p "$APP_DIR"

    if [ -f "$COMPOSE_FILE" ]; then
        echo -e "${YELLOW}检测到已安装，是否覆盖安装？(y/n)${RESET}"
        read confirm
        [[ "$confirm" != "y" ]] && return
    fi

    read -p "请输入访问端口 [默认:805]: " input_port
    PORT=${input_port:-805}
    check_port "$PORT" || return

    echo
    read -p "是否启用认证功能？(y/n 默认n): " enable_auth

    AUTH_ENABLED=false
    AUTH_USERS=""
    AUTH_TOKEN_EXPIRY=24
    AUTH_JWT_SECRET=""

    if [[ "$enable_auth" == "y" ]]; then
        AUTH_ENABLED=true
        read -p "请输入账号密码 (格式admin:MySecretPass123 ，多个用逗号分隔): " AUTH_USERS
        read -p "Token有效期小时 [默认24]: " expiry
        AUTH_TOKEN_EXPIRY=${expiry:-24}
        AUTH_JWT_SECRET=$(openssl rand -hex 32)
    fi

    cat > "$COMPOSE_FILE" <<EOF
services:
  pansou:
    image: ghcr.io/fish2018/pansou-web:latest
    container_name: pansou-app
    labels:
      - "autoheal=true"
    ports:
      - "127.0.0.1:${PORT}:80"
    environment:
      - DOMAIN=localhost
      - PANSOU_PORT=8888
      - PANSOU_HOST=127.0.0.1
      - CACHE_PATH=/app/data/cache
      - LOG_PATH=/app/data/logs
      - HEALTH_CHECK_INTERVAL=30
      - HEALTH_CHECK_TIMEOUT=10
      - HEALTH_CHECK_RETRIES=3
      - AUTH_ENABLED=${AUTH_ENABLED}
      - AUTH_USERS=${AUTH_USERS}
      - AUTH_TOKEN_EXPIRY=${AUTH_TOKEN_EXPIRY}
      - AUTH_JWT_SECRET=${AUTH_JWT_SECRET}
    volumes:
      - pansou-data:/app/data
    restart: unless-stopped

  autoheal:
    image: willfarrell/autoheal:latest
    container_name: pansou-autoheal
    restart: always
    environment:
      - AUTOHEAL_CONTAINER_LABEL=autoheal
      - AUTOHEAL_INTERVAL=30
      - AUTOHEAL_START_PERIOD=60
      - AUTOHEAL_DEFAULT_STOP_TIMEOUT=10
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock

volumes:
  pansou-data:
    driver: local
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo
    echo -e "${GREEN}✅ Pansou-Web 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: http://127.0.0.1:${PORT}${RESET}"
    echo -e "${GREEN}📂 安装目录: $APP_DIR${RESET}"

    if [[ "$AUTH_ENABLED" == "true" ]]; then
        echo -e "${GREEN}🔐 已启用认证功能${RESET}"
        echo -e "${YELLOW}账号信息: ${AUTH_USERS}${RESET}"
    fi

    read -p "按回车返回菜单..."
}

update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; return; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ 更新完成${RESET}"
    read -p "按回车返回菜单..."
}

restart_app() {
    docker restart pansou-app
    echo -e "${GREEN}✅ 已重启${RESET}"
    read -p "按回车返回菜单..."
}

view_logs() {
    echo -e "${YELLOW}按 Ctrl+C 退出日志${RESET}"
    docker logs -f pansou-app
}

check_status() {
    docker ps | grep pansou-app
    read -p "按回车返回菜单..."
}

uninstall_app() {
    cd "$APP_DIR" || return
    docker compose down
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Pansou-Web 已卸载${RESET}"
    read -p "按回车返回菜单..."
}

menu