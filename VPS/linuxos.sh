# 定义颜色
GREEN='\033[0;32m'
RESET='\033[0m'

# 获取系统 ID
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

case "$OS" in
    alpine)
        echo -e "${GREEN}检测到 Alpine Linux，正在执行更换系统软件源...${RESET}"
        bash <(curl -sSL https://linuxmirrors.cn/main.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，正在执行更换系统软件源...${RESET}"
        # 通用 VPS 环境 (通常涉及 apt/yum/journalctl)
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/huanyuan.sh)
        ;;
esac