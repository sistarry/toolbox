#!/bin/sh
# ========================================
# Cloudflare Tunnel / Argo 彻底卸载脚本
# 支持：Ubuntu / Debian / CentOS / Alpine Linux
# 兼容：systemd / openrc / docker / 进程 / 环境清理
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}   Cloudflare / Argo Tunnel 彻底卸载${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 停止系统服务 (同时兼容 systemd 和 openrc)
# =============================
echo -e "${YELLOW}[1/6] 停止系统服务 (cloudflared/argo)...${RESET}"

# 1.1 适配传统的 systemd (Ubuntu, Debian, CentOS 等)
if command -v systemctl >/dev/null 2>&1; then
    for service in cloudflared argo; do
        systemctl stop $service >/dev/null 2>&1
        systemctl disable $service >/dev/null 2>&1
        systemctl stop ${service}@* >/dev/null 2>&1
        systemctl disable ${service}@* >/dev/null 2>&1
        rm -f /etc/systemd/system/${service}.service
        rm -f /etc/systemd/system/${service}@*.service
    done
    systemctl daemon-reload >/dev/null 2>&1
fi

# 1.2 适配 Alpine 的 openrc
if command -v rc-service >/dev/null 2>&1; then
    for service in cloudflared argo; do
        rc-service $service stop >/dev/null 2>&1
        rc-update del $service default >/dev/null 2>&1
        rm -f /etc/init.d/$service
    done
fi

# =============================
# 2. 杀掉残留进程
# =============================
echo -e "${YELLOW}[2/6] 清理运行进程 (cloudflared/argo)...${RESET}"

# 优先使用 pkill，如果 BusyBox 裁切了 pkill，则回退使用 killall
if command -v pkill >/dev/null 2>&1; then
    pkill -f cloudflared >/dev/null 2>&1
    pkill -f argo >/dev/null 2>&1
else
    killall cloudflared >/dev/null 2>&1
    killall argo >/dev/null 2>&1
fi

# =============================
# 3. 删除二进制程序文件
# =============================
echo -e "${YELLOW}[3/6] 删除程序文件...${RESET}"

rm -f /usr/bin/cloudflared /usr/local/bin/cloudflared /bin/cloudflared
rm -f /usr/bin/argo /usr/local/bin/argo /bin/argo
rm -f ./argo

# 标准 POSIX sh 的字符串非空判断，替代 Bash 的 [[ -n ]]
if [ -n "$work_dir" ]; then
    rm -f "${work_dir}/argo"
fi

# =============================
# 4. 删除配置 / 证书 / 数据
# =============================
echo -e "${YELLOW}[4/6] 清理配置与隧道数据...${RESET}"

rm -rf /etc/cloudflared /opt/cloudflared /var/lib/cloudflared ~/.cloudflared
rm -rf /etc/argo /opt/argo ~/.argo

# =============================
# 5. 清理环境变量 (兼容 BusyBox 文本流)
# =============================
echo -e "${YELLOW}[5/6] 清理环境变量...${RESET}"

# 增加 Alpine 常见的 .ashrc，并用 grep -v 代替不兼容的 sed -i
for file in ~/.bashrc ~/.profile ~/.ashrc /etc/profile; do
    if [ -f "$file" ]; then
        grep -vE "cloudflared|argo" "$file" > "${file}.tmp" 2>/dev/null && mv "${file}.tmp" "$file"
    fi
done

# =============================
# 6. Docker 清理
# =============================
echo -e "${YELLOW}[6/6] 清理 Docker 中的 Tunnel...${RESET}"

if command -v docker >/dev/null 2>&1; then

    echo -e "${YELLOW}检查相关容器 (cloudflared/tunnel/argo)...${RESET}"
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "cloudflared|tunnel|argo" | awk '{print $1}' | xargs -r docker stop >/dev/null 2>&1
    docker ps -a --format '{{.ID}} {{.Names}}' | grep -Ei "cloudflared|tunnel|argo" | awk '{print $1}' | xargs -r docker rm -f >/dev/null 2>&1

    echo -e "${YELLOW}检查相关镜像...${RESET}"
    docker images --format '{{.Repository}} {{.ID}}' | grep -Ei "cloudflared|cloudflare|argo" | awk '{print $2}' | xargs -r docker rmi -f >/dev/null 2>&1

    echo -e "${YELLOW}检查相关 volume...${RESET}"
    docker volume ls --format '{{.Name}}' | grep -Ei "cloudflared|tunnel|argo" | xargs -r docker volume rm >/dev/null 2>&1

    echo -e "${GREEN}Docker 清理完成${RESET}"
else
    echo -e "${YELLOW}未检测到 Docker，跳过${RESET}"
fi

# =============================
# 最终检测
# =============================
echo -e "${YELLOW}检查残留状态...${RESET}"

# 兼容 Alpine(BusyBox) 的 ps 参数格式
residual_proc=$(ps w | grep -Ei "cloudflared|argo" | grep -v grep)

if [ -n "$residual_proc" ]; then
    echo -e "${RED}警告: 仍有进程残留:${RESET}"
    echo "$residual_proc"
else
    echo -e "${GREEN}恭喜: 无 cloudflared/argo 进程残留${RESET}"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}    Tunnel / Argo 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"