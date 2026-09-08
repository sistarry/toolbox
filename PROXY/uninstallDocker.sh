#!/bin/bash

# 定义需要匹配的容器/镜像关键字列表
TARGETS=(
    "xray" "sing" "hysteria" "tuic" "snell" "3xui_app" "AnyTLSD" 
    "MTProto" "shadowsocks" "sshadow-tls" "shadow-tls" "Singbox-AnyReality" 
    "Singbox-AnyTLS" "Singbox-TUICv5" "Xray-Reality" "Xray-Realityxhttp" 
    "xray-socks5" "xray-vlesshttpupgrade" "xray-vmess" "mtg-proxy" 
    "xray-vmesstls" "clash" "mihomo" "warp" "microwarp" "easytier" 
    "ppanel-service" "wg-easy" "wireguard" "xboard" "xboard-node-1" 
    "miaomiaowux" "Mihomo" "remnawave" "remnawave-subscription-page" 
    "sui-traffic-reset" "forwardx-panel" "forwardxplus-panel" "frpp-master" 
    "frp-panel-server" "frp-panel-client" "relaypanel-panel" 
    "vite-frontend" "onebord" "nodepassdash"
)

# 颜色常量
YELLOW="\033[33m"
GREEN="\033[32m"
RED="\033[31m"
PLAIN="\033[0m"

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo -e "${RED}未检测到 Docker，请先安装 Docker。${PLAIN}"
    exit 1
fi

# 获取所有容器（格式: ID|名称|镜像）
containers_raw=$(docker ps -a --format "{{.ID}}|{{.Names}}|{{.Image}}")

if [ -z "$containers_raw" ]; then
    echo -e "${YELLOW}当前系统没有发现任何 Docker 容器。${PLAIN}"
    exit 0
fi

# 筛选匹配的容器
matched_containers=()
while IFS='|' read -r cid cname cimage; do
    for target in "${TARGETS[@]}"; do
        if [[ "${cname,,}" == *"${target,,}"* ]]; then
            matched_containers+=("$cid|$cname|$cimage")
            break
        fi
    done
done <<< "$containers_raw"

# 去重
matched_containers=($(printf "%s\n" "${matched_containers[@]}" | sort -u))

if [ ${#matched_containers[@]} -eq 0 ]; then
    echo -e "${YELLOW}没有找到代理容器。${PLAIN}"
    exit 0
fi

# 显示黄色菜单
echo -e "${YELLOW}========================================${PLAIN}"
echo -e "${YELLOW}       检测到以下已安装的代理容器       ${PLAIN}"
echo -e "${YELLOW}========================================${PLAIN}"

i=1
declare -A menu_map
for item in "${matched_containers[@]}"; do
    IFS='|' read -r cid cname cimage <<< "$item"
    menu_map[$i]="$cid|$cname|$cimage"
    echo -e "${GREEN} [$i] 容器名: $cname | 镜像: $cimage ${PLAIN}"
    ((i++))
done

echo -e "${YELLOW}========================================${PLAIN}"
echo -e "${YELLOW}操作说明:${PLAIN}"
echo -e "${YELLOW} - 输入编号多选，用空格隔开 (例如: 1 3 5)${PLAIN}"
echo -e "${YELLOW} - 输入 all 选择全部${PLAIN}"
echo -e "${YELLOW} - 输入 0 退出${PLAIN}"
echo -e "${YELLOW}========================================${PLAIN}"

read -p "$(echo -e "${GREEN}请选择要操作的容器编号: ${PLAIN}")" choice

if [ -z "$choice" ] || [ "$choice" == "0" ]; then
    echo -e "${YELLOW}操作已取消。${PLAIN}"
    exit 0
fi

selected_indices=()
if [ "$choice" == "all" ]; then
    for k in "${!menu_map[@]}"; do
        selected_indices+=("$k")
    done
else
    read -ra selected_indices <<< "$choice"
fi

# 执行删除（同时默认删除对应镜像，无需确认）
for idx in "${selected_indices[@]}"; do
    if [ -n "${menu_map[$idx]}" ]; then
        IFS='|' read -r cid cname cimage <<< "${menu_map[$idx]}"
        
        echo -e "正在处理容器: ${GREEN}$cname${PLAIN} (ID: $cid)"
        docker stop "$cid" 2>/dev/null
        docker rm "$cid" 2>/dev/null
        
        echo -e "正在删除关联镜像: ${GREEN}$cimage${PLAIN}"
        docker rmi "$cimage" 2>/dev/null || echo -e "${YELLOW}镜像 $cimage 可能被其他容器占用，跳过删除。${PLAIN}"
    fi
done

echo -e "${GREEN}所有选定的容器及镜像已清理完成！${PLAIN}"
