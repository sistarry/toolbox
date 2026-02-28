#!/bin/bash
# ========================================
# MyTube 一键管理脚本
# 适用: Debian 12 VPS (bridge 网络)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="mytube"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

check_docker() {
    if ! command -v docker &>/dev/null; then
        echo -e "${YELLOW}未检测到 Docker，正在安装...${RESET}"
        curl -fsSL https://get.docker.com | bash
        systemctl enable docker
        systemctl start docker
    fi

    if ! docker compose version &>/dev/null; then
        echo -e "${YELLOW}正在安装 Docker Compose 插件...${RESET}"
        apt update
        apt install -y docker-compose-plugin
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
        echo -e "${GREEN}=== MyTube 管理菜单 ===${RESET}"
        echo -e "${GREEN}1) 安装启动${RESET}"
        echo -e "${GREEN}2) 更新${RESET}"
        echo -e "${GREEN}3) 重启${RESET}"
        echo -e "${GREEN}4) 查看日志${RESET}"
        echo -e "${GREEN}5) 查看状态${RESET}"
        echo -e "${GREEN}6) 卸载(含数据)${RESET}"
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
    mkdir -p "$APP_DIR/uploads"
    mkdir -p "$APP_DIR/data"

    if [ -f "$COMPOSE_FILE" ]; then
        echo -e "${YELLOW}检测到已安装，是否覆盖安装？(y/n)${RESET}"
        read confirm
        [[ "$confirm" != "y" ]] && return
    fi

    read -p "请输入前端访问端口 [默认:5556]: " input_port
    PORT=${input_port:-5556}
    check_port "$PORT" || return

    check_port 5551 || return

    cat > "$COMPOSE_FILE" <<EOF
services:
  backend:
    image: franklioxygen/mytube:backend-latest
    container_name: mytube-backend
    restart: unless-stopped
    ports:
      - "5551:5551"
    networks:
      - mytube-network
    environment:
      - PORT=5551
    volumes:
      - ./uploads:/app/uploads
      - ./data:/app/data

  frontend:
    image: franklioxygen/mytube:frontend-latest
    container_name: mytube-frontend
    restart: unless-stopped
    ports:
      - "127.0.0.1:${PORT}:5556"
    depends_on:
      - backend
    networks:
      - mytube-network
    environment:
      - VITE_API_URL=/api
      - VITE_BACKEND_URL=

networks:
  mytube-network:
    driver: bridge
EOF

    cd "$APP_DIR" || exit
    docker compose pull
    docker compose up -d

    SERVER_IP=$(curl -s ifconfig.me)

    echo
    echo -e "${GREEN}✅ MyTube 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: http://127.0.0.1:${PORT}${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/data${RESET}"
    echo -e "${GREEN}📂 上传目录: $APP_DIR/uploads${RESET}"
    read -p "按回车返回菜单..."
}

update_app() {
    cd "$APP_DIR" || { echo "未检测到安装目录"; sleep 1; return; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ MyTube 更新完成${RESET}"
    read -p "按回车返回菜单..."
}

restart_app() {
    docker restart mytube-backend
    docker restart mytube-frontend
    echo -e "${GREEN}✅ MyTube 已重启${RESET}"
    read -p "按回车返回菜单..."
}

view_logs() {
    echo -e "${YELLOW}按 Ctrl+C 退出日志${RESET}"
    docker compose -f "$COMPOSE_FILE" logs -f
}

check_status() {
    docker ps | grep mytube
    read -p "按回车返回菜单..."
}

uninstall_app() {
    cd "$APP_DIR" || return
    docker compose down -v
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ MyTube 已彻底卸载（含数据）${RESET}"
    read -p "按回车返回菜单..."
}

menu