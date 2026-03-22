#!/bin/bash
# ===============================
# 菜单式管理 onedocker 容器（国外源）
# 支持 创建 / 删除 / 查询容器信息
# ===============================

SCRIPT_URL="https://raw.githubusercontent.com/oneclickvirt/docker/main/scripts/onedocker.sh"
SCRIPT_FILE="onedocker.sh"

# 颜色定义
green="\033[32m"
reset="\033[0m"

# -------------------------------
# 下载 onedocker.sh
# -------------------------------
download_onedocker() {
    if [ ! -f "$SCRIPT_FILE" ]; then
        echo "📥 下载 onedocker.sh（国外源）..."
        curl -L "$SCRIPT_URL" -o "$SCRIPT_FILE"
        chmod +x "$SCRIPT_FILE"
    fi
}

# -------------------------------
# 创建容器
# -------------------------------
create_container() {
    # 默认配置
    CONTAINER_NAME="mydocker"
    CPU=1
    MEMORY=512
    PASSWORD="123456"
    SSHPORT=25000
    STARTPORT=34975
    ENDPORT=35000
    IPV6="N"
    SYSTEM="debian"
    DISK="5"

    # 交互式输入
    read -p "容器名称 [例如:$CONTAINER_NAME]: " input; [ -n "$input" ] && CONTAINER_NAME=$input
    read -p "CPU 核数 [例如:$CPU]: " input; [ -n "$input" ] && CPU=$input
    read -p "内存 MB [例如:$MEMORY]: " input; [ -n "$input" ] && MEMORY=$input
    read -p "root 密码 [例如:$PASSWORD]: " input; [ -n "$input" ] && PASSWORD=$input
    read -p "SSH 端口 [例如:$SSHPORT]: " input; [ -n "$input" ] && SSHPORT=$input
    read -p "端口范围开始 [例如:$STARTPORT]: " input; [ -n "$input" ] && STARTPORT=$input
    read -p "端口范围结束 [例如:$ENDPORT]: " input; [ -n "$input" ] && ENDPORT=$input
    read -p "独立 IPv6地址 [默认$IPV6]: " input; [ -n "$input" ] && IPV6=$input
    read -p "系统类型 [例如:$SYSTEM]: " input; [ -n "$input" ] && SYSTEM=$input
    read -p "硬盘大小GB [$DISK]: " input; [ -n "$input" ] && DISK=$input

    # 下载脚本并执行
    download_onedocker
    echo "🚀 开始创建容器: $CONTAINER_NAME"
    ./$SCRIPT_FILE "$CONTAINER_NAME" "$CPU" "$MEMORY" "$PASSWORD" "$SSHPORT" "$STARTPORT" "$ENDPORT" "$IPV6" "$SYSTEM" "$DISK"
    echo "✅ 容器创建完成"
}

# -------------------------------
# 删除容器
# -------------------------------
remove_container() {
    read -p "请输入要删除的容器名称: " NAME
    if [ -z "$NAME" ]; then
        echo "❌ 容器名称不能为空"
        return
    fi

    echo "🗑 正在删除容器: $NAME ..."
    docker rm -f "$NAME" 2>/dev/null && echo "✅ 容器已删除" || echo "⚠️ 容器不存在"

    if [ -d "$NAME" ]; then
        echo "🗑 正在删除目录: $NAME ..."
        rm -rf "$NAME"
        echo "✅ 目录已删除"
    else
        echo "⚠️ 未找到目录 $NAME"
    fi
}

# -------------------------------
# 查询容器信息
# -------------------------------
query_container() {
    read -p "请输入要查询的容器名称: " NAME
    if [ -z "$NAME" ]; then
        echo "❌ 容器名称不能为空"
        return
    fi

    if [ -f "$NAME" ]; then
        echo "📋 容器 [$NAME] 的信息如下:"
        cat "$NAME"
    else
        echo "⚠️ 未找到容器 $NAME 的信息文件"
    fi
}

# -------------------------------
# 主菜单
# -------------------------------
while true; do
    clear
    echo -e "${green}==== Docker 容器管理 ======${reset}"
    echo -e "${green}1) 创建容器${reset}"
    echo -e "${green}2) 删除容器${reset}"
    echo -e "${green}3) 查询容器信息${reset}"
    echo -e "${green}0) 退出${reset}"
    read -r -p $'\033[32m请输入选项: \033[0m' choice

    case "$choice" in
        1) create_container ;;
        2) remove_container ;;
        3) query_container ;;
        0) exit 0 ;;
        *) echo " 无效选项，请重新输入" ;;
    esac
done
