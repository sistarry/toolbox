#!/bin/sh
# ========================================
# Sing-box + S-UI 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / apt / yum / apk / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}    Sing-box + S-UI 彻底卸载开始执行     ${RESET}"
echo -e "${RED}========================================${RESET}"

# 必须 root (兼容 Alpine/POSIX sh 的 root 检查)
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}请使用 root 身份运行此脚本${RESET}"
    exit 1
fi

# =============================
# 1. 停止服务 & 杀进程 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/7] 停止服务与进程...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop sing-box >/dev/null 2>&1
    systemctl disable sing-box >/dev/null 2>&1
    systemctl stop s-ui >/dev/null 2>&1
    systemctl disable s-ui >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    for service in sing-box s-ui; do
        rc-service $service stop >/dev/null 2>&1
        rc-update del $service default >/dev/null 2>&1
        rm -f /etc/init.d/$service
    done
fi

# 1.3 强杀进程兜底
if command -v pkill >/dev/null 2>&1; then
    pkill -9 sing-box >/dev/null 2>&1
    pkill -9 s-ui >/dev/null 2>&1
else
    killall -9 sing-box >/dev/null 2>&1
    killall -9 s-ui >/dev/null 2>&1
fi

# =============================
# 2. 包管理卸载 (增加 apk 支持)
# =============================
echo -e "${YELLOW}[2/7] 检测包管理安装...${RESET}"

if command -v apk >/dev/null 2>&1; then
    # Alpine 环境
    apk del sing-box >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu 环境
    if dpkg -l 2>/dev/null | grep -q sing-box; then
        echo -e "${YELLOW}检测到 apt 安装 Sing-box${RESET}"
        apt purge -y sing-box
        apt autoremove -y
    fi
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL 环境
    if rpm -qa | grep -q sing-box; then
        echo -e "${YELLOW}检测到 yum 安装 Sing-box${RESET}"
        yum remove -y sing-box
    fi
fi

# =============================
# 3. 删除可执行文件
# =============================
echo -e "${YELLOW}[3/7] 清理可执行文件...${RESET}"

rm -f /usr/local/bin/sing-box /usr/bin/sing-box
rm -f /usr/bin/s-ui

# =============================
# 4. 删除配置 & 数据 & 日志
# =============================
echo -e "${YELLOW}[4/7] 清理配置与日志...${RESET}"

rm -rf /etc/sing-box /usr/local/etc/sing-box /var/log/sing-box /opt/sing-box
rm -rf /usr/local/s-ui /etc/s-ui /var/log/s-ui

# =============================
# 5. 删除 systemd 服务文件
# =============================
echo -e "${YELLOW}[5/7] 清理 systemd 服务文件...${RESET}"

rm -f /etc/systemd/system/sing-box.service
rm -f /etc/systemd/system/sing-box@.service
rm -f /etc/systemd/system/s-ui.service

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload >/dev/null 2>&1
    systemctl reset-failed >/dev/null 2>&1
fi

# =============================
# 6. Docker 清理
# =============================
echo -e "${YELLOW}[6/7] 清理 Docker 残留...${RESET}"

if command -v docker >/dev/null 2>&1; then
    docker ps -a --format "{{.Names}}" | grep -Ei 'sing-box|singbox|s-ui|sui' | xargs -r docker rm -f >/dev/null 2>&1
fi

# =============================
# 7. 网络接口 & 残留检查
# =============================
echo -e "${YELLOW}[7/7] 检查残留...${RESET}"

# 检查虚拟网卡 (TUN/TAP)
if ip link show >/dev/null 2>&1; then
    echo -e "${YELLOW}检查关联虚拟网卡:${RESET}"
    ip link show 2>/dev/null | grep -iE 'sing|tun'
fi

# 检查进程 (兼容 BusyBox 的 ps 参数)
echo -e "${YELLOW}检查活跃进程:${RESET}"
ps w | grep -E 'sing-box|s-ui' | grep -v grep

# 检查端口 (兼容 BusyBox ss / netstat)
echo -e "${YELLOW}检查活跃端口:${RESET}"
if command -v ss >/dev/null 2>&1; then
    ports=$(ss -tuln 2>/dev/null | grep -Ei 'sing-box|s-ui')
else
    ports=$(netstat -tuln 2>/dev/null | grep -Ei 'sing-box|s-ui')
fi

if [ -n "$ports" ]; then
    echo -e "${RED}仍有端口占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无端口残留${RESET}"
fi

# =============================
# 完成
# =============================
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}     Sing-box + S-UI 已彻底卸载完成      ${RESET}"
echo -e "${GREEN}========================================${RESET}"
