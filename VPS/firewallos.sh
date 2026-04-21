# 定义颜色
GREEN='\033[0;32m'
RESET='\033[0m'
# 检测系统环境
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

# 根据系统执行对应的防火墙脚本
case "$OS" in
    alpine)
        echo -e "${GREEN}检测到 Alpine Linux，正在调用Alpine配置防火墙...${RESET}"

        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apfeew.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，正在调用配置通用防火墙...${RESET}"
        # 通用 VPS 脚本
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/firewall.sh)
        ;;
esac
