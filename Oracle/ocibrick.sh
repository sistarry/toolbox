#!/bin/bash

GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
RESET="\033[0m"

# 检查 root 权限
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}请使用 root 权限运行脚本${RESET}"
  exit 1
fi

# 脚本开头提示救援包信息
echo -e "${YELLOW}=== 可用救援包信息 ===${RESET}"
echo -e "${GREEN}1) Ubuntu 18.04 ARM 官方原版完整救援包${RESET}（用户名：root , 密码：CNBoy.org）"
echo -e "   下载命令: wget --no-check-certificate https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/ubuntu18.04.arm.img.gz"
echo -e "   恢复命令: gzip -dc /root/ubuntu18.04.arm.img.gz | dd of=/dev/sdb\n"

echo -e "${GREEN}2) Debian 10 ARM 网络精简救援包${RESET}（用户名：root , 密码：10086.fit）"
echo -e "   下载命令: wget --no-check-certificate https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/dabian10.arm.img.gz"
echo -e "   恢复命令: gzip -dc /root/dabian10.arm.img.gz | dd of=/dev/sdb\n"

echo -e "${GREEN}3) Ubuntu 20.04 AMD 官方原版完整救援包${RESET}（用户名：root , 密码：CNBoy.org）"
echo -e "   下载命令: wget --no-check-certificate https://github.com/honorcnboy/BlogDatas/releases/download/OracleRescueKit/ubuntu20.04.amd.img.gz"
echo -e "   恢复命令: gzip -dc /root/ubuntu20.04.amd.img.gz | dd of=/dev/sdb\n"

# 安装 curl 提示（不实际执行安装）
echo -e "${GREEN}提示：如果未安装 curl，可使用命令 'apt update -y && apt install -y curl' 安装${RESET}"
echo -e "${GREEN}注意: 进入工作区后使用 Ctrl+b 再按 d 退出${RESET}"
echo

# --- tmux 菜单脚本 ---
menu() {
    clear
    echo -e "${GREEN}=== 甲骨文救砖管理菜单 ===${RESET}"
    echo -e "${GREEN}1) 查看附加卷${RESET}"
    echo -e "${GREEN}2) 安装后台工具 (tmux)${RESET}"
    echo -e "${GREEN}3) 创建新的 tmux 工作区${RESET}"
    echo -e "${GREEN}4) 返回已有 tmux 工作区${RESET}"
    echo -e "${GREEN}0) 退出${RESET}"
    read -p $'\033[32m请选择操作: \033[0m' choice
    case $choice in
        1)
            echo -e "${GREEN}当前附加卷列表:${RESET}"
            lsblk
            pause
            ;;
        2)
            echo -e "${GREEN}正在安装后台工具 tmux...${RESET}"
            apt update -y && apt install -y tmux
            pause
            ;;
        3)
            echo -e "${GREEN}正在创建新的 tmux 工作区 my1...${RESET}"
            tmux new -s my1
            ;;
        4)
            echo -e "${GREEN}正在返回 tmux 工作区 my1...${RESET}"
            tmux attach-session -t my1
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${RED}无效选择，请重新输入${RESET}"
            sleep 1
            menu
            ;;
    esac
}

pause() {
    read -p $'\033[32m按回车键返回菜单...\033[0m'
    menu
}

menu
