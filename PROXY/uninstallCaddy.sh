#!/bin/sh
# ========================================
# Caddy 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / apt / yum / apk / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        Caddy 彻底卸载开始执行           ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止 Caddy 服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop caddy >/dev/null 2>&1
    systemctl disable caddy >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    rc-service caddy stop >/dev/null 2>&1
    rc-update del caddy default >/dev/null 2>&1
    rm -f /etc/init.d/caddy
fi

# 1.3 强杀进程兜底
if command -v pkill >/dev/null 2>&1; then
    pkill -9 caddy >/dev/null 2>&1
else
    killall -9 caddy >/dev/null 2>&1
fi

# =============================
# 2. Docker 清理 (增加了安全环境检测)
# =============================
echo -e "${YELLOW}[2/6] 清理 Docker Caddy...${RESET}"

if command -v docker >/dev/null 2>&1; then
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "caddy" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "caddy" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1
    docker volume ls --format '{{.Name}}' | grep -Ei "caddy" | xargs -r docker volume rm >/dev/null 2>&1
    echo -e "${GREEN}Docker 相关残留清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 3. 包管理器卸载 (apt / yum / apk)
# =============================
echo -e "${YELLOW}[3/6] 检测包管理安装...${RESET}"

if command -v apk >/dev/null 2>&1; then
    # Alpine 环境
    apk del caddy >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu 环境
    if dpkg -l 2>/dev/null | grep -qi caddy; then
        apt purge -y caddy
        apt autoremove -y
    fi
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL 环境
    if rpm -qa | grep -qi caddy; then
        yum remove -y caddy
    fi
fi

# =============================
# 4. 删除二进制 & systemd 文件
# =============================
echo -e "${YELLOW}[4/6] 清理系统文件...${RESET}"

rm -f /usr/bin/caddy
rm -f /usr/local/bin/caddy

rm -f /etc/systemd/system/caddy.service
rm -f /lib/systemd/system/caddy.service

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload >/dev/null 2>&1
fi

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
# 6. 检查端口 & 进程 (兼容 BusyBox 工具流)
# =============================
echo -e "${YELLOW}[6/6] 检查残留状态...${RESET}"

if command -v ss >/dev/null 2>&1; then
    ports=$(ss -tuln 2>/dev/null | grep -Ei ":80|:443|caddy")
else
    ports=$(netstat -tuln 2>/dev/null | grep -Ei ":80|:443|caddy")
fi

# 使用标准 POSIX [ -n ] 替代 [[ -n ]]
if [ -n "$ports" ]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无 Caddy 端口残留${RESET}"
fi

echo -e "${YELLOW}检查残留进程...${RESET}"
ps w | grep caddy | grep -v grep

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        Caddy 已彻底卸载完成            ${RESET}"
echo -e "${GREEN}========================================${RESET}"