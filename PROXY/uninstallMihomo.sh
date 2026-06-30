#!/bin/sh
# ========================================
# Mihomo (Clash Meta) 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / apt / yum / apk / docker
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}       Mihomo 彻底卸载开始执行           ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止相关服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止 Mihomo/Clash 服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop mihomo >/dev/null 2>&1
    systemctl disable mihomo >/dev/null 2>&1
    systemctl stop clash >/dev/null 2>&1
    systemctl disable clash >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    for service in mihomo clash clash-meta; do
        rc-service $service stop >/dev/null 2>&1
        rc-update del $service default >/dev/null 2>&1
        rm -f /etc/init.d/$service
    done
fi

# 1.3 暴力保底杀进程
if command -v pkill >/dev/null 2>&1; then
    pkill -9 mihomo >/dev/null 2>&1
    pkill -9 clash >/dev/null 2>&1
else
    killall -9 mihomo >/dev/null 2>&1
    killall -9 clash >/dev/null 2>&1
fi

# =============================
# 2. 包管理器卸载 (apt / yum / apk)
# =============================
echo -e "${YELLOW}[2/6] 检测包管理安装...${RESET}"

if command -v apk >/dev/null 2>&1; then
    # Alpine 环境
    apk del mihomo clash-meta >/dev/null 2>&1
elif command -v apt >/dev/null 2>&1; then
    # Debian/Ubuntu 环境
    if dpkg -l 2>/dev/null | grep -qiE 'mihomo|clash'; then
        echo -e "${YELLOW}检测到 apt 安装的软件包${RESET}"
        apt purge -y mihomo clash-meta 2>/dev/null
        apt autoremove -y
    fi
elif command -v yum >/dev/null 2>&1; then
    # CentOS/RHEL 环境
    if rpm -qa | grep -qiE 'mihomo|clash'; then
        echo -e "${YELLOW}检测到 yum 安装的软件包${RESET}"
        yum remove -y mihomo clash-meta 2>/dev/null
    fi
fi

# =============================
# 3. 删除二进制文件
# =============================
echo -e "${YELLOW}[3/6] 清理可执行文件...${RESET}"

rm -f /usr/local/bin/mihomo /usr/bin/mihomo
rm -f /usr/local/bin/clash /usr/bin/clash

# =============================
# 4. 清理配置 & 数据
# =============================
echo -e "${YELLOW}[4/6] 清理配置与日志...${RESET}"

rm -rf /etc/mihomo /etc/clash
rm -rf /usr/local/etc/mihomo /usr/local/etc/clash
rm -rf /var/log/mihomo /var/log/clash
rm -rf /opt/mihomo

# =============================
# 5. systemd 服务文件清理
# =============================
echo -e "${YELLOW}[5/6] 清理 systemd 服务文件...${RESET}"

rm -f /etc/systemd/system/mihomo.service
rm -f /etc/systemd/system/clash.service
rm -f /etc/systemd/system/clash-meta.service

if command -v systemctl >/dev/null 2>&1; then
    systemctl daemon-reload >/dev/null 2>&1
fi

# =============================
# 6. Docker + 网络残留
# =============================
echo -e "${YELLOW}[6/6] 清理 Docker 与残留...${RESET}"

if command -v docker >/dev/null 2>&1; then
    docker ps -a --format "{{.Names}}" | grep -Ei 'mihomo|clash|meta' | xargs -r docker rm -f >/dev/null 2>&1
fi

# 检查 TUN / 虚拟网卡 (修复原本在 sh 容易报错的条件块结构)
if ip link show 2>/dev/null | grep -qEi 'mihomo|clash'; then
    echo -e "${YELLOW}⚠️ 检测到虚拟网卡残留（可能需要手动或重启后物理清理）${RESET}"
fi

# =============================
# 最终检查 (兼容 BusyBox 命令格式)
# =============================
echo -e "${YELLOW}检查残留进程/端口...${RESET}"

ps w | grep -Ei 'mihomo|clash' | grep -v grep

if command -v ss >/dev/null 2>&1; then
    ports=$(ss -tuln 2>/dev/null | grep -Ei 'mihomo|clash')
else
    ports=$(netstat -tuln 2>/dev/null | grep -Ei 'mihomo|clash')
fi

# 用标准 POSIX [ -n ] 替代 [[ -n ]]
if [ -n "$ports" ]; then
    echo -e "${RED}仍有端口占用或未释放绑定:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无 mihomo/clash 端口残留${RESET}"
fi

# =============================
# 完成
# =============================
echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}      ✅ Mihomo 已彻底卸载完成          ${RESET}"
echo -e "${GREEN}========================================${RESET}"