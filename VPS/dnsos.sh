# 定义颜色
GREEN='\033[0;32m'
RESET='\033[0m'
# 检查系统版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

# 根据 OS 类型执行不同的 DNS 设置逻辑
case "$OS" in
    alpine)
        echo -e "${GREEN}检测到 Alpine Linux，正在执行专用 DNS 配置...${RESET}"
        # 针对 Alpine 的逻辑：直接修改 /etc/resolv.conf 并锁定
        # 也可以直接调用你现有的 apdns.sh
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apdns.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，执行通用 DNS 配置...${RESET}"
        # 针对 Debian/Ubuntu/CentOS 的通用逻辑
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/dns.sh)
        ;;
esac
