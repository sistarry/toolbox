# 定义颜色
GREEN='\033[0;32m'
RESET='\033[0m'

# 1. 环境预检
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS=$(uname -s)
fi

# 2. 针对 Alpine 的特殊处理
if [ "$OS" = "alpine" ]; then
    echo -e "${GREEN}检测到 Alpine Linux，正在准备 Fail2Ban 环境...${RESET}"
    
    # 执行 Alpine 专用脚本 (通常包含对 OpenRC 的支持)
    bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/apFail2Ban.sh)

# 3. 针对其他系统的处理
else
    echo -e "${GREEN}检测到 $OS 系统，执行通用 Fail2Ban 配置...${RESET}"
    
    # 执行通用脚本 (通常包含对 Systemd 的支持)
    bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/fail2ban.sh)
fi