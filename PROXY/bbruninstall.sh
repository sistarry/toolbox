#!/bin/bash
# ========================================
# BBR 卸载 + 恢复系统默认 TCP
# ========================================

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
RESET="\033[0m"

echo -e "${YELLOW}开始恢复系统默认 TCP...${RESET}"

SYSCTL_FILE="/etc/sysctl.conf"
SYSCTL_DIR="/etc/sysctl.d"

# =============================
# 1. 清理所有 BBR / TCP 优化残留
# =============================
echo -e "${YELLOW}清理 sysctl 配置...${RESET}"

sed -i '/bbr/d' $SYSCTL_FILE 2>/dev/null
sed -i '/tcp_congestion_control/d' $SYSCTL_FILE 2>/dev/null
sed -i '/default_qdisc/d' $SYSCTL_FILE 2>/dev/null
sed -i '/fq/d' $SYSCTL_FILE 2>/dev/null

rm -f $SYSCTL_DIR/*bbr*.conf 2>/dev/null
rm -f $SYSCTL_DIR/*tcp*.conf 2>/dev/null
rm -f $SYSCTL_DIR/*network*.conf 2>/dev/null

# =============================
# 2. 自动判断系统支持的 qdisc
# =============================
QDISC="fq_codel"

if sysctl -a 2>/dev/null | grep -q "fq"; then
    QDISC="fq"
fi

echo -e "${GREEN}使用队列算法: $QDISC${RESET}"

# =============================
# 3. 恢复 TCP 为 cubic（系统默认）
# =============================
sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
sysctl -w net.core.default_qdisc=$QDISC >/dev/null 2>&1

# =============================
# 4. 写入持久配置
# =============================
cat > /etc/sysctl.d/99-default-tcp.conf <<EOF
net.ipv4.tcp_congestion_control=cubic
net.core.default_qdisc=$QDISC
EOF

# =============================
# 5. 立即生效
# =============================
sysctl -p >/dev/null 2>&1

# =============================
# 6. 检查状态
# =============================
echo ""
echo -e "${GREEN}当前 TCP 状态：${RESET}"
sysctl net.ipv4.tcp_congestion_control
sysctl net.core.default_qdisc

# =============================
# 7. 提示
# =============================
echo ""
echo -e "${GREEN}✔ 已恢复系统默认 TCP 环境${RESET}"
echo -e "${YELLOW}如果之前装过 BBR脚本但仍异常，建议重启系统${RESET}"
