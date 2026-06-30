#!/bin/sh
# ========================================
# EasyTier 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / docker / 进程 / 虚拟网卡清理
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}           EasyTier 彻底卸载            ${RESET}"
echo -e "${RED}========================================${RESET}"

# 必须 root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}请使用 root 身份运行此脚本${RESET}"
    exit 1
fi

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止 EasyTier 服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop easytier >/dev/null 2>&1
    systemctl disable easytier >/dev/null 2>&1
    systemctl stop easytier-core >/dev/null 2>&1
    systemctl disable easytier-core >/dev/null 2>&1
    
    rm -f /etc/systemd/system/easytier*.service
    rm -f /lib/systemd/system/easytier*.service
    systemctl daemon-reload >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    rc-service easytier stop >/dev/null 2>&1
    rc-update del easytier default >/dev/null 2>&1
    rm -f /etc/init.d/easytier
fi

# =============================
# 2. 强杀残留进程
# =============================
echo -e "${YELLOW}[2/6] 清理运行进程 (easytier)...${RESET}"

if command -v pkill >/dev/null 2>&1; then
    pkill -9 easytier >/dev/null 2>&1
    pkill -9 easytier-core >/dev/null 2>&1
else
    killall -9 easytier >/dev/null 2>&1
    killall -9 easytier-core >/dev/null 2>&1
fi

# =============================
# 3. 清理虚拟网卡残留
# =============================
echo -e "${YELLOW}[3/6] 清理 EasyTier 虚拟网卡...${RESET}"

# 查找所有包含 easytier 或 et_ 开头的 tun/tap 网卡并尝试删除
if command -v ip >/dev/null 2>&1; then
    for tun_dev in $(ip link show 2>/dev/null | grep -oE '(easytier[0-9]*|et_[0-9a-zA-Z]*)'); do
        echo -e "${YELLOW}正在删除虚拟网卡: $tun_dev...${RESET}"
        ip link delete "$tun_dev" >/dev/null 2>&1
    done
fi

# =============================
# 4. 删除程序二进制与配置
# =============================
echo -e "${YELLOW}[4/6] 删除程序文件与配置...${RESET}"

# 二进制文件
rm -f /usr/bin/easytier* /usr/local/bin/easytier* /bin/easytier*

# 配置文件目录
rm -rf /etc/easytier
rm -rf /opt/easytier
rm -rf /var/lib/easytier
rm -rf ~/.easytier

# 常见的单个配置文件残留
rm -f /etc/easytier.toml
rm -f /etc/easytier.conf

# =============================
# 5. Docker 清理
# =============================
echo -e "${YELLOW}[5/6] 清理 Docker EasyTier...${RESET}"

if command -v docker >/dev/null 2>&1; then
    echo -e "${YELLOW}检查 easytier 容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "easytier" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "easytier" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 easytier 镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "easytier" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 easytier volume...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "easytier" | xargs -r docker volume rm >/dev/null 2>&1
    echo -e "${GREEN}Docker 残留清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 6. 最终残留审计
# =============================
echo -e "${YELLOW}[6/6] 检查残留状态...${RESET}"

# 进程检查 (兼容 BusyBox 的 ps w)
et_proc=$(ps w | grep -Ei "easytier" | grep -v grep)
if [ -n "$et_proc" ]; then
    echo -e "${RED}⚠️ 警告: 仍有进程残留:${RESET}"
    echo "$et_proc"
else
    echo -e "${GREEN}无 EasyTier 进程残留${RESET}"
fi

# 网卡检查
if ip a 2>/dev/null | grep -qEi "easytier|et_"; then
    echo -e "${RED}⚠️ 警告: 仍检测到虚拟网卡残留，可能需要重启系统以彻底释放${RESET}"
else
    echo -e "${GREEN}无虚拟网卡残留${RESET}"
fi

# 端口检查 (EasyTier 默认使用 UDP 11010 运行 peer 发现)
if command -v ss >/dev/null 2>&1; then
    ports=$(ss -uln 2>/dev/null | grep -E "11010|easytier")
else
    ports=$(netstat -uln 2>/dev/null | grep -E "11010|easytier")
fi

if [ -n "$ports" ]; then
    echo -e "${RED}⚠️ 提示: 11010 或关联端口仍被占用:${RESET}"
    echo "$ports"
else
    echo -e "${GREEN}无端口占用残留${RESET}"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}       EasyTier 已彻底卸载完成           ${RESET}"
echo -e "${GREEN}========================================${RESET}"