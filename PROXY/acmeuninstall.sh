#!/bin/bash
# ========================================
# acme.sh 彻底卸载脚本
# 清理证书 / 定时任务 / 账户 / 目录
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${RED}========================================${RESET}"
echo -e "${RED}       ACME(acme.sh) 彻底卸载${RESET}"
echo -e "${RED}========================================${RESET}"

# =============================
# 1. 执行官方卸载（如果存在）
# =============================
echo -e "${YELLOW}[1/5] 尝试官方卸载...${RESET}"

if command -v acme.sh &>/dev/null; then
    acme.sh --uninstall 2>/dev/null
fi

# =============================
# 2. 删除 acme 主目录
# =============================
echo -e "${YELLOW}[2/5] 删除 acme.sh 目录...${RESET}"

rm -rf ~/.acme.sh
rm -rf /root/.acme.sh
rm -rf /home/*/.acme.sh 2>/dev/null

# =============================
# 3. 清理证书残留（重点）
# =============================
echo -e "${YELLOW}[3/5] 清理证书目录...${RESET}"

rm -rf /etc/ssl/acme
rm -rf /etc/acme.sh
rm -rf /var/lib/acme.sh
rm -rf /usr/local/acme.sh

# 常见 nginx/caddy 证书路径（很多人放这里）
rm -rf /etc/letsencrypt
rm -rf /usr/local/etc/letsencrypt

# =============================
# 4. 清理 cron 定时任务
# =============================
echo -e "${YELLOW}[4/5] 清理定时任务...${RESET}"

crontab -l 2>/dev/null | grep -v acme.sh | crontab -

# 删除 root cron 文件（部分脚本写死）
rm -f /var/spool/cron/root 2>/dev/null

# =============================
# 5. 删除残留命令 & 环境变量
# =============================
echo -e "${YELLOW}[5/5] 清理环境残留...${RESET}"

rm -f /usr/local/bin/acme.sh
rm -f /usr/bin/acme.sh

# shell 环境变量清理（如果写入过 profile）
sed -i '/acme\.sh/d' ~/.bashrc 2>/dev/null
sed -i '/acme\.sh/d' ~/.profile 2>/dev/null
sed -i '/acme\.sh/d' /etc/profile 2>/dev/null

# =============================
# 最终检查
# =============================
echo -e "${YELLOW}检查残留...${RESET}"

if command -v acme.sh &>/dev/null; then
    echo -e "${RED}仍然存在 acme.sh 命令${RESET}"
else
    echo -e "${GREEN}acme.sh 已移除${RESET}"
fi

if ls /etc | grep -qi letsencrypt; then
    echo -e "${YELLOW}⚠️ 检测到 letsencrypt 残留${RESET}"
else
    echo -e "${GREEN}无证书残留目录${RESET}"
fi

echo -e "${GREEN}========================================${RESET}"
echo -e "${GREEN}        ACME 已彻底卸载完成${RESET}"
echo -e "${GREEN}========================================${RESET}"