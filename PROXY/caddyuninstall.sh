#!/bin/bash
# ========================================
# Caddy 彻底卸载脚本
# 支持 apt / yum / apk / 手动 / Docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        Caddy 彻底卸载开始执行${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止 systemd 服务
# =============================
echo -e "${YELLOW}[1/6] 停止 Caddy 服务...${RESET}"

systemctl stop caddy 2>/dev/null
systemctl disable caddy 2>/dev/null

pkill -9 caddy 2>/dev/null

# =============================
# 2. Docker 清理
# =============================
echo -e "${YELLOW}[2/6] 清理 Docker Caddy...${RESET}"

if command -v docker &>/dev/null; then
    caddy_containers=$(docker ps -a --format "{{.Names}}" | grep -Ei "caddy")

    if [[ -n "$caddy_containers" ]]; then
        echo "$caddy_containers" | xargs -r docker rm -f
        echo -e "${GREEN}Docker Caddy 容器已删除${RESET}"
    else
        echo -e "${GREEN}无 Caddy Docker 容器${RESET}"
    fi

    # 删除镜像（可选）
    docker images | grep caddy &>/dev/null && {
        docker rmi -f $(docker images | grep caddy | awk '{print $3}') 2>/dev/null
    }
fi

# =============================
# 3. 包管理卸载
# =============================
echo -e "${YELLOW}[3/6] 检测包管理安装...${RESET}"

if command -v apt &>/dev/null && dpkg -l 2>/dev/null | grep -qi caddy; then
    apt purge -y caddy
    apt autoremove -y

elif command -v yum &>/dev/null && rpm -qa | grep -qi caddy; then
    yum remove -y caddy

elif command -v apk &>/dev/null; then
    apk del caddy 2>/dev/null
fi

# =============================
# 4. 删除二进制 & systemd
# =============================
echo -e "${YELLOW}[4/6] 清理系统文件...${RESET}"

rm -f /usr/bin/caddy
rm -f /usr/local/bin/caddy

rm -f /etc/systemd/system/caddy.service
rm -f /lib/systemd/system/caddy.service

systemctl daemon-reload

# =============================
# 5. 清理配置 / 数据
# =============================
echo -e "${YELLOW}[5/6] 清理配置与数据...${RESET}"

rm -rf /etc/caddy
rm -rf /var/lib/caddy
rm -rf /var/log/caddy
rm -rf /usr/share/caddy
rm -rf /opt/caddy

rm -rf ~/.caddy

# =============================
# 6. 检查端口 & 进程
# =============================
echo -e "${YELLOW}[6/6] 检查残留状态...${RESET}"

ports=$(ss -tulnp 2>/dev/null | grep -Ei ":80|:443|caddy")

if [[ -n "$ports" ]]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无 Caddy 端口残留${RESET}"
fi

echo -e "${YELLOW}检查残留进程...${RESET}"
ps -ef | grep caddy | grep -v grep

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        Caddy 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"