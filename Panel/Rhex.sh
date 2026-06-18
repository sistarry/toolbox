#!/bin/bash
# ========================================
# Rhex 一键管理脚本
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

APP_NAME="Rhex"
APP_DIR="/opt/$APP_NAME"

generate_secret() {

    openssl rand -hex 32
}

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

get_public_ip() {
    local mode=${1:-"auto"} # auto: 自动, v4: 强制IPv4, v6: 强制IPv6
    local ip=""
    
    if [[ "$mode" == "v4" ]]; then
        # 强制获取 IPv4
        for url in "https://api.ipify.org" "https://4.ip.sb" "https://checkip.amazonaws.com"; do
            ip=$(wget -qO- --timeout=3 --tries=1 -4 --no-check-certificate "$url" 2>/dev/null) && [[ -n "$ip" && "$ip" != *":"* ]] && echo "$ip" && return 0
        done
    elif [[ "$mode" == "v6" ]]; then
        # 强制获取 IPv6
        for url in "https://api64.ipify.org" "https://6.ip.sb"; do
            ip=$(wget -qO- --timeout=3 --tries=1 -6 --no-check-certificate "$url" 2>/dev/null) && [[ -n "$ip" && "$ip" == *":"* ]] && echo "$ip" && return 0
        done
    else
        # auto 模式：双栈环境优先获取 IPv4 (更适合大众网络)，纯 v6 环境自动fallback到 v6
        for url in "https://api.ipify.org" "https://4.ip.sb"; do
            ip=$(wget -qO- --timeout=3 --tries=1 -4 --no-check-certificate "$url" 2>/dev/null) && [[ -n "$ip" ]] && echo "$ip" && return 0
        done
        # 如果获取 v4 失败，说明可能是纯 v6 机器，尝试获取 v6
        for url in "https://api64.ipify.org" "https://6.ip.sb"; do
            ip=$(wget -qO- --timeout=3 --tries=1 --no-check-certificate "$url" 2>/dev/null) && [[ -n "$ip" ]] && echo "$ip" && return 0
        done
    fi

    # 兜底处理：所有接口都失败时，直接输出 127.0.0.1，不报错
    echo "127.0.0.1" && return 0
}

menu() {

    while true; do

        clear

        echo -e "${GREEN}=========================${RESET}"
        echo -e "${GREEN}   ◈  Rhex 管理菜单  ◈   ${RESET}"
        echo -e "${GREEN}=========================${RESET}"
        echo -e "${GREEN}1) 安装启动${RESET}"
        echo -e "${GREEN}2) 更新${RESET}"
        echo -e "${GREEN}3) 重启${RESET}"
        echo -e "${GREEN}4) 查看日志${RESET}"
        echo -e "${GREEN}5) 查看状态${RESET}"
        echo -e "${GREEN}6) 卸载(含数据)${RESET}"
        echo -e "${GREEN}0) 退出${RESET}"
        echo -e "${GREEN}=========================${RESET}"

        read -p "$(echo -e ${GREEN}请选择:${RESET}) " choice

        case $choice in
            1) install_app ;;
            2) update_app ;;
            3) restart_app ;;
            4) view_logs ;;
            5) check_status ;;
            6) uninstall_app ;;
            0) exit 0 ;;
            *) echo -e "${RED}无效选择${RESET}" ; sleep 1 ;;
        esac
    done
}

install_app() {

    check_docker

    if [ -d "$APP_DIR" ]; then
        echo -e "${YELLOW}检测到已安装，是否覆盖安装？(y/n)${RESET}"
        read confirm
        [[ "$confirm" != "y" ]] && return

        rm -rf "$APP_DIR"
    fi


    echo
    read -p "管理员用户名 [默认:admin]: " input_admin_user
    ADMIN_USER=${input_admin_user:-admin}

    read -p "管理员密码 [默认:ChangeMe_123456]: " input_admin_pass
    ADMIN_PASS=${input_admin_pass:-ChangeMe_123456}

    read -p "管理员邮箱 [默认:admin@rhex.im]: " input_admin_email
    ADMIN_EMAIL=${input_admin_email:-admin@rhex.im}

    read -p "管理员昵称 [默认:秦始皇]: " input_admin_nick
    ADMIN_NICK=${input_admin_nick:-秦始皇}

    SESSION_SECRET=$(generate_secret)
    CAPTCHA_SECRET_KEY=$(generate_secret)

    cd /opt || exit

    git clone https://github.com/lovedevpanda/Rhex.git

    cd "$APP_DIR" || exit

    cp .env.example .env

    sed -i "s#^DATABASE_URL=.*#DATABASE_URL=\"postgresql://postgres:postgres@postgres:5432/bbs?schema=public\"#g" .env

    sed -i "s#^REDIS_URL=.*#REDIS_URL=\"redis://redis:6379\"#g" .env

    sed -i "s#^SESSION_SECRET=.*#SESSION_SECRET=\"${SESSION_SECRET}\"#g" .env

    sed -i "s#^CAPTCHA_SECRET_KEY=.*#CAPTCHA_SECRET_KEY=\"${CAPTCHA_SECRET_KEY}\"#g" .env

    sed -i "s#^SEED_ADMIN_USERNAME=.*#SEED_ADMIN_USERNAME=\"${ADMIN_USER}\"#g" .env

    sed -i "s#^SEED_ADMIN_PASSWORD=.*#SEED_ADMIN_PASSWORD=\"${ADMIN_PASS}\"#g" .env

    sed -i "s#^SEED_ADMIN_EMAIL=.*#SEED_ADMIN_EMAIL=\"${ADMIN_EMAIL}\"#g" .env

    sed -i "s#^SEED_ADMIN_NICKNAME=.*#SEED_ADMIN_NICKNAME=\"${ADMIN_NICK}\"#g" .env

    sed -i "s#^TZ=.*#TZ=\"Asia/Shanghai\"#g" .env


    docker compose up -d

    SERVER_IP=$(get_public_ip)

    echo
    echo -e "${GREEN}✅ Rhex 已启动${RESET}"
    echo -e "${YELLOW}🌐 访问地址: http://${SERVER_IP}:3000${RESET}"
    echo -e "${YELLOW}👤 管理员: ${ADMIN_USER}${RESET}"
    echo -e "${YELLOW}🔑 管理密码: ${ADMIN_PASS}${RESET}"
    echo -e "${YELLOW}📧 管理邮箱: ${ADMIN_EMAIL}${RESET}"
    echo -e "${YELLOW}📂 安装目录: $APP_DIR${RESET}"

    read -p "按回车返回菜单..."
}

update_app() {

    cd "$APP_DIR" || return

    git pull

    docker compose pull

    docker compose up -d

    echo -e "${GREEN}✅ 更新完成${RESET}"

    read -p "按回车返回菜单..."
}

restart_app() {

    cd "$APP_DIR" || return

    docker compose restart

    echo -e "${GREEN}✅ 已重启${RESET}"

    read -p "按回车返回菜单..."
}

view_logs() {

    cd "$APP_DIR" || return

    docker compose logs -f
}

check_status() {

    cd "$APP_DIR" || return

    docker compose ps

    read -p "按回车返回菜单..."
}

uninstall_app() {

    cd "$APP_DIR" || return

    docker compose down -v

    rm -rf "$APP_DIR"

    echo -e "${RED}✅ 已彻底卸载${RESET}"

    read -p "按回车返回菜单..."
}

menu
