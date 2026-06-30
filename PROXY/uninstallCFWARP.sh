#!/bin/sh
# ========================================
# Cloudflare WARP 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / apt / yum / apk / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}         Cloudflare WARP 彻底卸载        ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. warp u 卸载
# =============================
echo -e "${YELLOW}[1/7] 尝试 warp u 卸载...${RESET}"

if command -v warp >/dev/null 2>&1; then
    warp u >/dev/null 2>&1 && echo -e "${GREEN}warp u 已执行${RESET}"
fi

# =============================
# 2. warp-cli 清理
# =============================
echo -e "${YELLOW}[2/7] 清理 warp-cli...${RESET}"

if command -v warp-cli >/dev/null 2>&1; then
    warp-cli disconnect >/dev/null 2>&1
    warp-cli delete >/dev/null 2>&1
fi

# =============================
# 3. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[3/7] 停止 WARP 服务...${RESET}"

# 3.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop warp-svc >/dev/null 2>&1
    systemctl disable warp-svc >/dev/null 2>&1
    systemctl stop wg-quick@wgcf >/dev/null 2>&1
    systemctl disable wg-quick@wgcf >/dev/null 2>&1
    systemctl stop wgcf >/dev/null 2>&1
    systemctl disable wgcf >/dev/null 2>&1
fi

# 3.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    for service in warp-svc wgcf wg-quick; do
        rc-service $service stop >/dev/null 2>&1
        rc-update del $service default >/dev/null 2>&1
        rm -f /etc/init.d/$service
    done
fi

# =============================
# 4. wgcf / wireguard 接口清理
# =============================
echo -e "${YELLOW}[4/7] 清理 WGCF / WireGuard...${RESET}"

if command -v wg-quick >/dev/null 2>&1; then
    wg-quick down wgcf >/dev/null 2>&1
fi

# 修复了原有 POSIX sh 下 { } 的语法兼容问题
if ip link show 2>/dev/null | grep -qE "wgcf|warp"; then
    ip link delete wgcf >/dev/null 2>&1
    ip link delete warp >/dev/null 2>&1
fi

# =============================
# 5. 删除程序与配置文件
# =============================
echo -e "${YELLOW}[5/7] 删除程序文件...${RESET}"

rm -f /usr/bin/warp /usr/local/bin/warp
rm -f /usr/bin/warp-cli /usr/local/bin/warp-cli
rm -f /usr/bin/wgcf /usr/local/bin/wgcf

rm -rf /opt/warp /etc/warp
rm -rf /etc/wireguard
rm -rf ~/.warp ~/.wgcf

# =============================
# 6. 包管理卸载 (增加 apk 支持)
# =============================
echo -e "${YELLOW}[6/7] 检测包管理安装...${RESET}"

if command -v apk >/dev/null 2>&1; then
    # Alpine 环境 (部分第三方构建的 wgcf/wireguard-tools)
    apk del cloudflare-warp wgcf wireguard-tools >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu 环境
    if dpkg -l 2>/dev/null | grep -qiE "warp|wgcf"; then
        apt purge -y warp-cli cloudflare-warp wgcf >/dev/null 2>&1
        apt autoremove -y >/dev/null 2>&1
    fi
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL 环境
    if rpm -qa | grep -qiE "warp|wgcf"; then
        yum remove -y cloudflare-warp wgcf >/dev/null 2>&1
    fi
fi

# =============================
# 7. Docker 清理
# =============================
echo -e "${YELLOW}[7/7] 清理 Docker WARP 相关残留...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查 WARP 相关容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 WARP 相关镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "warp|wgcf|cloudflare" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 WARP 相关数据卷...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "warp|wgcf|cloudflare" | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker WARP 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 最终检测
# =============================
echo -e "${YELLOW}检查残留状态...${RESET}"

# 兼容 Alpine (BusyBox) 的 ps w 格式
warp_status=$(ps w | grep -Ei "warp|wgcf" | grep -v grep)

if [ -n "$warp_status" ]; then
    echo -e "${RED}仍有进程残留:${RESET}"
    echo "$warp_status"
else
    echo -e "${GREEN}无进程残留${RESET}"
fi

if ip a 2>/dev/null | grep -qEi "warp|wgcf"; then
    echo -e "${YELLOW}⚠️ 仍有虚拟网卡残留${RESET}"
else
    echo -e "${GREEN}无虚拟网卡残留${RESET}"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}      WARP 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"