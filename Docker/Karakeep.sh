#!/bin/bash
# ========================================
# Karakeep 一键管理脚本
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="karakeep-app"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"
ENV_FILE="$APP_DIR/.env"

# 检查 Docker & Docker Compose
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

# 检查端口占用
check_port() {
    if ss -tlnp | grep -q ":$1 "; then
        echo -e "${RED}端口 $1 已被占用，请更换端口！${RESET}"
        return 1
    fi
}

# 生成自定义 .env 文件
generate_env() {
    read -p "输入 Karakeep 版本 [默认: release]: " input_version
    KARAKEEP_VERSION=${input_version:-release}

    read -p "输入 NEXTAUTH_SECRET [默认自动生成]: " input_nextauth
    NEXTAUTH_SECRET=${input_nextauth:-$(openssl rand -base64 36)}

    read -p "输入 MEILI_MASTER_KEY [默认自动生成]: " input_meili
    MEILI_MASTER_KEY=${input_meili:-$(openssl rand -base64 36)}

    read -p "输入 NEXTAUTH_URL [默认: http://127.0.0.1:$PORT]: " input_url
    NEXTAUTH_URL=${input_url:-http://127.0.0.1:$PORT}

    cat > "$ENV_FILE" <<EOF
KARAKEEP_VERSION=$KARAKEEP_VERSION
NEXTAUTH_SECRET=$NEXTAUTH_SECRET
MEILI_MASTER_KEY=$MEILI_MASTER_KEY
NEXTAUTH_URL=$NEXTAUTH_URL
EOF

    echo -e "${GREEN}✅ .env 文件已生成${RESET}"
}

# 菜单主函数
menu() {
    while true; do
        clear
        echo -e "${GREEN}=== Karakeep 管理菜单 ===${RESET}"
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

# 安装/启动
install_app() {
    check_docker
    mkdir -p "$APP_DIR"

    if [ -f "$COMPOSE_FILE" ]; then
        echo -e "${YELLOW}检测到已安装，是否覆盖安装？(y/n)${RESET}"
        read confirm
        [[ "$confirm" != "y" ]] && return
    fi

    read -p "请输入访问端口 [默认:3030]: " input_port
    PORT=${input_port:-3030}
    check_port "$PORT" || return

    # 生成 .env 文件（可自定义）
    generate_env

    # 动态生成 docker-compose.yml
    cat > "$COMPOSE_FILE" <<EOF
services:
  web:
    image: ghcr.io/karakeep-app/karakeep:latest
    restart: unless-stopped
    volumes:
      - ./data:/data
    ports:
      - "127.0.0.1:${PORT}:3000"
    env_file:
      - .env
    environment:
      MEILI_ADDR: http://meilisearch:7700
      BROWSER_WEB_URL: http://chrome:9222
      DATA_DIR: /data
  chrome:
    image: gcr.io/zenika-hub/alpine-chrome:124
    restart: unless-stopped
    command:
      - --no-sandbox
      - --disable-gpu
      - --disable-dev-shm-usage
      - --remote-debugging-address=0.0.0.0
      - --remote-debugging-port=9222
      - --hide-scrollbars
  meilisearch:
    image: getmeili/meilisearch:v1.13.3
    restart: unless-stopped
    env_file:
      - .env
    environment:
      MEILI_NO_ANALYTICS: "true"
    volumes:
      - ./meilisearch:/meili_data
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo
    echo -e "${GREEN}✅ Karakeep 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: ${NEXTAUTH_URL}${RESET}"
    echo -e "${GREEN}✅ NEXTAUTH_SECRET: $NEXTAUTH_SECRET${RESET}"
    echo -e "${GREEN}✅ MEILI_MASTER_KEY:$MEILI_MASTER_KEY${RESET}"
    echo -e "${GREEN}📂 安装目录: $APP_DIR${RESET}"
    read -p "按回车返回菜单..."
}  


# 更新
update_app() {
    cd "$APP_DIR" || return
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ Karakeep 更新完成${RESET}"
    read -p "按回车返回菜单..."
}

# 重启
restart_app() {
    cd "$APP_DIR" || return
    docker compose restart
    echo -e "${GREEN}✅ Karakeep 已重启${RESET}"
    read -p "按回车返回菜单..."
}

# 查看日志
view_logs() {
    cd "$APP_DIR" || return
    echo -e "${YELLOW}按 Ctrl+C 退出日志${RESET}"
    docker compose logs -f
}

# 查看状态
check_status() {
    cd "$APP_DIR" || return
    docker compose ps
    read -p "按回车返回菜单..."
}

# 卸载
uninstall_app() {
    cd "$APP_DIR" || return
    docker compose down
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ Karakeep 已卸载${RESET}"
    read -p "按回车返回菜单..."
}

menu