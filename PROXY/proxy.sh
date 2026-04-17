#!/bin/bash
# ========================================
# 代理协议一键菜单（一级+二级分类版）
# 二级菜单 0 返回 | x 退出 | 自动补零 | 循环菜单
# ========================================

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
BLUE="\033[34m"
RESET="\033[0m"
BOLD="\033[1m"
ORANGE='\033[38;5;208m'

SCRIPT_PATH="/root/proxy.sh"
SCRIPT_URL="https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/proxy.sh"
BIN_LINK_DIR="/usr/local/bin"

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}请使用 root 权限运行！${RESET}"
    exit 1
fi

# =============================
# 首次运行自动安装
# =============================
if [ ! -f "$SCRIPT_PATH" ]; then
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    chmod +x "$SCRIPT_PATH"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/f"
    ln -sf "$SCRIPT_PATH" "$BIN_LINK_DIR/F"
    echo -e "${GREEN}✅ 安装完成${RESET}"
    echo -e "${GREEN}✅ 快捷键：F 或 f 可快速启动${RESET}"
fi

# =============================
# 自动补零
# =============================
format_choice() {
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        printf "%02d" "$1"
    else
        echo "$1"
    fi
}
# =============================
# 通用菜单读取（一级用）
# =============================
read_mainmenu() {
    echo -ne "${RED}请选择: ${RESET}"
    read choice

    choice=$(echo "$choice" | xargs)

    [[ "$choice" =~ ^[xX]$ ]] && exit 0
    [[ "$choice" == "0" || "$choice" == "00" ]] && exit 0

    choice=$(format_choice "$choice")
}

# =============================
# 通用二级菜单读取逻辑
# =============================
read_submenu() {
    echo -ne "${RED}选择: ${RESET}"
    read sub

    sub=$(echo "$sub" | xargs)

    [[ "$sub" =~ ^[xX]$ ]] && exit 0
    [[ "$sub" == "0" || "$sub" == "00" ]] && return 1

    sub=$(format_choice "$sub")
    return 0
}

pause_return() {
    read -p "$(echo -e ${GREEN}按回车返回菜单...${RESET})"
}
# =============================
# 一级菜单
# =============================
main_menu() {
    clear
    echo -e "${ORANGE}╔═════════════════════════╗${RESET}"
    echo -e "${ORANGE}  代理工具箱(快捷指令:F/f)  ${RESET}"
    echo -e "${ORANGE}╚═════════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] 单协议安装类${RESET}"
    echo -e "${YELLOW}[02] 多协议安装类${RESET}"
    echo -e "${YELLOW}[03] 面板管理类${RESET}"
    echo -e "${YELLOW}[04] 转发管理类${RESET}"
    echo -e "${YELLOW}[05] 组网管理类${RESET}"
    echo -e "${YELLOW}[06] 网络优化类${RESET}"
    echo -e "${YELLOW}[07] DNS 解锁类${RESET}"
    echo -e "${YELLOW}[08] Docker单协议类${RESET}"
    echo -e "${YELLOW}[09] Docker多协议类${RESET}"
    echo -e "${YELLOW}[10] 监控通知类${RESET}"
    echo -e "${YELLOW}[11] 核心状态检测${RESET}"
    echo -e "${YELLOW}[12] 核心卸载管理${RESET}"
    echo -e "${GREEN}[88] 更新脚本${RESET}"
    echo -e "${GREEN}[99] 卸载脚本${RESET}"
    echo -e "${YELLOW}[00] 退出${RESET}"

    read_mainmenu

    case "$choice" in
        01) protocol_menu ;;
        02) protocols_menu ;;
        03) panel_menu ;;
        04) zfpanel_menu ;;
        05) zwpanel_menu ;;
        06) network_menu ;;
        07) dns_menu ;;
        08) docker_menu ;;
        09) dockers_menu ;;
        10) monitor_menu ;;
        11) check_panel ; pause_return ;;
        12) uninstall_core_menu ;;
        88) update_script ; pause_return ;;
        99) uninstall_script ;;
        00) exit 0 ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
}

# =============================
# 单协议类
# =============================
protocol_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      单协议安装类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] Shadowsocks${RESET}"
    echo -e "${YELLOW}[02] Reality${RESET}"
    echo -e "${YELLOW}[03] Snell${RESET}"
    echo -e "${YELLOW}[04] Anytls${RESET}"
    echo -e "${YELLOW}[05] Hysteria2${RESET}"
    echo -e "${YELLOW}[06] Tuicv5${RESET}"
    echo -e "${YELLOW}[07] MTProto${RESET}"
    echo -e "${YELLOW}[08] Socks5${RESET}"
    echo -e "${YELLOW}[09] NaiveProxy${RESET}"
    echo -e "${YELLOW}[10] Xray-Argo${RESET}"
    echo -e "${YELLOW}[11] Vmess+ws${RESET}"
    echo -e "${YELLOW}[12] Vless+httpupgrade${RESET}"
    echo -e "${YELLOW}[13] VlessEncryption${RESET}"
    echo -e "${YELLOW}[14] VlessRealityxhttp${RESET}"
    echo -e "${YELLOW}[15] AnyReality${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"

    read_submenu || return

    case "$sub" in
        01) wget -O ss-rust.sh https://raw.githubusercontent.com/xOS/Shadowsocks-Rust/master/ss-rust.sh && bash ss-rust.sh ;;
        02) wget -qO /tmp/vlessreality.sh https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/vlessreality.sh && bash /tmp/vlessreality.sh ;;
        03) wget -O snell.sh --no-check-certificate https://git.io/Snell.sh && chmod +x snell.sh && ./snell.sh ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Anytls.sh) ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/GLHysteria2.sh) ;;
        06) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/tuicv5.sh) ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/GLMTProto.sh) ;;
        08) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Socks5.sh) ;;
        09) bash -c "$(curl -Ls https://raw.githubusercontent.com/dododook/NaiveProxy/refs/heads/main/install.sh?v=2)" ;;
        10) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Xray2go.sh) ;;
        11) wget -qO /tmp/Vmessws.sh https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Vmessws.sh && bash /tmp/Vmessws.sh ;;
        12) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Vlesshttpupgrade.sh) ;;
        13) wget -qO /tmp/VLESSEncryption.sh https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/VLESSEncryption.sh && bash /tmp/VLESSEncryption.sh ;;
        14) wget -qO /tmp/vlessrealityxhttp.sh https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/vlessrealityxhttp.sh && bash /tmp/vlessrealityxhttp.sh ;;
        15) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/singboxanyreality.sh) ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 多协议类
# =============================
protocols_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      多协议安装类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] 老王Sing-box${RESET}"
    echo -e "${YELLOW}[02] mack-a八合一${RESET}"
    echo -e "${YELLOW}[03] 甬哥-Sing-box${RESET}"
    echo -e "${YELLOW}[04] F佬-Sing-box${RESET}"
    echo -e "${YELLOW}[05] 233boy-Sing-box${RESET}"
    echo -e "${YELLOW}[06] SS+SNELL+Reality${RESET}"
    echo -e "${YELLOW}[07] SS-Xray-2go${RESET}"
    echo -e "${YELLOW}[08] vless-all-in-one${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"

    read_submenu || return

    case "$sub" in
        01) bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh) ;;
        02) wget -O install.sh https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh && bash install.sh ;;
        03) bash <(curl -Ls https://raw.githubusercontent.com/yonggekkk/sing-box-yg/main/sb.sh) ;;
        04) bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh) ;;
        05) bash <(wget -qO- -o- https://github.com/233boy/sing-box/raw/main/install.sh) ;;
        06) bash <(curl -L -s menu.jinqians.com) ;;
        07) bash <(curl -Ls https://raw.githubusercontent.com/Luckylos/xray-2go/refs/heads/main/xray_2go.sh) ;;
        08) wget -O vless-server.sh https://raw.githubusercontent.com/Zyx0rx/vless-all-in-one/main/vless-server.sh && chmod +x vless-server.sh && ./vless-server.sh ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 二级菜单：面板类
# =============================
panel_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      面板管理类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] S-UI${RESET}"
    echo -e "${YELLOW}[02] H-UI${RESET}"
    echo -e "${YELLOW}[03] X-UI${RESET}"
    echo -e "${YELLOW}[04] 甬哥-X-UI${RESET}"
    echo -e "${YELLOW}[05] 3X-UI${RESET}"
    echo -e "${YELLOW}[06] 中文版-3X-UI${RESET}"
    echo -e "${YELLOW}[07] Alpine-3X-UI${RESET}"
    echo -e "${YELLOW}[08] Docker-3X-UI${RESET}"
    echo -e "${YELLOW}[09] Xboard${RESET}"
    echo -e "${YELLOW}[10] XrayR 节点${RESET}"
    echo -e "${YELLOW}[11] heki 节点${RESET}"
    echo -e "${YELLOW}[12] DockerHeki${RESET}"
    echo -e "${YELLOW}[13] PPanel${RESET}"
    echo -e "${YELLOW}[14] PPanel(MSQL)${RESET}"
    echo -e "${YELLOW}[15] ppnode 节点${RESET}"
    echo -e "${YELLOW}[16] ConfluxMihomo代理${RESET}"
    echo -e "${YELLOW}[17] ClashDocker${RESET}"
    echo -e "${YELLOW}[18] FreeGFW${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return

    case "$sub" in
        01) bash <(curl -Ls https://raw.githubusercontent.com/alireza0/s-ui/master/install.sh) ; pause_return ;;
        02) bash <(curl -fsSL https://raw.githubusercontent.com/jonssonyan/h-ui/main/install.sh) ; pause_return ;;
        03) bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh) ; pause_return ;;
        04) bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/x-ui-yg/main/install.sh) ; pause_return ;;
        05) bash <(curl -fsSL https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) ; pause_return ;;
        06) bash <(curl -fsSL https://raw.githubusercontent.com/xeefei/3x-ui/master/install.sh) ; pause_return ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Alpine/3xuiAlpine.sh) ; pause_return ;;
        08) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/3X-UID.sh) ; pause_return ;;
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Xboard.sh) ; pause_return ;;
        10) wget -N https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh && bash install.sh ; pause_return ;;
        11) bash <(curl -Ls https://raw.githubusercontent.com/hekicore/heki/master/install.sh) ; pause_return ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/GLHeki.sh) ; pause_return ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/PPanelYC.sh) ; pause_return ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/PPanel.sh) ; pause_return ;;
        15) bash <(wget -qO- https://raw.githubusercontent.com/perfect-panel/ppanel-node/master/scripts/install.sh) ; pause_return ;;
        16) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Conflux.sh) ; pause_return ;;
        17) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ClashDocker.sh) ; pause_return ;;
        18) curl -fsSL https://raw.githubusercontent.com/haradakashiwa/freegfw/main/install.sh | bash ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 二级菜单：转发类
# =============================
zfpanel_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      转发管理类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] 极光面板${RESET}"
    echo -e "${YELLOW}[02] 哆啦A梦转发面板${RESET}"
    echo -e "${YELLOW}[03] EZGost安装${RESET}"
    echo -e "${YELLOW}[04] GOSTPanel${RESET}"
    echo -e "${YELLOW}[05] EZRealm安装${RESET}"
    echo -e "${YELLOW}[06] Realm-xwPF${RESET}"
    echo -e "${YELLOW}[07] ZelayRealm转发面板${RESET}"
    echo -e "${YELLOW}[08] Realm转发(Web面板)${RESET}"
    echo -e "${YELLOW}[09] NodePass${RESET}"
    echo -e "${YELLOW}[10] nftables端口转发${RESET}"
    echo -e "${YELLOW}[11] 哆啦A梦面板重制版${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return

    case "$sub" in
        01) bash <(curl -fsSL https://raw.githubusercontent.com/Aurora-Admin-Panel/deploy/main/install.sh) ; pause_return ;;
        02) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/dlam.sh) ; pause_return ;;
        03) wget --no-check-certificate -O gost.sh https://raw.githubusercontent.com/qqrrooty/EZgost/main/gost.sh && chmod +x gost.sh && ./gost.sh ; pause_return ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/GOSTPanel.sh) ; pause_return ;;
        05) wget -N https://raw.githubusercontent.com/qqrrooty/EZrealm/main/realm.sh && chmod +x realm.sh && ./realm.sh ; pause_return ;;
        06) wget -qO- https://raw.githubusercontent.com/zywe03/realm-xwPF/main/xwPF.sh | sudo bash -s install ; pause_return ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ZelayRealm.sh) ; pause_return ;;
        08) bash <(curl -fsSL https://raw.githubusercontent.com/hiapb/hia-realm/main/install.sh) ; pause_return ;;
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/NodePass.sh) ; pause_return ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/nftables.sh) ; pause_return ;;
        11) curl -fsSL https://raw.githubusercontent.com/0xNetuser/flux-panel/main/panel_install.sh -o panel_install.sh && chmod +x panel_install.sh && ./panel_install.sh ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 二级菜单：组网类
# =============================
zwpanel_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      组网管理类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] WireGuard${RESET}"
    echo -e "${YELLOW}[02] WG-Easy${RESET}"
    echo -e "${YELLOW}[03] Easytier组网${RESET}"
    echo -e "${YELLOW}[04] FRP-Panel(Web面板)${RESET}"
    echo -e "${YELLOW}[05] FRP工具(FRP服务端/客户端)${RESET}"
    echo -e "${YELLOW}[06] 安装FRP管理${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return
  

    case "$sub" in
        01) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/wireguard.sh) ; pause_return ;;
        02) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/WGEasy.sh) ; pause_return ;;
        03) bash <(curl -sL https://raw.githubusercontent.com/ceocok/c.cococ/refs/heads/main/easytier.sh) ; pause_return ;;
        04) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/frppanel.sh) ; pause_return ;;
        05) bash <(curl -fsSL https://raw.githubusercontent.com/nuro-hia/nuro-frp/main/install.sh) ; pause_return ;;
        06) wget -O frp.sh https://raw.githubusercontent.com/ceocok/c.cococ/main/frp.sh && chmod +x frp.sh && ./frp.sh ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}
# =============================
# 网络优化
# =============================
network_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      网络优化类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] WARP管理${RESET}"
    echo -e "${YELLOW}[02] TCP窗口调优${RESET}"
    echo -e "${YELLOW}[03] BBR管理${RESET}"
    echo -e "${YELLOW}[04] BBRv3优化${RESET}"
    echo -e "${YELLOW}[05] BBR+TCP智能调参${RESET}"
    echo -e "${YELLOW}[06] MicroWARP${RESET}"
    echo -e "${YELLOW}[07] IP屏蔽助手${RESET}"
    echo -e "${YELLOW}[08] 专线优化${RESET}"
    echo -e "${YELLOW}[09] warp-yg${RESET}"
    echo -e "${YELLOW}[10] tun2socks${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return

    case "$sub" in
        01) wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh ; pause_return ;;
        02) wget http://sh.nekoneko.cloud/tools.sh -O tools.sh && bash tools.sh ; pause_return ;;
        03) wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh && chmod +x tcpx.sh && ./tcpx.sh ; pause_return ;;
        04) bash <(curl -fsSL "https://raw.githubusercontent.com/Eric86777/vps-tcp-tune/main/install-alias.sh?$(date +%s)") ; pause_return ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/BBRTCP.sh) ; pause_return ;;
        06) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/MicroWarp.sh) ; pause_return ;;
        07) curl -fsSL https://raw.githubusercontent.com/Henry00123/china_blocker/main/china_blocker.sh -o china_blocker.sh && chmod +x china_blocker.sh && sudo ./china_blocker.sh ;;
        08) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/bbry.sh) ; pause_return ;;
        09) bash <(wget -qO- https://raw.githubusercontent.com/yonggekkk/warp-yg/main/CFwarp.sh) ; pause_return ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/tun2socks.sh) ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# DNS 类
# =============================
dns_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      DNS 解锁类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] DDNS${RESET}"
    echo -e "${YELLOW}[02] 自建DNS解锁${RESET}"
    echo -e "${YELLOW}[03] DnsmasqSNIproxy-One-click${RESET}"
    echo -e "${YELLOW}[04] 自定义DNS解锁${RESET}"
    echo -e "${YELLOW}[05] 谷歌分流Warp${RESET}"
    echo -e "${YELLOW}[06] 谷歌定位解锁${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return
   

    case "$sub" in
        01) bash <(wget -qO- https://raw.githubusercontent.com/mocchen/cssmeihua/mochen/shell/ddns.sh) ; pause_return ;;
        02) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/DNSjiesuo.sh) ; pause_return ;;
        03) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Dnsmasqsniproxy.sh) ; pause_return ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/VPS/unlockdns.sh) ; pause_return ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/vpsjk/warp-google/main/warp-google.sh) ; pause_return ;;
        06) bash <(curl -fsSL https://vpszdm.com/warp-google.sh) ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 二级菜单：Docker单协议类
# ===========================
docker_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      Docker单协议类     ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] SS2022${RESET}"
    echo -e "${YELLOW}[02] SS2022+TLS${RESET}"
    echo -e "${YELLOW}[03] Reality${RESET}"
    echo -e "${YELLOW}[04] Snell${RESET}"
    echo -e "${YELLOW}[05] Snell+TLS${RESET}"
    echo -e "${YELLOW}[06] Vmess+WS+TLS${RESET}"
    echo -e "${YELLOW}[07] Anytls${RESET}"
    echo -e "${YELLOW}[08] Hysteria2${RESET}"
    echo -e "${YELLOW}[09] Tuicv5${RESET}"
    echo -e "${YELLOW}[10] MTProto${RESET}"
    echo -e "${YELLOW}[11] Socks5${RESET}"
    echo -e "${YELLOW}[12] Vmess+WS${RESET}"
    echo -e "${YELLOW}[13] Realityxhttp${RESET}"
    echo -e "${YELLOW}[14] AnyReality${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return

    case "$sub" in
        01) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/SSRust2022D.sh) ; pause_return ;;
        02) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/SSRust-tlsD.sh) ; pause_return ;;
        03) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-RealityD.sh) ; pause_return ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/snell-serverD.sh) ; pause_return ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/snelltls-serverD.sh) ; pause_return ;;
        06) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-VmesswstlsD.sh) ; pause_return ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/AnyTLSD.sh) ; pause_return ;;
        08) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/hysteria2D.sh) ; pause_return ;;
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Singbox-TUICv5D.sh) ; pause_return ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/MTProtoD.sh) ; pause_return ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-Socks5D.sh) ; pause_return ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-VmesswsD.sh) ; pause_return ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-RealityxhttpD.sh) ; pause_return ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Singbox-AnyRealityD.sh) ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 二级菜单：Docker多协议类
# =============================
dockers_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      Docker多协议类     ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] SS2022${RESET}"
    echo -e "${YELLOW}[02] SS2022+TLS${RESET}"
    echo -e "${YELLOW}[03] Reality${RESET}"
    echo -e "${YELLOW}[04] Snell${RESET}"
    echo -e "${YELLOW}[05] Snell+TLS${RESET}"
    echo -e "${YELLOW}[06] Vmess+WS+TLS${RESET}"
    echo -e "${YELLOW}[07] Anytls${RESET}"
    echo -e "${YELLOW}[08] Hysteria2${RESET}"
    echo -e "${YELLOW}[09] Tuicv5${RESET}"
    echo -e "${YELLOW}[10] MTProto${RESET}"
    echo -e "${YELLOW}[11] Socks5${RESET}"
    echo -e "${YELLOW}[12] Vmess+WS${RESET}"
    echo -e "${YELLOW}[13] Realityxhttp${RESET}"
    echo -e "${YELLOW}[14] AnyReality${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return

    case "$sub" in
        01) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/SSRust2022GLD.sh) ; pause_return ;;
        02) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/SSRust-tlsGLD.sh) ; pause_return ;;
        03) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-RealityGLD.sh) ; pause_return ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/snell-serverGLD.sh) ; pause_return ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/snelltls-serverGLD.sh) ; pause_return ;;
        06) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-VmesswstlsGLD.sh) ; pause_return ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/AnyTLSGLD.sh) ; pause_return ;;
        08) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/hysteria2GLD.sh) ; pause_return ;;
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Singbox-TUICv5GLD.sh) ; pause_return ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/MTProtoGLD.sh) ; pause_return ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-Socks5GLD.sh) ; pause_return ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-VmesswsGLD.sh) ; pause_return ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Xray-RealityxhttpGLD.sh) ; pause_return ;;
        14) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Dockerproxy/Singbox-AnyRealityGLD.sh) ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}


# =============================
# 监控通知 类
# =============================
monitor_menu() {
while true; do
    clear
    echo -e "${ORANGE}╔══════════════════════╗${RESET}"
    echo -e "${ORANGE}      监控通知类        ${RESET}"
    echo -e "${ORANGE}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] IP-Sentinel${RESET}"
    echo -e "${YELLOW}[02] TrafficCop流量监控${RESET}"
    echo -e "${YELLOW}[03] VPS遥控器${RESET}"
    echo -e "${YELLOW}[04] vnstat${RESET}"
    echo -e "${YELLOW}[05] 流量狗${RESET}"
    echo -e "${YELLOW}[06] 阿里云CDT流量监控${RESET}"
    echo -e "${YELLOW}[07] 3XUI面板流量监控${RESET}"
    echo -e "${GREEN}[0]  返回${RESET}"
    echo -e "${GREEN}[x]  退出${RESET}"
    
    read_submenu || return
   

    case "$sub" in
        01) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/IPSentinel.sh) ;;
        02) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/toy/traffic.sh) ;;
        03) curl -fsSL https://raw.githubusercontent.com/MEILOI/VPS_BOT_X/main/vps_bot-x/install.sh -o install.sh && chmod +x install.sh && bash install.sh ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/vnStat.sh) ;;
        05) wget -O port-traffic-dog.sh https://raw.githubusercontent.com/zywe03/realm-xwPF/main/port-traffic-dog.sh && chmod +x port-traffic-dog.sh && ./port-traffic-dog.sh ;;
        06) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ECSController.sh) ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/Docker/xtrafficdash.sh) ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 核心状态检测
# =============================
check_panel() {
    clear
    echo -e "${ORANGE}╔══════════════════════════╗${RESET}"
    echo -e "${ORANGE}       核心状态检测          ${RESET}"
    echo -e "${ORANGE}╚══════════════════════════╝${RESET}"
    echo ""

    format_status() {
        case "$1" in
            active) echo -e "${GREEN}运行中${RESET}" ;;
            inactive|failed) echo -e "${YELLOW}未运行${RESET}" ;;
            *) echo -e "${RED}未安装${RESET}" ;;
        esac
    }

    get_ports() {
        ss -tulnp 2>/dev/null | grep -E "$1" | awk '{print $5}' | awk -F: '{print $NF}' | sort -u
    }

    # =============================
    # Xray
    # =============================
    echo -e "${YELLOW}▶ Xray${RESET}"
    if command -v xray &>/dev/null || pgrep -f xray &>/dev/null; then

        status=$(systemctl is-active xray 2>/dev/null)
        [[ "$status" != "active" && $(pgrep -f xray) ]] && status="active"

        echo -e "状态: $(format_status "$status")"

        if command -v xray &>/dev/null; then
            ver=$(xray version 2>/dev/null | head -n1 | awk '{print $2}')
        else
            ver=$(ps -ef | grep xray | grep -v grep | grep -oE 'v[0-9.]+' | head -n1)
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        ports=$(get_ports xray)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Sing-box
    # =============================
    echo -e "${YELLOW}▶ Sing-box${RESET}"
    if command -v sing-box &>/dev/null; then
        status=$(systemctl is-active sing-box 2>/dev/null)
        echo -e "状态: $(format_status "$status")"

        ver=$(sing-box version 2>/dev/null | head -n1 | awk '{print $3}')
        echo -e "版本: ${ver:-未知}"

        ports=$(get_ports sing-box)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Mihomo
    # =============================
    echo -e "${YELLOW}▶ Mihomo${RESET}"
    if command -v mihomo &>/dev/null || command -v clash &>/dev/null; then
        status=$(systemctl is-active mihomo 2>/dev/null || systemctl is-active clash 2>/dev/null)
        echo -e "状态: $(format_status "$status")"

        ver=$(mihomo -v 2>/dev/null | head -n1 || clash -v 2>/dev/null | head -n1)
        echo -e "版本: ${ver:-未知}"

        ports=$( (get_ports mihomo; get_ports clash) | sort -u )
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Nginx（本机 + Docker）
    # =============================
    echo -e "${YELLOW}▶ Nginx${RESET}"

    nginx_found=0

    if command -v nginx &>/dev/null; then
        nginx_found=1
        status=$(systemctl is-active nginx 2>/dev/null)
        echo -e "状态: $(format_status "$status")"

        ver=$(nginx -v 2>&1 | awk -F/ '{print $2}')
        echo -e "版本: ${ver:-未知}"

        ports=$(get_ports nginx)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')"
    fi

    if command -v docker &>/dev/null; then
        docker_nginx=$(docker ps --format "{{.Names}}" | grep -i nginx)
        if [[ -n "$docker_nginx" ]]; then
            nginx_found=1
            echo -e "Docker: ${GREEN}运行中${RESET} ($docker_nginx)"
        fi
    fi

    [[ $nginx_found -eq 0 ]] && echo -e "状态: ${RED}未安装${RESET}"
    echo ""

    # =============================
    # Caddy（本机 + Docker）
    # =============================
    echo -e "${YELLOW}▶ Caddy${RESET}"

    caddy_found=0

    if command -v caddy &>/dev/null; then
        caddy_found=1
        status=$(systemctl is-active caddy 2>/dev/null)
        echo -e "状态: $(format_status "$status")"

        ver=$(caddy version 2>/dev/null)
        echo -e "版本: ${ver:-未知}"

        ports=$(get_ports caddy)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')"
    fi

    if command -v docker &>/dev/null; then
        docker_caddy=$(docker ps --format "{{.Names}}" | grep -i caddy)
        if [[ -n "$docker_caddy" ]]; then
            caddy_found=1
            echo -e "Docker: ${GREEN}运行中${RESET} ($docker_caddy)"
        fi
    fi

    [[ $caddy_found -eq 0 ]] && echo -e "状态: ${RED}未安装${RESET}"
    echo ""

    # =============================
    # ACME（仅 acme.sh）
    # =============================
    echo -e "${YELLOW}▶ ACME${RESET}"
    if command -v acme.sh &>/dev/null || [[ -f ~/.acme.sh/acme.sh ]]; then
        echo -e "状态: ${GREEN}已安装${RESET}"

        if command -v acme.sh &>/dev/null; then
            ver=$(acme.sh --version 2>/dev/null | head -n1)
            echo -e "版本: ${ver:-未知}"
        fi
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # CF WARP
    # =============================
    echo -e "${YELLOW}▶ CF WARP${RESET}"

    warp_found=0

    if command -v warp-cli &>/dev/null; then
        warp_found=1
        if warp-cli status 2>/dev/null | grep -qi 'Connected'; then
            echo -e "状态: ${GREEN}已连接${RESET}"
        else
            echo -e "状态: ${YELLOW}已安装(未连接)${RESET}"
        fi
    fi

    if command -v wgcf &>/dev/null || ip a 2>/dev/null | grep -q 'wgcf'; then
        warp_found=1
        echo -e "状态: ${GREEN}WGCF已安装${RESET}"
    fi

    if systemctl list-unit-files 2>/dev/null | grep -q warp-svc; then
        warp_found=1
        if systemctl is-active warp-svc &>/dev/null; then
            echo -e "状态: ${GREEN}服务运行中${RESET}"
        else
            echo -e "状态: ${YELLOW}服务已安装${RESET}"
        fi
    fi

    if command -v warp &>/dev/null; then
        warp_found=1
        if warp status 2>/dev/null | grep -q "WARP 网络接口已开启"; then
            echo -e "状态: ${GREEN}已开启${RESET}"
        else
            echo -e "状态: ${YELLOW}已安装${RESET}"
        fi
    fi

    if [[ $warp_found -eq 0 ]]; then
        echo -e "状态: ${RED}未安装${RESET}"
    else
        trace=$(curl -s --max-time 2 https://www.cloudflare.com/cdn-cgi/trace)
        if echo "$trace" | grep -q "warp=on"; then
            echo -e "模式: ${GREEN}WARP中${RESET}"
        elif echo "$trace" | grep -q "warp=plus"; then
            echo -e "模式: ${GREEN}WARP+${RESET}"
        else
            echo -e "模式: ${YELLOW}普通网络${RESET}"
        fi
    fi
    echo ""



    # =============================
    # Docker
    # =============================
    echo -e "${YELLOW}▶ Docker${RESET}"
    if command -v docker &>/dev/null; then
        containers=$(docker ps --format "{{.Names}}" | grep -Ei 'xray|sing|hysteria|tuic|snell|3xui_app|AnyTLSD|MTProto|shadowsocks|sshadow-tls|shadow-tls|Singbox-AnyReality|Singbox-AnyTLS|Singbox-TUICv5|Xray-Reality|Xray-Realityxhttp|xray-socks5|xray-vmess|xray-vmesstls|clash|mihomo|warp|glash|conflux|heki|microwarp|nodepassdash|ppanel|wg-easy|wireguard|gostpanel|vite-frontend|xboard')
        if [[ -n "$containers" ]]; then
            echo -e "${GREEN}运行中:${RESET} $(echo $containers | tr '\n' ' ')"
        else
            echo -e "${GREEN}无相关容器${RESET}"
        fi
    else
        echo -e "${RED}未安装${RESET}"
    fi

    echo ""

    # =============================
    # BBR
    # =============================
    echo -e "${YELLOW}▶ BBR${RESET}"

    actual_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null)

    if [[ "$actual_cc" == "bbr" ]]; then
        echo -e "状态: ${GREEN}已启用 BBR${RESET}"
    else
        echo -e "状态: ${RED}未启用 BBR${RESET}"
    fi

    echo ""


    # =============================
    # 网络出口
    # =============================
    echo -e "${YELLOW}▶ 网络出口${RESET}"

    ipv4=$(curl -4 -s --max-time 3 ip.sb 2>/dev/null)
    [[ -z "$ipv4" ]] && ipv4=$(curl -4 -s --max-time 3 ifconfig.me 2>/dev/null)
    [[ -z "$ipv4" ]] && ipv4=$(curl -4 -s --max-time 3 ipv4.icanhazip.com 2>/dev/null)

    ipv6=$(curl -6 -s --max-time 3 ip.sb 2>/dev/null)

    get_country() {
        local ip="$1"
        local country=""

        country=$(curl -s --max-time 3 "https://ip.sb/geoip/$ip" | grep country_code | cut -d '"' -f4)
        [[ -z "$country" ]] && country=$(curl -s --max-time 3 "http://ip-api.com/line/$ip?fields=countryCode")
        [[ -z "$country" || "$country" == *"limit"* ]] && country=$(curl -s --max-time 3 "https://ipinfo.io/$ip/country")

        echo "${country:-未知}"
    }

    if [[ -n "$ipv4" ]]; then
        country=$(get_country "$ipv4")
        echo -e "IPv4: ${GREEN}$ipv4${RESET}  国家: ${GREEN}$country${RESET}"
    else
        echo -e "IPv4: ${RED}获取失败${RESET}"
    fi

    if [[ -n "$ipv6" ]]; then
        echo -e "IPv6: ${GREEN}$ipv6${RESET}"
    fi

    echo ""
    
}

# =============================
# 核心卸载菜单
# =============================
uninstall_core_menu() {
while true; do
    clear
    echo -e "${RED}╔══════════════════════╗${RESET}"
    echo -e "${RED}      核心卸载管理        ${RESET}"
    echo -e "${RED}╚══════════════════════╝${RESET}"
    echo -e "${YELLOW}[01] 卸载 Xray${RESET}"
    echo -e "${YELLOW}[02] 卸载 Sing-box${RESET}"
    echo -e "${YELLOW}[03] 卸载 Mihomo${RESET}"
    echo -e "${YELLOW}[04] 卸载 Nginx${RESET}"
    echo -e "${YELLOW}[05] 卸载 Caddy${RESET}"
    echo -e "${YELLOW}[06] 卸载 ACME证书${RESET}"
    echo -e "${YELLOW}[07] 卸载 WARP${RESET}"
    echo -e "${YELLOW}[08] 卸载 BBR${RESET}"
    echo -e "${YELLOW}[09] 清理 Docke代理容器${RESET}"
    echo -e "${GREEN}[0] 返回${RESET}"
    echo -e "${GREEN}[x] 退出${RESET}"

    read_submenu || return

    case "$sub" in
        01) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/xaryuninstall.sh) ; pause_return ;;
        02) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/singboxuninstall.sh) ; pause_return ;;
        03) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/mihomouninstall.sh) ; pause_return ;;
        04) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/nginxuninstall.sh) ; pause_return ;;
        05) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/caddyuninstall.sh) ; pause_return ;;
        06) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/acmeuninstall.sh) ; pause_return ;;
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/warpuninstall.sh) ; pause_return ;;
        08) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/bbruninstall.sh) ; pause_return ;;
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/dockerprouninstall.sh) ; pause_return ;;
        0) return ;;
        *) echo -e "${RED}无效选项${RESET}"; sleep 1 ;;
    esac
done
}

# =============================
# 更新 & 卸载
# =============================
update_script() {
    echo -e "${GREEN}更新中...${RESET}"
    curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    chmod +x "$SCRIPT_PATH"
    echo -e "${GREEN}✅ 更新完成!${RESET}"
    exec "$SCRIPT_PATH"
}

uninstall_script() {
    rm -f "$SCRIPT_PATH"
    rm -f "$BIN_LINK_DIR/F" "$BIN_LINK_DIR/f"
    echo -e "${RED}✅ 脚本已卸载${RESET}"
    exit 0
}

# =============================
# 主循环
# =============================
while true; do
    main_menu
done
