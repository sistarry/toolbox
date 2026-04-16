#!/bin/bash
# ========================================
# Mihomo (Clash Meta) 彻底卸载脚本
# 支持 apt / yum / 手动安装 / Docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}   Mihomo彻底卸载开始${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停服务 + 杀进程
# =============================
echo -e "${YELLOW}[1/6] 停止 Mihomo/Clash 服务...${RESET}"

systemctl stop mihomo 2>/dev/null
systemctl disable mihomo 2>/dev/null

systemctl stop clash 2>/dev/null
systemctl disable clash 2>/dev/null

pkill -9 mihomo 2>/dev/null
pkill -9 clash 2>/dev/null

# =============================
# 2. apt / yum 卸载
# =============================
echo -e "${YELLOW}[2/6] 检测包管理安装...${RESET}"

if command -v apt &>/dev/null; then
    if dpkg -l 2>/dev/null | grep -qi mihomo; then
        echo -e "${YELLOW}检测到 apt 安装 Mihomo${RESET}"
        apt purge -y mihomo
        apt purge -y clash-meta 2>/dev/null
        apt autoremove -y
    fi
elif command -v yum &>/dev/null; then
    if rpm -qa | grep -qi mihomo; then
        echo -e "${YELLOW}检测到 yum 安装 Mihomo${RESET}"
        yum remove -y mihomo
    fi
fi

# =============================
# 3. 删除二进制文件
# =============================
echo -e "${YELLOW}[3/6] 清理可执行文件...${RESET}"

rm -f /usr/local/bin/mihomo
rm -f /usr/bin/mihomo
rm -f /usr/local/bin/clash
rm -f /usr/bin/clash

# =============================
# 4. 清理配置 & 数据
# =============================
echo -e "${YELLOW}[4/6] 清理配置与日志...${RESET}"

rm -rf /etc/mihomo
rm -rf /etc/clash
rm -rf /usr/local/etc/mihomo
rm -rf /usr/local/etc/clash
rm -rf /var/log/mihomo
rm -rf /var/log/clash
rm -rf /opt/mihomo

# =============================
# 5. systemd 服务清理
# =============================
echo -e "${YELLOW}[5/6] 清理 systemd 服务...${RESET}"

rm -f /etc/systemd/system/mihomo.service
rm -f /etc/systemd/system/clash.service
rm -f /etc/systemd/system/clash-meta.service

systemctl daemon-reload

# =============================
# 6. Docker + 网络残留
# =============================
echo -e "${YELLOW}[6/6] 清理 Docker 与残留...${RESET}"

if command -v docker &>/dev/null; then
    docker ps -a --format "{{.Names}}" | grep -Ei 'mihomo|clash|meta' | xargs -r docker rm -f
fi

# 检查 TUN / 虚拟网卡
ip link show 2>/dev/null | grep -Ei 'mihomo|clash' && {
    echo -e "${YELLOW}检测到虚拟网卡残留（可能需要手动清理）${RESET}"
}

# =============================
# 最终检查
# =============================
echo -e "${YELLOW}检查残留进程/端口...${RESET}"

ps -ef | grep -Ei 'mihomo|clash' | grep -v grep

ports=$(ss -tulnp 2>/dev/null | grep -Ei 'mihomo|clash')

if [[ -n "$ports" ]]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无端口残留${RESET}"
fi

# =============================
# 完成
# =============================
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}   Mihomo 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"