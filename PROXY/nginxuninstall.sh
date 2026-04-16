#!/bin/bash
# ========================================
# Nginx + Docker Nginx 彻底卸载脚本
# 支持 apt / yum / apk / 手动 / Docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        Nginx 彻底卸载开始执行${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止 systemd Nginx
# =============================
echo -e "${YELLOW}[1/6] 停止 Nginx 服务...${RESET}"

systemctl stop nginx 2>/dev/null
systemctl disable nginx 2>/dev/null

pkill -9 nginx 2>/dev/null

# =============================
# 2. Docker Nginx 清理
# =============================
echo -e "${YELLOW}[2/6] 清理 Docker Nginx...${RESET}"

if command -v docker &>/dev/null; then
    nginx_containers=$(docker ps -a --format "{{.Names}}" | grep -Ei "nginx|webserver")

    if [[ -n "$nginx_containers" ]]; then
        echo "$nginx_containers" | xargs -r docker rm -f
        echo -e "${GREEN}Docker Nginx 容器已删除${RESET}"
    else
        echo -e "${GREEN}无 Nginx Docker 容器${RESET}"
    fi

    # 可选：删除 nginx 镜像（更彻底）
    docker images | grep nginx &>/dev/null && {
        docker rmi -f $(docker images | grep nginx | awk '{print $3}') 2>/dev/null
    }
fi

# =============================
# 3. apt / yum / apk 卸载
# =============================
echo -e "${YELLOW}[3/6] 检测包管理安装...${RESET}"

if command -v apt &>/dev/null; then
    if dpkg -l 2>/dev/null | grep -qi nginx; then
        apt purge -y nginx nginx-common nginx-core
        apt autoremove -y
    fi

elif command -v yum &>/dev/null; then
    if rpm -qa | grep -qi nginx; then
        yum remove -y nginx
    fi

elif command -v apk &>/dev/null; then
    apk del nginx 2>/dev/null
fi

# =============================
# 4. 删除二进制 & systemd
# =============================
echo -e "${YELLOW}[4/6] 清理系统文件...${RESET}"

rm -f /usr/sbin/nginx
rm -f /usr/bin/nginx
rm -f /usr/local/sbin/nginx

rm -f /etc/systemd/system/nginx.service
rm -f /lib/systemd/system/nginx.service

systemctl daemon-reload

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
# 6. 检查残留端口
# =============================
echo -e "${YELLOW}[6/6] 检查端口占用...${RESET}"

ports=$(ss -tulnp 2>/dev/null | grep -Ei ":80|:443|nginx")

if [[ -n "$ports" ]]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无 Nginx 端口残留${RESET}"
fi

# =============================
# 最终检查
# =============================
echo -e "${YELLOW}检查残留进程...${RESET}"

ps -ef | grep nginx | grep -v grep

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        Nginx 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"