#!/bin/sh
# ========================================
# acme.sh 彻底卸载脚本（全平台通用版，含 Alpine & Docker）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux 
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}       ACME(acme.sh) 彻底卸载           ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 执行官方卸载（如果存在）
# =============================
echo -e "${YELLOW}[1/6] 尝试官方卸载...${RESET}"

if command -v acme.sh >/dev/null 2>&1; then
    acme.sh --uninstall >/dev/null 2>&1
fi

# =============================
# 2. 删除 acme 主目录
# =============================
echo -e "${YELLOW}[2/6] 删除 acme.sh 目录...${RESET}"

rm -rf ~/.acme.sh
rm -rf /root/.acme.sh
rm -rf /home/*/.acme.sh >/dev/null 2>&1

# =============================
# 3. 清理证书残留
# =============================
echo -e "${YELLOW}[3/6] 清理证书目录...${RESET}"

rm -rf /etc/ssl/acme
rm -rf /etc/acme.sh
rm -rf /var/lib/acme.sh
rm -rf /usr/local/acme.sh

# 常见证书目录
rm -rf /etc/letsencrypt
rm -rf /usr/local/etc/letsencrypt

# =============================
# 4. 清理 cron 定时任务（安全适配 Alpine）
# =============================
echo -e "${YELLOW}[4/6] 清理定时任务...${RESET}"

# 仅通过管道过滤，不再暴力删除 /var/spool/cron/root，确保其他任务安全
if command -v crontab >/dev/null 2>&1; then
    crontab -l 2>/dev/null | grep -v "acme.sh" | crontab - >/dev/null 2>&1
fi

# =============================
# 5. 删除残留命令 & 环境变量（兼容 BusyBox）
# =============================
echo -e "${YELLOW}[5/6] 清理环境残留...${RESET}"

rm -f /usr/local/bin/acme.sh
rm -f /usr/bin/acme.sh

# 使用 grep -v 代替 sed -i，完美兼容 Alpine BusyBox，避免损坏环境文件
for file in ~/.bashrc ~/.profile ~/.ashrc /etc/profile; do
    if [ -f "$file" ]; then
        grep -v "acme.sh" "$file" > "${file}.tmp" 2>/dev/null && mv "${file}.tmp" "$file"
    fi
done

# =============================
# 6. Docker 相关清理
# =============================
echo -e "${YELLOW}[6/6] 清理 Docker 相关残留...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查 acme 相关容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -i acme | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -i acme | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 acme 相关镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -i acme | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 acme 相关数据卷...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -i acme | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 最终检查
# =============================
echo -e "${YELLOW}检查残留...${RESET}"

if command -v acme.sh >/dev/null 2>&1; then
    echo -e "${RED}仍然存在 acme.sh 命令${RESET}"
else
    echo -e "${GREEN}acme.sh 已移除${RESET}"
fi

if ls /etc 2>/dev/null | grep -qi letsencrypt; then
    echo -e "${YELLOW}⚠️ 检测到 letsencrypt 残留${RESET}"
else
    echo -e "${GREEN}无证书残留目录${RESET}"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        ACME 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"