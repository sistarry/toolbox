#!/bin/sh
# ========================================
# FRP 彻底卸载脚本（全平台通用版）
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / docker / 进程 / 配置 / 端口
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}        FRP 彻底卸载开始执行            ${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止系统服务...${RESET}"

# 1.1 适配 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    systemctl stop frps >/dev/null 2>&1
    systemctl stop frpc >/dev/null 2>&1
    systemctl disable frps >/dev/null 2>&1
    systemctl disable frpc >/dev/null 2>&1
    
    systemctl stop frps@* >/dev/null 2>&1
    systemctl stop frpc@* >/dev/null 2>&1
    
    rm -f /etc/systemd/system/frps.service
    rm -f /etc/systemd/system/frpc.service
    rm -f /etc/systemd/system/frps@*.service
    rm -f /etc/systemd/system/frpc@*.service
    
    systemctl daemon-reload >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    for service in frps frpc; do
        rc-service $service stop >/dev/null 2>&1
        rc-update del $service default >/dev/null 2>&1
        rm -f /etc/init.d/$service
    done
fi

# =============================
# 2. 杀掉进程
# =============================
echo -e "${YELLOW}[2/6] 清理运行进程...${RESET}"

if command -v pkill >/dev/null 2>&1; then
    pkill -f frps >/dev/null 2>&1
    pkill -f frpc >/dev/null 2>&1
else
    killall frps >/dev/null 2>&1
    killall frpc >/dev/null 2>&1
fi

# =============================
# 3. 删除二进制 & 配置
# =============================
echo -e "${YELLOW}[3/6] 删除程序文件...${RESET}"

rm -f /usr/bin/frps /usr/bin/frpc
rm -f /usr/local/bin/frps /usr/local/bin/frpc
rm -f /bin/frps /bin/frpc

rm -rf /etc/frp
rm -rf /opt/frp
rm -rf /var/lib/frp

rm -f /etc/frps.ini /etc/frpc.ini
rm -f /etc/frps.toml /etc/frpc.toml

rm -rf ~/.frp

# =============================
# 4. 清理启动脚本 / 环境变量 (引入存在性判断)
# =============================
echo -e "${YELLOW}[4/6] 清理环境残留...${RESET}"

for file in ~/.bashrc ~/.profile /etc/profile; do
    if [ -f "$file" ]; then
        sed -i '/frps/d' "$file" 2>/dev/null
        sed -i '/frpc/d' "$file" 2>/dev/null
    fi
done

# =============================
# 5. Docker 清理
# =============================
echo -e "${YELLOW}[5/6] 清理 Docker FRP...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查 frp 容器...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "frp|frps|frpc" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "frp|frps|frpc" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 frp 镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "frp" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查 frp volume...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "frp" | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker frp 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 6. 最终检查
# =============================
echo -e "${YELLOW}[6/6] 检查残留状态...${RESET}"

# 兼容 Alpine (BusyBox) 的 ps w 格式
frp_proc=$(ps w | grep -Ei "frps|frpc" | grep -v grep)

# 使用标准 POSIX [ -n ] 替代 [[ -n ]]
if [ -n "$frp_proc" ]; then
    echo -e "${RED}仍有进程残留:${RESET}"
    echo "$gost_proc"
else
    echo -e "${GREEN}无 FRP 进程残留${RESET}"
fi

# 检查端口监听（兼容 BusyBox 剪裁版的 ss/netstat）
if command -v ss >/dev/null 2>&1; then
    ss -lnt 2>/dev/null | grep -Ei "7000|7500|6000|frp"
else
    netstat -lnt 2>/dev/null | grep -Ei "7000|7500|6000|frp"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        FRP 已彻底卸载完成               ${RESET}"
echo -e "${GREEN}========================================${RESET}"