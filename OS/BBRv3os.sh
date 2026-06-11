#!/bin/bash

# 颜色定义
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 代理前缀列表（第一个留空代表直连尝试）
GITHUB_PROXY=(
    ''
    'https://v6.gh-proxy.org/'
    'https://gh-proxy.com/'
    'https://hub.glowp.xyz/'
    'https://proxy.vvvv.ee/'
    'https://ghproxy.lvedong.eu.org/'
)
# --------------------------
# 架构检测函数
# --------------------------
check_virt() {
    
    # 尝试使用 systemd-detect-virt (如果系统支持)
    if command -v systemd-detect-virt >/dev/null 2>&1; then
        VIRT=$(systemd-detect-virt)
    else
        # 针对 Alpine 等无 systemd 系统，通过常见特征检测
        if [ -f /proc/user_beancounters ]; then
            VIRT="openvz"
        elif grep -q "lxc" /proc/1/environ 2>/dev/null || [ -f /run/container_type ]; then
            VIRT="lxc"
        else
            VIRT="kvm_or_other"
        fi
    fi

    if [ "$VIRT" == "lxc" ] || [ "$VIRT" == "openvz" ]; then
        echo -e "${YELLOW}❌ 警告: 您的系统处于 $VIRT 容器环境下。${RESET}"
        echo -e "${YELLOW}容器环境无法自主修改内核模块，请联系宿主机提供商在母鸡开启 BBR。${RESET}"
        exit 1
    fi
}

# --------------------------
# Alpine 开启 BBR 逻辑
# --------------------------
enable_bbr_alpine() {

    # 尝试加载模块（静默处理，防止报错）
    modprobe tcp_bbr 2>/dev/null || true
    
    mkdir -p /etc/sysctl.d/
    cat > /etc/sysctl.d/bbr.conf <<EOF
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF

    # 尝试使其生效
    sysctl -p /etc/sysctl.d/bbr.conf 2>/dev/null || true

    if sysctl net.ipv4.tcp_congestion_control | grep -q "bbr"; then
        echo "tcp_bbr" >> /etc/modules 2>/dev/null || true
        echo -e "${YELLOW}================================${RESET}"
        echo -e "${YELLOW}      ✅BBR+FQ 已成功开启！     ${RESET}"
        echo -e "${YELLOW}================================${RESET}"
    else
        echo -e "${YELLOW}❌ BBR 开启失败。可能原因：内核版本过低或缺少内核模块包。${RESET}"
        echo -e "${YELLOW}提示: 尝试运行 'apk add linux-lts' 升级内核后重启再试。${RESET}"
    fi
}

# --------------------------
# 主逻辑
# --------------------------

# 1. 先查架构
check_virt

# 2. 再查发行版
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    OS="unknown"
fi


# 核心下载与执行函数（多代理自动轮询容灾）
fetch_and_run() {
    local script_url="$1"
    local success=1 # 默认失败状态

    # 遍历代理数组
    for proxy in "${GITHUB_PROXY[@]}"; do
        local full_url="${proxy}${script_url}"
        
        # 提示当前正在尝试的链接
        if [ -z "$proxy" ]; then
            echo
        else
            echo
        fi

        # 执行下载与运行
        if bash <(curl -fsSL --connect-timeout 5 "$full_url"); then
            echo
            success=0
            break # 成功后跳出循环
        fi
    done

    # 如果所有代理都失败了
    if [ $success -ne 0 ]; then
        echo -e "${RED}错误：所有代理通道均已失败，请检查网络连接。${RESET}"
        exit 1
    fi
}


case "$OS" in
    alpine)
        enable_bbr_alpine
        ;;
    debian|ubuntu|centos|rocky|almalinux|fedora)

        fetch_and_run "https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/BBRV3.sh"
        ;;
    *)
        fetch_and_run "https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/BBRV3.sh"
        ;;
esac
