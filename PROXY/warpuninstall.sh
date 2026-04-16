#!/bin/bash
# ========================================
# Cloudflare WARP 彻底卸载脚本
# 支持 warp u / warp-cli / wgcf / wireguard / 脚本安装
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}      Cloudflare WARP 彻底卸载${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 优先使用 warp u 卸载
# =============================
echo -e "${YELLOW}[1/6] 尝试 warp u 卸载...${RESET}"

if command -v warp &>/dev/null; then
    warp u 2>/dev/null && echo -e "${GREEN}warp u 已执行${RESET}"
fi

# =============================
# 2. warp-cli 卸载
# =============================
echo -e "${YELLOW}[2/6] 清理 warp-cli...${RESET}"

if command -v warp-cli &>/dev/null; then
    warp-cli disconnect 2>/dev/null
    warp-cli delete 2>/dev/null
fi

# =============================
# 3. systemd 服务清理
# =============================
echo -e "${YELLOW}[3/6] 停止 WARP 服务...${RESET}"

systemctl stop warp-svc 2>/dev/null
systemctl disable warp-svc 2>/dev/null

systemctl stop wg-quick@wgcf 2>/dev/null
systemctl disable wg-quick@wgcf 2>/dev/null

systemctl stop wgcf 2>/dev/null
systemctl disable wgcf 2>/dev/null

# =============================
# 4. wgcf / wireguard 清理
# =============================
echo -e "${YELLOW}[4/6] 清理 WGCF / WireGuard...${RESET}"

wg-quick down wgcf 2>/dev/null

ip link show 2>/dev/null | grep -E "wgcf|warp" && {
    ip link delete wgcf 2>/dev/null
    ip link delete warp 2>/dev/null
}

# =============================
# 5. 删除二进制与脚本
# =============================
echo -e "${YELLOW}[5/6] 删除程序文件...${RESET}"

rm -f /usr/bin/warp
rm -f /usr/local/bin/warp
rm -f /usr/bin/warp-cli
rm -f /usr/local/bin/warp-cli
rm -f /usr/bin/wgcf
rm -f /usr/local/bin/wgcf

rm -rf /opt/warp
rm -rf /etc/warp
rm -rf /etc/wireguard
rm -rf ~/.warp
rm -rf ~/.wgcf

# =============================
# 6. apt / yum 卸载
# =============================
echo -e "${YELLOW}[6/6] 检测包管理安装...${RESET}"

if command -v apt &>/dev/null && dpkg -l 2>/dev/null | grep -qi warp; then
    apt purge -y warp-cli
    apt purge -y cloudflare-warp
    apt autoremove -y
elif command -v yum &>/dev/null && rpm -qa | grep -qi warp; then
    yum remove -y cloudflare-warp
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