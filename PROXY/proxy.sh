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
        10) bash <(curl -fsSL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/Xray2gsocks5.sh) ;;
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
    echo -e "${YELLOW}[07] Sing-box多用户与管理${RESET}"
    echo -e "${YELLOW}[08] SS-Xray-2go${RESET}"
    echo -e "${YELLOW}[09] vless-all-in-one${RESET}"
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
        07) wget -O sb.sh https://raw.githubusercontent.com/Tangfffyx/sing-box/main/sb.sh && bash sb.sh ;;
        08) bash <(curl -Ls https://raw.githubusercontent.com/Luckylos/xray-2go/refs/heads/main/xray_2go.sh) ;;
        09) wget -O vless-server.sh https://raw.githubusercontent.com/Zyx0rx/vless-all-in-one/main/vless-server.sh && chmod +x vless-server.sh && ./vless-server.sh ;;
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
    echo -e "${YELLOW}[16] Mihomo代理${RESET}"
    echo -e "${YELLOW}[17] Clash代理${RESET}"
    echo -e "${YELLOW}[18] FreeGFW代理${RESET}"
    echo -e "${YELLOW}[19] Remnawave${RESET}"
    echo -e "${YELLOW}[20] 3X-UICluster(多节点)${RESET}"
    echo -e "${YELLOW}[21] J-Board${RESET}"
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
        18) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/FreeGFW.sh) ; pause_return ;;
        19) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/RemnawaveGL.sh) ; pause_return ;;
        20) bash <(curl -Ls https://raw.githubusercontent.com/Copperchaleu/3x-ui-cluster/main/install.sh) ; pause_return ;;
        21) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/J-Board.sh) ; pause_return ;;
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
    echo -e "${YELLOW}[12] ForwardX端口转发${RESET}"
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
        12) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/ForwardX.sh) ; pause_return ;;
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
    echo -e "${YELLOW}[09] 甬哥-WARP${RESET}"
    echo -e "${YELLOW}[10] tun2socks${RESET}"
    echo -e "${YELLOW}[11] WARP面板${RESET}"
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
        11) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/WARPpanel.sh) ; pause_return ;;
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
    echo -e "${YELLOW}[07] DNS分流规则管理面板${RESET}"
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
        07) wget -O install.sh https://raw.githubusercontent.com/mslxi/Liquid-Glass-Prism-dns/main/install.sh && sudo bash install.sh ;;
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
    echo -e "${YELLOW}[08] VPS端口流量监控${RESET}"
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
        07) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/xtrafficdash.sh) ;;
        08) bash <(curl -fsSL https://raw.githubusercontent.com/156933/PortTrafficStatistics/main/install.sh) ;;
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
    if command -v sing-box &>/dev/null || pgrep -f sing-box &>/dev/null; then

        status=$(systemctl is-active sing-box 2>/dev/null)
        [[ "$status" != "active" && $(pgrep -f sing-box) ]] && status="active"

        echo -e "状态: $(format_status "$status")"

        if command -v sing-box &>/dev/null; then
            # Sing-box 的版本号获取通常在第 3 列
            ver=$(sing-box version 2>/dev/null | head -n1 | awk '{print $3}')
        else
            ver=$(ps -ef | grep sing-box | grep -v grep | grep -oE 'v[0-9.]+' | head -n1)
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        ports=$(get_ports sing-box)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Mihomo (Clash Meta)
    # =============================
    echo -e "${YELLOW}▶ Mihomo/Clash${RESET}"
    
    mihomo_found=0
    mi_ports=""

    # 1. 检测：系统命令、进程或 Docker (保持之前的逻辑)
    if command -v docker &>/dev/null; then
        mi_containers=$(docker ps -a --format "{{.Names}}" | grep -iE "mihomo|clash")
    fi

    if command -v mihomo &>/dev/null || pgrep -iE "mihomo|clash" &>/dev/null || [[ -n "$mi_containers" ]]; then
        mihomo_found=1
        
        # 状态判定
        status=$(systemctl is-active mihomo 2>/dev/null || systemctl is-active clash 2>/dev/null)
        if [[ "$status" != "active" ]]; then
            if pgrep -iE "mihomo|clash" &>/dev/null; then status="active"
            elif [[ -n "$mi_containers" ]]; then
                for name in $mi_containers; do
                    [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]] && status="active" && break
                done
            fi
        fi
        echo -e "状态: $(format_status "$status")"

        # 2. 版本获取优化 (核心修正点)
        # 获取第一行版本号，并检查是否含有 gvisor 关键字
        local raw_ver=""
        if command -v mihomo &>/dev/null; then
            raw_ver=$(mihomo -v 2>/dev/null)
        elif [[ -n "$mi_containers" ]]; then
            first_c=$(echo "$mi_containers" | head -n1)
            raw_ver=$(docker exec "$first_c" mihomo -v 2>/dev/null)
        fi

        if [[ -n "$raw_ver" ]]; then
            # 提取版本号 (v1.x.x)
            ver_num=$(echo "$raw_ver" | grep -iE "Mihomo|Clash" | awk '{print $3}' | head -n1)
            # 检查是否包含 gvisor 并做个简洁标记
            [[ "$raw_ver" == *"gvisor"* ]] && ver_num="${ver_num} (gVisor)"
            echo -e "版本: ${ver_num:-未知}"
        else
            echo -e "版本: 运行中(内置)"
        fi

        # 3. 端口获取
        mi_ports=$(get_ports mihomo; get_ports clash)
        if [[ -n "$mi_containers" ]]; then
            d_ports=$(docker container inspect $(echo "$mi_containers") --format '{{range $p, $conf := .NetworkSettings.Ports}}{{range $conf}}{{.HostPort}} {{end}}{{end}}' | tr -s ' ' '\n' | grep -v '^$')
            mi_ports="$mi_ports $d_ports"
        fi
        final_mi_ports=$(echo $mi_ports | tr ' ' '\n' | sort -un | tr '\n' ',' | sed 's/,$//')
        [[ -n "$final_mi_ports" ]] && echo -e "端口: ${GREEN}${final_mi_ports}${RESET}" || echo -e "端口: ${YELLOW}无${RESET}"

        # 4. 列出 Docker 容器
        if [[ -n "$mi_containers" ]]; then
            for name in $mi_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""
    # =============================
    # Realm
    # =============================
    echo -e "${YELLOW}▶ Realm${RESET}"
    
    # 查找 Docker 容器名包含 realm 的容器 ID (不区分大小写)
    realm_containers=""
    if command -v docker &>/dev/null; then
        realm_containers=$(docker ps -a --format "{{.Names}}" | grep -i "realm")
    fi

    # 1. 检测原生安装、进程或 Docker 容器
    if command -v realm &>/dev/null || pgrep -f realm &>/dev/null || [[ -n "$realm_containers" ]]; then

        status=$(systemctl is-active realm 2>/dev/null)
        # 如果 systemctl 没过，但进程在，或者 Docker 在运行，也算 active
        if [[ "$status" != "active" ]]; then
            if pgrep -f realm &>/dev/null; then
                status="active"
            elif [[ -n "$realm_containers" ]]; then
                # 检查是否有任一 realm 容器在运行
                for name in $realm_containers; do
                    if [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]]; then
                        status="active"
                        break
                    fi
                done
            fi
        fi

        echo -e "状态: $(format_status "$status")"

        # 版本获取
        if command -v realm &>/dev/null; then
            ver=$(realm --version 2>/dev/null | awk '{print $2}')
        elif [[ -n "$realm_containers" ]]; then
            # 尝试从第一个容器内提取版本
            first_c=$(echo "$realm_containers" | head -n1)
            ver=$(docker exec "$first_c" realm --version 2>/dev/null | awk '{print $2}')
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        # 端口获取
        ports=$(get_ports realm)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"

        # 如果有 Docker 容器，额外列出容器名 (保持简洁)
        if [[ -n "$realm_containers" ]]; then
            for name in $realm_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""


    # =============================
    # Gost 模块 (完整优化版)
    # =============================
    echo -e "${YELLOW}▶ Gost${RESET}"
    
    # 颜色变量定义 (确保脚本开头已定义，若无请取消下面注释)
    # YELLOW='\033[0;33m' && CYAN='\033[0;36m' && RED='\033[0;31m' && RESET='\033[0m'

    gost_containers=""
    if command -v docker &>/dev/null; then
        # 排除 grep 自身的干扰，精确获取容器名
        gost_containers=$(docker ps -a --format "{{.Names}}" | grep -i "gost")
    fi

    # 1. 综合检测：二进制文件、进程、或 Docker 容器
    if command -v gost &>/dev/null || pgrep -f gost &>/dev/null || [[ -n "$gost_containers" ]]; then

        status="inactive"
        # 优先级：Systemd > 进程 > Docker 运行状态
        if systemctl is-active gost &>/dev/null; then
            status="active"
        elif pgrep -f gost &>/dev/null; then
            status="active"
        elif [[ -n "$gost_containers" ]]; then
            for name in $gost_containers; do
                if [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]]; then
                    status="active"
                    break
                fi
            done
        fi

        echo -e "状态: $(format_status "$status")"

        # 2. 版本获取 (多重兼容逻辑)
        ver=""
        # 方式 A: 宿主机原生命令
        if command -v gost &>/dev/null; then
            ver=$(gost -V 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        fi
        
        # 方式 B: 如果宿主机没装或没取到，从 Docker 容器取
        if [[ -z "$ver" && -n "$gost_containers" ]]; then
            first_c=$(echo "$gost_containers" | head -n1)
            # 尝试容器内 gost -V
            ver=$(docker exec "$first_c" gost -V 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
            # 兼容 gostpanel 等特殊镜像路径
            [[ -z "$ver" ]] && ver=$(docker exec "$first_c" /bin/gost -V 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1)
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        # 3. 端口获取 (原生 + Docker 穿透)
        ports=$(get_ports gost)
        if [[ -n "$gost_containers" ]]; then
            # 抓取 Docker 映射端口并格式化清洗
            d_ports=$(docker container inspect $gost_containers --format '{{range $p, $conf := .NetworkSettings.Ports}}{{range $conf}}{{.HostPort}} {{end}}{{end}}' | tr ' ' '\n' | sed '/^$/d' | sort -u | tr '\n' ',' | sed 's/^,//;s/,$//')
            
            if [[ -n "$d_ports" ]]; then
                if [[ -n "$ports" ]]; then
                    ports="${ports},${d_ports}"
                else
                    ports="$d_ports"
                fi
            fi
        fi

        # 最终端口清洗输出
        final_ports=$(echo "$ports" | tr ' ' '\n' | tr ',' '\n' | sed '/^$/d' | sort -u | tr '\n' ',' | sed 's/,$//')
        [[ -n "$final_ports" ]] && echo -e "端口: ${CYAN}${final_ports}${RESET}" || echo -e "${YELLOW}端口: 无${RESET}"

        # 4. 细分容器详情显示
        if [[ -n "$gost_containers" ]]; then
            for name in $gost_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                # 统一显示为 active 或实际状态
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""



    # =============================
    # FRP (frpc/frps)
    # =============================
    echo -e "${YELLOW}▶ FRP${RESET}"
    
    # 查找 Docker 容器名包含 frp 的容器 (不区分大小写)
    frp_containers=""
    if command -v docker &>/dev/null; then
        frp_containers=$(docker ps -a --format "{{.Names}}" | grep -i "frp")
    fi

    # 1. 检测原生安装、进程或 Docker 容器
    if command -v frpc &>/dev/null || command -v frps &>/dev/null || pgrep -x frpc &>/dev/null || pgrep -x frps &>/dev/null || [[ -n "$frp_containers" ]]; then

        # 判定状态：优先看系统服务，其次看进程，最后看容器
        status=$(systemctl is-active frpc 2>/dev/null || systemctl is-active frps 2>/dev/null)
        if [[ "$status" != "active" ]]; then
            if pgrep -x frpc &>/dev/null || pgrep -x frps &>/dev/null; then
                status="active"
            elif [[ -n "$frp_containers" ]]; then
                for name in $frp_containers; do
                    if [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]]; then
                        status="active"
                        break
                    fi
                done
            fi
        fi

        echo -e "状态: $(format_status "$status")"

        # 版本获取逻辑
        if command -v frpc &>/dev/null; then
            ver=$(frpc -v 2>/dev/null)
        elif command -v frps &>/dev/null; then
            ver=$(frps -v 2>/dev/null)
        elif [[ -n "$frp_containers" ]]; then
            first_c=$(echo "$frp_containers" | head -n1)
            # 尝试在容器内分别测试 frpc 或 frps
            ver=$(docker exec "$first_c" frpc -v 2>/dev/null || docker exec "$first_c" frps -v 2>/dev/null)
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        # 端口获取
        ports=$( (get_ports frpc; get_ports frps) | sort -u )
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"

        # 如果有 Docker 容器，列出所有相关容器名
        if [[ -n "$frp_containers" ]]; then
            for name in $frp_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Nginx（本机 + Docker）
    # =============================
    echo -e "${YELLOW}▶ Nginx${RESET}"

    nginx_found=0
    all_ports=""

    # 1. 检测本机 Nginx
    if command -v nginx &>/dev/null; then
        nginx_found=1
        status=$(systemctl is-active nginx 2>/dev/null)
        [[ "$status" != "active" ]] && pgrep -x nginx &>/dev/null && status="active"
        
        echo -e "状态: $(format_status "$status")"
        ver=$(nginx -v 2>&1 | awk -F/ '{print $2}')
        echo -e "版本: ${ver:-内置}"

        all_ports=$(get_ports nginx)
    fi

    # 2. 检测 Docker Nginx (针对 NPM 做了优化)
    if command -v docker &>/dev/null; then
        # 匹配 nginx 或 npm 相关容器
        nginx_containers=$(docker ps -a --format "{{.Names}}" | grep -iE "nginx|npm")
        
        if [[ -n "$nginx_containers" ]]; then
            [[ $nginx_found -eq 0 ]] && echo -e "状态: ${GREEN}Docker 运行中${RESET}"
            nginx_found=1

            for name in $nginx_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"

                # 修正：更精准地提取宿主机 HostPort，并确保每个端口后有空格以便后续分割
                d_ports=$(docker container inspect "$name" --format '{{range $p, $conf := .NetworkSettings.Ports}}{{range $conf}}{{.HostPort}} {{end}}{{end}}' | tr -s ' ' '\n' | grep -v '^$')
                all_ports="$all_ports $d_ports"
            done
        fi
    fi

    # 3. 最终端口汇总显示
    if [[ $nginx_found -eq 1 ]]; then
        # 核心修正点：确保用换行符分割，再排序去重，最后用逗号连接
        final_ports=$(echo $all_ports | tr ' ' '\n' | grep -v '^$' | sort -un | tr '\n' ',' | sed 's/,$//')
        
        if [[ -n "$final_ports" ]]; then
            echo -e "端口: ${GREEN}${final_ports}${RESET}"
        else
            echo -e "端口: ${YELLOW}未发现映射端口${RESET}"
        fi
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""
    # =============================
    # Caddy
    # =============================
    echo -e "${YELLOW}▶ Caddy${RESET}"
    
    # 查找 Docker 容器 (不区分大小写)
    caddy_containers=""
    if command -v docker &>/dev/null; then
        caddy_containers=$(docker ps -a --format "{{.Names}}" | grep -i "caddy")
    fi

    if command -v caddy &>/dev/null || pgrep -x caddy &>/dev/null || [[ -n "$caddy_containers" ]]; then

        status=$(systemctl is-active caddy 2>/dev/null)
        if [[ "$status" != "active" ]]; then
            if pgrep -x caddy &>/dev/null; then
                status="active"
            elif [[ -n "$caddy_containers" ]]; then
                for name in $caddy_containers; do
                    if [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]]; then
                        status="active"
                        break
                    fi
                done
            fi
        fi

        echo -e "状态: $(format_status "$status")"

        # 版本获取：增加 awk 处理，只保留 v2.x.x
        if command -v caddy &>/dev/null; then
            ver=$(caddy version 2>/dev/null | awk '{print $1}')
        elif [[ -n "$caddy_containers" ]]; then
            first_c=$(echo "$caddy_containers" | head -n1)
            ver=$(docker exec "$first_c" caddy version 2>/dev/null | awk '{print $1}')
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        # 端口获取
        ports=$(get_ports caddy)
        [[ -n "$ports" ]] && echo -e "端口: $(echo $ports | tr ' ' ', ')" || echo -e "${YELLOW}端口: 无${RESET}"

        # Docker 容器列表
        if [[ -n "$caddy_containers" ]]; then
            for name in $caddy_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # ACME (acme.sh)
    # =============================
    echo -e "${YELLOW}▶ ACME${RESET}"
    # 检测原生二进制、家目录脚本或 Docker 容器
    if command -v acme.sh &>/dev/null || [[ -f ~/.acme.sh/acme.sh ]] || (command -v docker &>/dev/null && docker ps -a --format '{{.Names}}' | grep -qi "acme"); then
        
        # 确定状态
        if command -v acme.sh &>/dev/null || [[ -f ~/.acme.sh/acme.sh ]]; then
            echo -e "状态: ${GREEN}已安装${RESET}"
        else
            echo -e "状态: ${GREEN}已安装(Docker)${RESET}"
        fi

        # 版本获取逻辑：增加 grep 过滤掉 URL 干扰
        if command -v acme.sh &>/dev/null; then
            ver=$(acme.sh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        elif [[ -f ~/.acme.sh/acme.sh ]]; then
            ver=$(~/.acme.sh/acme.sh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        elif command -v docker &>/dev/null; then
            container_id=$(docker ps -a --format "{{.Names}}" | grep -i "acme" | head -n1)
            # 从容器内部提取版本，并过滤出纯数字版本号
            ver=$(docker exec "$container_id" acme.sh --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
        fi
        echo -e "版本: ${ver:-内置}"
        
    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""
    # =============================
    # CF WARP
    # =============================
    echo -e "${YELLOW}▶ Cloudflare WARP${RESET}"

    warp_found=0

    # 1. 官方 warp-cli
    if command -v warp-cli &>/dev/null; then
        warp_found=1
        if warp-cli status 2>/dev/null | grep -qi 'Connected'; then
            echo -e "状态: ${GREEN}已连接${RESET}"
        else
            echo -e "状态: ${YELLOW}已安装(未连接)${RESET}"
        fi
    fi
    
    # 2. WarpGo
    if command -v warp-go &>/dev/null || command -v warpgo &>/dev/null; then
        warp_found=1
        echo -e "状态: ${GREEN}WarpGo已安装${RESET}"
    fi

    if systemctl list-unit-files 2>/dev/null | grep -q warp-go; then
        warp_found=1
        if systemctl is-active warp-go &>/dev/null; then
            echo -e "状态: ${GREEN}WarpGo服务运行中${RESET}"
        else
            echo -e "状态: ${YELLOW}WarpGo已安装(未运行)${RESET}"
        fi
    fi

    # 3. WGCF
    if command -v wgcf &>/dev/null || ip a 2>/dev/null | grep -q 'wgcf'; then
        warp_found=1
        echo -e "状态: ${GREEN}WGCF已安装${RESET}"
    fi

    # 4. 官方服务进程
    if systemctl list-unit-files 2>/dev/null | grep -q warp-svc; then
        warp_found=1
        if systemctl is-active warp-svc &>/dev/null; then
            echo -e "状态: ${GREEN}服务运行中${RESET}"
        else
            echo -e "状态: ${YELLOW}服务已安装${RESET}"
        fi
    fi

    # 5. 其他快捷命令
    if command -v warp &>/dev/null; then
        warp_found=1
        if warp status 2>/dev/null | grep -q "WARP 网络接口已开启"; then
            echo -e "状态: ${GREEN}已开启${RESET}"
        else
            echo -e "状态: ${YELLOW}已安装${RESET}"
        fi
    fi

    # 6. Docker 模糊检测 (不区分大小写)
    if command -v docker &>/dev/null; then
        # 获取所有容器名，通过 grep -i 匹配包含 warp 的名称
        warp_containers=$(docker ps -a --format "{{.Names}}" | grep -i "warp")
        if [[ -n "$warp_containers" ]]; then
            warp_found=1
            for name in $warp_containers; do
                # 直接获取状态
                raw_status=$(docker inspect -f '{{.State.Status}}' "$name" 2>/dev/null)
                # 对 Docker 状态进行简单转换，确保 format_status 能识别
                [[ "$raw_status" == "running" ]] && c_status="active" || c_status="$raw_status"
                
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_status")"
            done
        fi
    fi

    # 网络模式检测
    if [[ $warp_found -eq 0 ]]; then
        # 只有在没有任何发现时才显示未安装
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
    # Cloudflare Tunnel (Argo)
    # =============================
    # 定义你脚本中的路径，假设 ${work_dir} 你已经全局定义了
    local argo_path="${work_dir}/argo"

    echo -e "${YELLOW}▶ Cloudflare Tunnel${RESET}"
    
    # 查找 Docker 容器 (保持模糊匹配)
    cf_containers=""
    if command -v docker &>/dev/null; then
        cf_containers=$(docker ps -a --format "{{.Names}}" | grep -iE "cloudflared|tunnel|argo")
    fi

    # 1. 检测：自定义路径文件、系统命令、进程或 Docker
    if [[ -f "$argo_path" ]] || command -v cloudflared &>/dev/null || pgrep -f "argo|cloudflared" &>/dev/null || [[ -n "$cf_containers" ]]; then

        status=$(systemctl is-active cloudflared 2>/dev/null || systemctl is-active argo 2>/dev/null)
        
        # 进程检测 (优先匹配你重命名后的 argo)
        if [[ "$status" != "active" ]]; then
            if pgrep -f "$argo_path" &>/dev/null || pgrep -f "cloudflared" &>/dev/null; then
                status="active"
            elif [[ -n "$cf_containers" ]]; then
                for name in $cf_containers; do
                    if [[ $(docker inspect -f '{{.State.Status}}' "$name") == "running" ]]; then
                        status="active"
                        break
                    fi
                done
            fi
        fi

        echo -e "状态: $(format_status "$status")"

        # 版本获取
        if [[ -f "$argo_path" ]]; then
            ver=$("$argo_path" --version 2>/dev/null | awk '{print $3}')
        elif command -v cloudflared &>/dev/null; then
            ver=$(cloudflared --version 2>/dev/null | awk '{print $3}')
        elif [[ -n "$cf_containers" ]]; then
            first_c=$(echo "$cf_containers" | head -n1)
            ver=$(docker exec "$first_c" cloudflared --version 2>/dev/null | awk '{print $3}')
        fi
        echo -e "版本: ${ver:-运行中(内置)}"

        # 如果有 Docker 容器，列出所有相关容器名
        if [[ -n "$cf_containers" ]]; then
            for name in $cf_containers; do
                raw_s=$(docker inspect -f '{{.State.Status}}' "$name")
                [[ "$raw_s" == "running" ]] && c_s="active" || c_s="$raw_s"
                echo -e "容器: ${CYAN}${name}${RESET} | 状态: $(format_status "$c_s")"
            done
        fi

    else
        echo -e "状态: ${RED}未安装${RESET}"
    fi
    echo ""

    # =============================
    # Docker
    # =============================
    echo -e "${YELLOW}▶ Docker${RESET}"

    if command -v docker &>/dev/null; then
        # Docker 已安装
        containers=$(docker ps --format "{{.Names}}" | grep -Ei 'xray|sing|hysteria|tuic|snell|3xui_app|AnyTLSD|MTProto|shadowsocks|sshadow-tls|shadow-tls|Singbox-AnyReality|Singbox-AnyTLS|Singbox-TUICv5|Xray-Reality|Xray-Realityxhttp|xray-socks5|xray-vmess|xray-vmesstls|clash|mihomo|warp|glash|conflux|heki|microwarp|nodepassdash|ppanel|wg-easy|wireguard|gostpanel|vite-frontend|xboard|xtrafficdash|lumina-client|freegfw|Mihomo|remnawave|forwardx-panel')

        if [[ -n "$containers" ]]; then
            echo -e "状态: ${GREEN}运行中${RESET}"
            echo -e "${YELLOW}容器:${RESET} $(echo "$containers" | tr '\n' ' ')"
        else
            echo -e "状态: ${GREEN}已安装${RESET}"
        fi
    else
        echo -e "状态: ${RED}未安装${RESET}"
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

    # 获取 IP
    ipv4=$(curl -4 -s --max-time 3 ip.sb 2>/dev/null || curl -4 -s --max-time 3 ifconfig.me 2>/dev/null)
    ipv6=$(curl -6 -s --max-time 3 ip.sb 2>/dev/null)

    get_country_cn() {
        local ip="$1"
        # 优先从 ip-api 获取中文名称
        local res=$(curl -s --max-time 3 "http://ip-api.com/json/$ip?lang=zh-CN")
        local name=$(echo "$res" | grep -oP '"country":"\K[^"]+')
        echo "${name:-未知}"
    }

    if [[ -n "$ipv4" ]]; then
        country4=$(get_country_cn "$ipv4")
        echo -e "IPv4: ${GREEN}$ipv4${RESET}         国家: ${GREEN}$country4${RESET}"
    else
        echo -e "IPv4: ${RED}获取失败${RESET}"
    fi

    if [[ -n "$ipv6" ]]; then
        country6=$(get_country_cn "$ipv6")
        echo -e "IPv6: ${GREEN}$ipv6${RESET}  国家: ${GREEN}$country6${RESET}"
    fi

    echo ""

    # =============================
    # DNS 检测
    # =============================
    echo -e "${YELLOW}▶ DNS 信息${RESET}"

    # 提取 DNS 地址
    dns_all=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}')
    dns_v4=$(echo "$dns_all" | grep -v ":" | tr '\n' ' ')
    dns_v6=$(echo "$dns_all" | grep ":" | tr '\n' ' ')

    # --- IPv4 DNS ---
    if [[ -n "$dns_v4" ]]; then
        echo -e "DNSv4: ${CYAN}${dns_v4}${RESET}"
        # 使用第一个 v4 DNS 测试解析 google.com
        test_v4=$(first_dns=$(echo $dns_v4 | awk '{print $1}'); dig +short +time=1 +tries=1 google.com @$first_dns >/dev/null 2>&1 && echo "ok" || echo "fail")
        if [[ "$test_v4" == "ok" ]]; then
            echo -e "解析: ${GREEN}IPv4 正常${RESET}"
        else
            echo -e "解析: ${RED}IPv4 失败或超时${RESET}"
        fi
    else
        echo -e "DNSv4: ${RED}无${RESET}"
    fi

    # --- IPv6 DNS (仅在存在时显示) ---
    if [[ -n "$dns_v6" ]]; then
        echo -e "DNSv6: ${CYAN}${dns_v6}${RESET}"
        # 使用第一个 v6 DNS 测试解析 google.com (AAAA)
        test_v6=$(first_dns6=$(echo $dns_v6 | awk '{print $1}'); dig +short +time=1 +tries=1 google.com AAAA @$first_dns6 >/dev/null 2>&1 && echo "ok" || echo "fail")
        if [[ "$test_v6" == "ok" ]]; then
            echo -e "解析: ${GREEN}IPv6 正常${RESET}"
        else
            echo -e "解析: ${RED}IPv6 失败或超时${RESET}"
        fi
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
    echo -e "${YELLOW}[09] 卸载 Realm${RESET}"
    echo -e "${YELLOW}[10] 卸载 GOST${RESET}"
    echo -e "${YELLOW}[11] 卸载 FRP${RESET}"
    echo -e "${YELLOW}[12] 卸载 CloudflareTunnel${RESET}"
    echo -e "${YELLOW}[13] 清理 Docke代理容器${RESET}"
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
        09) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/realmuninstall.sh) ; pause_return ;;
        10) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/gostuninstall.sh) ; pause_return ;;
        11) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/frpuninstall.sh) ; pause_return ;;
        12) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/cftunneluninstall.sh) ; pause_return ;;
        13) bash <(curl -sL https://raw.githubusercontent.com/sistarry/toolbox/main/PROXY/dockerprouninstall.sh) ; pause_return ;;
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
