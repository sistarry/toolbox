#!/bin/bash
# ========================================
# Cloudflare WARP 彻底卸载脚本（含 Docker）
# 支持 warp u / warp-cli / wgcf / wireguard / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}      Cloudflare WARP 彻底卸载${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. warp u 卸载
# =============================
echo -e "${YELLOW}[1/7] 尝试 warp u 卸载...${RESET}"

if command -v warp &>/dev/null; then
    warp u 2>/dev/null && echo -e "${GREEN}warp u 已执行${RESET}"
fi

# =============================
# 2. warp-cli 清理
# =============================
echo -e "${YELLOW}[2/7] 清理 warp-cli...${RESET}"

if command -v warp-cli &>/dev/null; then
    warp-cli disconnect 2>/dev/null
    warp-cli delete 2>/dev/null
fi

# =============================
# 3. systemd 服务清理
# =============================
echo -e "${YELLOW}[3/7] 停止 WARP 服务...${RESET}"

systemctl stop warp-svc 2>/dev/null
systemctl disable warp-svc 2>/dev/null

systemctl stop wg-quick@wgcf 2>/dev/null
systemctl disable wg-quick@wgcf 2>/dev/null

systemctl stop wgcf 2>/dev/null
systemctl disable wgcf 2>/dev/null

# =============================
# 4. wgcf / wireguard 清理
# =============================
echo -e "${YELLOW}[4/7] 清理 WGCF / WireGuard...${RESET}"

wg-quick down wgcf 2>/dev/null

ip link show 2>/dev/null | grep -E "wgcf|warp" && {
    ip link delete wgcf 2>/dev/null
    ip link delete warp 2>/dev/null
}

# =============================
# 5. 删除程序文件
# =============================
echo -e "${YELLOW}[5/7] 删除程序文件...${RESET}"

rm -f /usr/bin/warp /usr/local/bin/warp
rm -f /usr/bin/warp-cli /usr/local/bin/warp-cli
rm -f /usr/bin/wgcf /usr/local/bin/wgcf

rm -rf /opt/warp /etc/warp
rm -rf /etc/wireguard
rm -rf ~/.warp ~/.wgcf

# =============================
# 6. 包管理卸载
# =============================
echo -e "${YELLOW}[6/7] 检测包管理安装...${RESET}"

if command -v apt &>/dev/null && dpkg -l 2>/dev/null | grep -qi warp; then
    apt purge -y warp-cli cloudflare-warp
    apt autoremove -y
elif command -v yum &>/dev/null && rpm -qa | grep -qi warp; then
    yum remove -y cloudflare-warp
fi

# =============================
# 7. Docker 清理（新增）
# =============================
echo -e "${YELLOW}[7/7] 清理 Docker WARP 相关残留...${RESET}"

if command -v docker &>/dev/null; then

    # 1️⃣ 容器
    echo -e "${YELLOW}检查 WARP 相关容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $1}' | xargs -r docker stop 2>/dev/null
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $1}' | xargs -r docker rm -f 2>/dev/null

    # 2️⃣ 镜像
    echo -e "${YELLOW}检查 WARP 相关镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $2}' | xargs -r docker rmi -f 2>/dev/null

    # 3️⃣ volume
    echo -e "${YELLOW}检查 WARP 相关数据卷...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "warp|wgcf|cloudflare" | xargs -r docker volume rm 2>/dev/null

    echo -e "${GREEN}Docker WARP 清理完成${RESET}"

else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 最终检测
# =============================
echo -e "${YELLOW}检查残留状态...${RESET}"

warp_status=$(ps -ef | grep -Ei "warp|wgcf" | grep -v grep)

if [[ -n "$warp_status" ]]; then
    echo -e "${RED}仍有进程残留:${RESET}"
    echo "$warp_status"
else
    echo -e "${GREEN}无进程残留${RESET}"
fi

ip a | grep -Ei "warp|wgcf" && echo -e "${YELLOW}⚠️ 仍有虚拟网卡${RESET}"

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}      WARP 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"
