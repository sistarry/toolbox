#!/bin/sh
# ========================================
# Realm 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / docker / 进程 / 配置清理
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}           Realm 彻底卸载                ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止系统服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop realm >/dev/null 2>&1
    systemctl disable realm >/dev/null 2>&1
    systemctl stop realm@* >/dev/null 2>&1
    systemctl disable realm@* >/dev/null 2>&1
    
    # 删除 systemd 服务文件
    rm -f /etc/systemd/system/realm.service
    rm -f /etc/systemd/system/realm@*.service
    systemctl daemon-reload >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    rc-service realm stop >/dev/null 2>&1
    rc-update del realm default >/dev/null 2>&1
    rm -f /etc/init.d/realm
fi

# =============================
# 2. 停止进程
# =============================
echo -e "${YELLOW}[2/6] 清理运行进程...${RESET}"

# 优先使用 pkill，如果 BusyBox 裁切了 pkill，则回退使用 killall
if command -v pkill >/dev/null 2>&1; then
    pkill -f realm >/dev/null 2>&1
else
    killall realm >/dev/null 2>&1
fi

# =============================
# 3. 删除二进制文件
# =============================
echo -e "${YELLOW}[3/6] 删除程序文件...${RESET}"

rm -f /usr/bin/realm
rm -f /usr/local/bin/realm
rm -f /bin/realm

rm -rf /opt/realm
rm -rf /etc/realm
rm -rf /var/lib/realm
rm -rf ~/.realm

# =============================
# 4. 清理配置文件
# =============================
echo -e "${YELLOW}[4/6] 清理配置文件...${RESET}"

rm -f /etc/realm.json
rm -f /etc/realm/config.json
rm -f /usr/local/etc/realm.json

# =============================
# 5. Docker 清理
# =============================
echo -e "${YELLOW}[5/6] 清理 Docker Realm 相关...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查 realm 容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "realm" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "realm" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 realm 镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "realm" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 realm volume...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "realm" | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker realm 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 6. 检测端口与进程残留
# =============================
echo -e "${YELLOW}[6/6] 检测端口/残留进程...${RESET}"

# 兼容 Alpine (BusyBox) 的 ps w 格式
realm_proc=$(ps w | grep -Ei "realm" | grep -v grep)

# 使用标准 POSIX [ -n ] 替代 [[ -n ]]
if [ -n "$realm_proc" ]; then
    echo -e "${RED}仍有进程残留:${RESET}"
    echo "$realm_proc"
else
    echo -e "${GREEN}无 realm 进程残留${RESET}"
fi

# 检查常见端口占用（兼容 BusyBox ss 输出）
if command -v ss >/dev/null 2>&1; then
    ss -lnt 2>/dev/null | grep -Ei "realm"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        Realm 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"