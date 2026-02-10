#!/bin/bash
# ========================================
# epic-awesome-gamer 一键管理脚本 (Docker Compose)
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="epic-awesome-gamer"
CONTAINER_NAME="epic-awesome-gamer"
APP_DIR="/opt/$APP_NAME"
COMPOSE_FILE="$APP_DIR/docker-compose.yml"

check_env() {
    command -v docker >/dev/null 2>&1 || {
        echo -e "${RED}❌ 未检测到 Docker${RESET}"
        exit 1
    }

    docker compose version >/dev/null 2>&1 || {
        echo -e "${RED}❌ Docker Compose 不可用${RESET}"
        exit 1
    }
}

menu() {
    clear
    echo -e "${GREEN}=== Epic-awesome-gamer 管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 安装启动${RESET}"
    echo -e "${GREEN}2) 更新${RESET}"
    echo -e "${GREEN}3) 重启${RESET}"
    echo -e "${GREEN}4) 查看日志${RESET}"
    echo -e "${GREEN}5) 卸载(含数据)${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice

    case $choice in
        1) install_app ;;
        2) update_app ;;
        3) restart_app ;;
        4) view_logs ;;
        5) uninstall_app ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${RESET}"; sleep 1; menu ;;
    esac
}

install_app() {
    if [ -f "$COMPOSE_FILE" ]; then
        read -p "已存在安装，是否覆盖重装？(y/N): " confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && menu
    fi

    mkdir -p "$APP_DIR/volumes"

    # 读取时区
    read -p "请输入时区 [默认:Asia/Shanghai]: " input_tz
    TZ=${input_tz:-Asia/Shanghai}

    # 账号配置
    read -p "请输入 EPIC_EMAIL: " EPIC_EMAIL
    read -p "请输入 EPIC_PASSWORD: " EPIC_PASSWORD
    read -p "请输入 GEMINI_API_KEY: " GEMINI_API_KEY

    cat > "$COMPOSE_FILE" <<EOF
services:
  epic-awesome-gamer:
    image: ghcr.io/10000ge10000/epic-awesome-gamer:latest
    container_name: ${CONTAINER_NAME}
    restart: always
    environment:
      - TZ=${TZ}
      - EPIC_EMAIL=${EPIC_EMAIL}
      - EPIC_PASSWORD=${EPIC_PASSWORD}
      - GEMINI_API_KEY=${GEMINI_API_KEY}
      - GEMINI_BASE_URL=https://aihubmix.com
      - GEMINI_MODEL=gemini-2.5-pro
      - ENABLE_APSCHEDULER=true
      - DISABLE_BEZIER_TRAJECTORY=true
      - EXECUTION_TIMEOUT=120
      - RESPONSE_TIMEOUT=30
      - RETRY_ON_FAILURE=true
      - WAIT_FOR_CHALLENGE_VIEW_TO_RENDER_MS=1500
      - CONSTRAINT_RESPONSE_SCHEMA=true
      - CHALLENGE_CLASSIFIER_MODEL=gemini-2.5-flash
      - IMAGE_CLASSIFIER_MODEL=gemini-2.5-pro
      - SPATIAL_POINT_REASONER_MODEL=gemini-2.5-pro
      - SPATIAL_PATH_REASONER_MODEL=gemini-2.5-pro
      - IMAGE_CLASSIFIER_THINKING_BUDGET=970
      - SPATIAL_POINT_THINKING_BUDGET=1387
      - SPATIAL_PATH_THINKING_BUDGET=1652
    volumes:
      - ./volumes/:/app/app/volumes/
    entrypoint: [ "/usr/bin/tini", "--" ]
    command: xvfb-run --auto-servernum --server-num=1 --server-args='-screen 0, 1920x1080x24' uv run app/deploy.py
    mem_limit: 4g
    shm_size: '2gb'
EOF

    cd "$APP_DIR" || exit
    docker compose up -d

    echo -e "${GREEN}✅ epic-awesome-gamer 已启动${RESET}"
    echo -e "${GREEN}📂 数据目录: $APP_DIR/volumes${RESET}"
    read -p "按回车返回菜单..."
    menu
}

update_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录${RESET}"; sleep 1; menu; }
    docker compose pull
    docker compose up -d
    echo -e "${GREEN}✅ epic-awesome-gamer 已更新完成${RESET}"
    read -p "按回车返回菜单..."
    menu
}

restart_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录${RESET}"; sleep 1; menu; }
    docker compose restart
    echo -e "${GREEN}✅ epic-awesome-gamer 已重启${RESET}"
    read -p "按回车返回菜单..."
    menu
}

view_logs() {
    echo -e "${YELLOW}📄 正在查看日志，Ctrl+C 返回菜单${RESET}"
    docker logs -f ${CONTAINER_NAME}
    menu
}

uninstall_app() {
    cd "$APP_DIR" || { echo -e "${RED}未检测到安装目录${RESET}"; sleep 1; menu; }
    docker compose down
    rm -rf "$APP_DIR"
    echo -e "${RED}✅ epic-awesome-gamer 已卸载（含数据）${RESET}"
    read -p "按回车返回菜单..."
    menu
}

check_env
menu
