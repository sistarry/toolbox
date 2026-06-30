#!/bin/sh
# ========================================
# GOST 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / docker / 进程 / 配置 / 端口残留
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        GOST 彻底卸载开始执行            ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止系统服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop gost >/dev/null 2>&1
    systemctl disable gost >/dev/null 2>&1
    systemctl stop gost@* >/dev/null 2>&1
    systemctl disable gost@* >/dev/null 2>&1
    
    rm -f /etc/systemd/system/gost.service
    rm -f /etc/systemd/system/gost@*.service
    systemctl daemon-reload >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    rc-service gost stop >/dev/null 2>&1
    rc-update del gost default >/dev/null 2>&1
    rm -f /etc/init.d/gost
fi

# =============================
# 2. 杀掉进程
# =============================
echo -e "${YELLOW}[2/6] 清理运行进程...${RESET}"

if command -v pkill >/dev/null 2>&1; then
    pkill -f gost >/dev/null 2>&1
else
    killall gost >/dev/null 2>&1
fi

# =============================
# 3. 删除二进制文件 & 配置
# =============================
echo -e "${YELLOW}[3/6] 删除程序文件...${RESET}"

rm -f /usr/bin/gost
rm -f /usr/local/bin/gost
rm -f /bin/gost

rm -rf /etc/gost
rm -rf /opt/gost
rm -rf /var/lib/gost
rm -rf ~/.gost

rm -f /etc/gost.json
rm -f /etc/gost.yaml
rm -f /etc/gost.yml

# =============================
# 4. 清理启动脚本 / 环境变量 (加入文件存在性校验)
# =============================
echo -e "${YELLOW}[4/6] 清理环境残留...${RESET}"

[ -f ~/.bashrc ] && sed -i '/gost/d' ~/.bashrc 2>/dev/null
[ -f ~/.profile ] && sed -i '/gost/d' ~/.profile 2>/dev/null
[ -f /etc/profile ] && sed -i '/gost/d' /etc/profile 2>/dev/null

# =============================
# 5. Docker 清理
# =============================
echo -e "${YELLOW}[5/6] 清理 Docker GOST...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查 gost 容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "gost" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "gost" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 gost 镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "gost" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 gost volume...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "gost" | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker gost 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 6. 检查残留状态
# =============================
echo -e "${YELLOW}[6/6] 检查残留状态...${RESET}"

# 兼容 Alpine (BusyBox) 的 ps w 格式
gost_proc=$(ps w | grep -Ei "gost" | grep -v grep)

# 使用标准 POSIX [ -n ] 替代 [[ -n ]]
if [ -n "$gost_proc" ]; then
    echo -e "${RED}仍有进程残留:${RESET}"
    echo "$gost_proc"
else
    echo -e "${GREEN}无进程残留${RESET}"
fi

# 检查端口占用（兼容 BusyBox 剪裁版的 ss/netstat）
if command -v ss >/dev/null 2>&1; then
    ss -lnt 2>/dev/null | grep -Ei "gost"
else
    netstat -lnt 2>/dev/null | grep -Ei "gost"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        GOST 已彻底卸载完成             ${RESET}"
echo -e "${GREEN}========================================${RESET}"