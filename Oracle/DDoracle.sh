#!/bin/bash

# 颜色定义
gl_lv="\e[32m"   # 绿色
gl_bai="\e[0m"    # 重置颜色

echo -e "${gl_lv}重装系统${gl_bai}"
echo -e "${gl_lv}--------------------------------${gl_bai}"
echo -e "${gl_lv}注意: ${GREEN}重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。${RESET}"

# 确认继续
echo -ne "${gl_lv}确定继续吗？(Y/N): ${gl_bai}"
read choice

case "$choice" in
[Yy])
    # 系统选择
    while true; do
        echo -e "${gl_lv}可选系统:${gl_bai}"
        echo -e "${gl_lv}1) Debian12${gl_bai}"
        echo -e "${gl_lv}2) Ubuntu20.04${gl_bai}"
        echo -ne "${gl_lv}请输入对应数字选择系统: ${gl_bai}"
        read sys_choice
        case "$sys_choice" in
        1)
            xitong="-d 12"
            system_name="Debian12"
            break
            ;;
        2)
            xitong="-u 20.04"
            system_name="Ubuntu20.04"
            break
            ;;
        *)
            echo -e "${gl_lv}无效的选择，请重新输入。${gl_bai}"
            ;;
        esac
    done

    # 密码输入（明文）
    echo -ne "${gl_lv}请输入你重装后的密码: ${gl_bai}"
    read vpspasswd
    echo

    # SSH端口
    echo -ne "${gl_lv}请输入 SSH 端口 (默认 22): ${gl_bai}"
    read ssh_port
    ssh_port=${ssh_port:-22}

    # 重装前确认
    echo -e "${gl_lv}--------------------------------${gl_bai}"
    echo -e "${gl_lv}请确认以下信息是否正确:${gl_bai}"
    echo -e "${gl_lv}系统: ${gl_bai}$system_name"
    echo -e "${gl_lv}密码: ${gl_bai}$vpspasswd"
    echo -e "${gl_lv}SSH端口: ${gl_bai}$ssh_port"
    echo -e "${gl_lv}--------------------------------${gl_bai}"

    echo -ne "${gl_lv}确认开始重装吗？(Y/N): ${gl_bai}"
    read confirm
    case "$confirm" in
    [Yy])
        # 安装 wget
        if ! command -v wget >/dev/null 2>&1; then
            echo -e "${gl_lv}正在安装 wget...${gl_bai}"
            if command -v apt >/dev/null 2>&1; then
                sudo apt update && sudo apt install -y wget
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y wget
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y wget
            elif command -v apk >/dev/null 2>&1; then
                sudo apk add wget
            else
                echo -e "${gl_lv}无法自动安装 wget，请手动安装${gl_bai}"
                exit 1
            fi
        fi

        echo -e "${gl_lv}开始重装系统，请耐心等待...${gl_bai}"
        gh_proxy=${gh_proxy:-""}  # 如果未定义，默认空
        bash <(wget --no-check-certificate -qO- "${gh_proxy}https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p "$vpspasswd" -port "$ssh_port"
        ;;
    *)
        echo -e "${gl_lv}已取消重装${gl_bai}"
        ;;
    esac
    ;;
*)
    echo -e "${gl_lv}已取消重装${gl_bai}"
    ;;
esac
