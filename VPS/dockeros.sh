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
        echo -e "${GREEN}检测到 Alpine Linux，正在调用 Alpine 专用 Docker...${RESET}"
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apdocker.sh)
        ;;
    *)
        echo -e "${GREEN}检测到 $OS 系统，正在调用通用 Docker管理...${RESET}"
        # 通用 Linux 环境 (Debian/Ubuntu/CentOS/Arch等)
        bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/Docker.sh)
        ;;
esac
