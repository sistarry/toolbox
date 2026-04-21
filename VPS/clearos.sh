# 获取系统 ID
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

case "$OS" in
    alpine)
        echo -e "${GREEN}检测到 Alpine Linux，正在执行轻量化系统清理...${RESET}"
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apclear.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，正在执行通用系统清理...${RESET}"
        # 通用 VPS 环境 (通常涉及 apt/yum/journalctl)
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/clear.sh)
        ;;
esac