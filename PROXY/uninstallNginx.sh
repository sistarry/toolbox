#!/bin/sh
# ========================================
# Nginx + Docker Nginx 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / apt / yum / apk / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        Nginx 彻底卸载开始执行           ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止 Nginx 服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    rc-service nginx stop >/dev/null 2>&1
    rc-update del nginx default >/dev/null 2>&1
    rm -f /etc/init.d/nginx
fi

# 1.3 暴力保底杀进程
if command -v pkill >/dev/null 2>&1; then
    pkill -9 nginx >/dev/null 2>&1
else
    killall -9 nginx >/dev/null 2>&1
fi

# =============================
# 2. Docker Nginx 清理
# =============================
echo -e "${YELLOW}[2/6] 清理 Docker Nginx...${RESET}"

if command -v docker >/dev/null 2>&1; then
    nginx_containers=$(docker ps -a --format "{{.Names}}" | grep -Ei "nginx|webserver")

    # 使用标准 POSIX [ -n ] 替代 [[ -n ]]
    if [ -n "$nginx_containers" ]; then
        docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "nginx|webserver" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1
        echo -e "${GREEN}Docker Nginx 容器已删除${RESET}"
    else
        echo -e "${GREEN}无 Nginx Docker 容器${RESET}"
    fi

    # 清理 nginx 镜像（修复了原脚本在 sh 下的 {} 语法错误）
    if docker images --format '{{.Repository}}' | grep -q "nginx"; then
        docker images --format '{{.Repository}} {{.ID}}' | grep "nginx" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1
        echo -e "${GREEN}Docker Nginx 镜像已清理${RESET}"
    fi
fi

# =============================
# 3. 包管理器卸载 (apt / yum / apk)
# =============================
echo -e "${YELLOW}[3/6] 检测包管理安装...${RESET}"

if command -v apk >/dev/null 2>&1; then
    # Alpine 环境
    apk del nginx >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu 环境
    if dpkg -l 2>/dev/null | grep -qi nginx; then
        apt purge -y nginx nginx-common nginx-core
        apt autoremove -y
    fi
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL 环境
    if rpm -qa | grep -qi nginx; then
        yum remove -y nginx
    fi
fi

# =============================
# 4. 删除二进制 & systemd 文件
# =============================
echo -e "${YELLOW}[4/6] 清理系统文件...${RESET}"

rm -f /usr/sbin/nginx
rm -f /usr/bin/nginx
rm -f /usr/local/sbin/nginx

rm -f /etc/systemd/system/nginx.service
rm -f /lib/systemd/system/nginx.service

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload >/dev/null 2>&1
fi

# =============================
# 5. 清理配置 / 日志 / 网站目录
# =============================
echo -e "${YELLOW}[5/6] 清理配置与数据...${RESET}"

rm -rf /etc/nginx
rm -rf /var/log/nginx
rm -rf /var/lib/nginx
rm -rf /usr/share/nginx
rm -rf /var/www/html
rm -rf /opt/nginx

# =============================
# 6. 检查残留端口 (兼容 BusyBox ss / netstat)
# =============================
echo -e "${YELLOW}[6/6] 检查端口占用...${RESET}"

if command -v ss >/dev/null 2>&1; then
    ports=$(ss -tuln 2>/dev/null | grep -Ei ":80|:443|nginx")
else
    ports=$(netstat -tuln 2>/dev/null | grep -Ei ":80|:443|nginx")
fi

if [ -n "$ports" ]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无 Nginx 端口残留${RESET}"
fi

# =============================
# 最终检查 (兼容 BusyBox ps)
# =============================
echo -e "${YELLOW}检查残留进程...${RESET}"

ps w | grep nginx | grep -v grep

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        Nginx 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"