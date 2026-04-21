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
        echo -e "${GREEN}检测到 Alpine Linux，正在执行 Alpine 专用 Nginx 反代配置...${RESET}"
        # 确保基础工具已安装
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/approxy.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，正在执行通用 Nginx 反代配置...${RESET}"
        # 通用 VPS 环境 (通常基于 Systemd)
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/ngixv4.sh)
        ;;
esac
