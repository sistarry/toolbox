#!/bin/bash

export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export HOME=/root

# ================== 配色 ==================
GREEN="\033[32m"
CYAN="\033[36m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

# ================== 全局变量 ==================
BASE_DIR="/opt/docker_backups"
SCRIPT_DIR="$BASE_DIR/scripts"
BACKUP_DIR="$BASE_DIR/data"
CONFIG_FILE="$BASE_DIR/config.sh"
LOG_FILE="$BASE_DIR/cron.log"
REMOTE_SCRIPT_PATH="$SCRIPT_DIR/remote_script.sh"
SSH_KEY="$HOME/.ssh/id_rsa_vpsbackup"
INSTALL_PATH="$(realpath "$0")"
CRON_TAG="#docker_backup_cron"
EXCLUDE_DIR_NAME="$(basename "$BASE_DIR")"

# ---------------------------
# 新增：配置需要扫描的 Docker 根目录列表
# ---------------------------
SEARCH_DIRS=(
    "/opt/1panel/apps"
    "/data"
    "/date"
    "/app"
    "/root"
    "/opt"
)

# 新增：GitHub 代理列表
GITHUB_PROXIES=(
    'https://v6.gh-proxy.org/'
    'https://ghfast.top/'
    'https://gh-proxy.com/'
    'https://hub.glowp.xyz/'
    'https://proxy.vvvv.ee/'
)

# 默认配置
RETAIN_DAYS_DEFAULT=7
TG_TOKEN_DEFAULT=""
TG_CHAT_ID_DEFAULT=""
SERVER_NAME_DEFAULT="$(hostname)"
REMOTE_USER_DEFAULT=""
REMOTE_IP_DEFAULT=""
REMOTE_DIR_DEFAULT="$BACKUP_DIR"

mkdir -p "$SCRIPT_DIR" "$BACKUP_DIR"

# ========================================
# 新增：不测速下载函数（直接轮询代理下载）
# ========================================
download_script() {
    local target_path=$1
    local output_path=$2
    local tmp_file=$(mktemp)

    echo -e "${YELLOW}📥 正在尝试直连...${RESET}"
    if curl -fsSL -m 5 "https://${target_path}" -o "$tmp_file"; then
        mv -f "$tmp_file" "$output_path"
        return 0
    fi

    # 直连失败，打乱代理顺序进行盲跑轮询
    local shuffled_indexes=($(shuf -i 0-$((${#GITHUB_PROXIES[@]} - 1))))
    for idx in "${shuffled_indexes[@]}"; do
        local proxy="${GITHUB_PROXIES[$idx]}"
        echo -e "${YELLOW}📥 直连未成功，正在通过代理: ${proxy}${RESET}"
        if curl -fsSL -m 8 "${proxy}https://${target_path}" -o "$tmp_file"; then
            mv -f "$tmp_file" "$output_path"
            return 0
        fi
    done

    rm -f "$tmp_file"
    return 1
}

# ================== 首次运行下载远程脚本 ==================
if [[ ! -f "$REMOTE_SCRIPT_PATH" ]]; then
    # 替换为代理轮询下载
    if ! download_script "raw.githubusercontent.com/sistarry/toolbox/main/Docker/Dockcompbauck.sh" "$REMOTE_SCRIPT_PATH"; then
        echo -e "${RED}❌ 安装失败，请检查网络${RESET}"
        exit 1
    fi
    chmod +x "$REMOTE_SCRIPT_PATH"
    exec "$REMOTE_SCRIPT_PATH"
fi

# ================== 配置加载/保存 ==================
load_config() {
    [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE"
    BACKUP_DIR=${BACKUP_DIR:-$BACKUP_DIR}
    RETAIN_DAYS=${RETAIN_DAYS:-$RETAIN_DAYS_DEFAULT}
    TG_TOKEN=${TG_TOKEN:-$TG_TOKEN_DEFAULT}
    TG_CHAT_ID=${TG_CHAT_ID:-$TG_CHAT_ID_DEFAULT}
    SERVER_NAME=${SERVER_NAME:-$SERVER_NAME_DEFAULT}
    REMOTE_USER=${REMOTE_USER:-$REMOTE_USER_DEFAULT}
    REMOTE_IP=${REMOTE_IP:-$REMOTE_IP_DEFAULT}
    REMOTE_DIR=${REMOTE_DIR:-$REMOTE_DIR_DEFAULT}
}

save_config() {
    mkdir -p "$(dirname "$CONFIG_FILE")"
    cat >"$CONFIG_FILE" <<EOF
BACKUP_DIR="$BACKUP_DIR"
RETAIN_DAYS="$RETAIN_DAYS"
TG_TOKEN="$TG_TOKEN"
TG_CHAT_ID="$TG_CHAT_ID"
SERVER_NAME="$SERVER_NAME"
REMOTE_USER="$REMOTE_USER"
REMOTE_IP="$REMOTE_IP"
REMOTE_DIR="$REMOTE_DIR"
EOF
    echo -e "${GREEN}✅ 配置已保存到 $CONFIG_FILE${RESET}"
}

load_config

# ================== Telegram通知 ==================
tg_send() {
    local MESSAGE="$1"
    [[ -z "$TG_TOKEN" || -z "$TG_CHAT_ID" ]] && return
    local SERVER=${SERVER_NAME:-localhost}
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        --data-urlencode "chat_id=$TG_CHAT_ID" \
        --data-urlencode "text=[$SERVER] $MESSAGE" >/dev/null 2>&1
}

# ================== SSH密钥自动生成 ==================
setup_ssh_key() {
    if [[ ! -f "$SSH_KEY" ]]; then
        echo -e "${CYAN}🔑 生成 SSH 密钥...${RESET}"
        ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N ""
        echo -e "${GREEN}✅ 密钥生成完成: $SSH_KEY${RESET}"
    fi

    read -rp "$(echo -e "${GREEN}请输入远程用户名（默认 root）: ${RESET}")" username
    username=${username:-root}

    read -rp "$(echo -e "${GREEN}请输入远程服务器 IP: ${RESET}")" ip_address
    if [ -z "$ip_address" ]; then
        echo -e "${RED}❌ 错误: 服务器 IP 不能为空！${RESET}"
        return 1
    fi

    read -rp "$(echo -e "${GREEN}请输入SSH端口（默认 22）: ${RESET}")" port
    port=${port:-22}

    echo -e "${CYAN}🚀 正在将公钥部署到远程服务器 ${username}@${ip_address}:${port} ...${RESET}"
    
    ssh-copy-id -i "$SSH_KEY.pub" -p "$port" -o StrictHostKeyChecking=no "${username}@${ip_address}"

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ 密钥已成功部署到远程: ${username}@${ip_address}:${port}${RESET}"
        REMOTE_USER="$username"
        REMOTE_IP="$ip_address"
        save_config
    else
        echo -e "${RED}❌ 密钥部署失败，请检查网络或密码是否正确。${RESET}"
    fi
}

# ========================================
# 新增：动态扫描支持的 Docker 项目
# ========================================
scan_projects() {
    PROJECT_NAMES=()
    PROJECT_PATHS=()
    
    for s_dir in "${SEARCH_DIRS[@]}"; do
        if [ -d "$s_dir" ]; then
            local base_search_dir=$(readlink -f "$s_dir")
            
            while IFS= read -r compose_file; do
                [ -z "$compose_file" ] && continue
                
                local full_compose_path=$(readlink -f "$compose_file")
                local app_path=$(dirname "$full_compose_path")
                local app_name=""
                
                if [ "$app_path" == "$base_search_dir" ]; then
                    app_name=$(basename "$base_search_dir")
                else
                    app_name=$(basename "$app_path")
                fi
                
                PROJECT_NAMES+=("$app_name")
                PROJECT_PATHS+=("$app_path")
            done < <(find "$base_search_dir" -maxdepth 5 \( -name "docker-compose.yml" -o -name "docker-compose.yaml" \) 2>/dev/null | sort -u)
        fi
    done
}

# ================== 本地备份（已重构为编号选择模式） ==================
backup_local() {
    scan_projects
    if [ ${#PROJECT_PATHS[@]} -eq 0 ]; then
        echo -e "${RED}❌ 未找到任何符合条件的 Docker 目录。${RESET}"
        return
    fi

    clear
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}        📂 请选择需要备份的项目       ${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    for i in "${!PROJECT_PATHS[@]}"; do
        echo -e "${YELLOW}$((i+1))) ${PROJECT_NAMES[$i]}${RESET}"
    done
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}all) 备份上面所有项目${RESET}"
    echo -e "${GREEN}  0) 返回${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    
    read -rp "$(echo -e "${GREEN}请输入项目编号（支持空格分隔多个，或输入 all）: ${RESET}")" SELECTION

    [[ "$SELECTION" == "0" || -z "$SELECTION" ]] && return

    TARGET_PATHS=()
    TARGET_NAMES=()

    if [[ "$SELECTION" == "all" ]]; then
        TARGET_PATHS=("${PROJECT_PATHS[@]}")
        TARGET_NAMES=("${PROJECT_NAMES[@]}")
    else
        for num in $SELECTION; do
            if [[ $num =~ ^[0-9]+$ ]] && (( num>=1 && num<=${#PROJECT_PATHS[@]} )); then
                local idx=$((num-1))
                TARGET_PATHS+=("${PROJECT_PATHS[$idx]}")
                TARGET_NAMES+=("${PROJECT_NAMES[$idx]}")
            else
                echo -e "${RED}❌ 无效序号: $num 将被跳过${RESET}"
            fi
        done
    fi

    [[ ${#TARGET_PATHS[@]} -eq 0 ]] && { echo -e "${RED}❌ 未选择任何有效项目${RESET}"; return; }

    mkdir -p "$BACKUP_DIR"
    for i in "${!TARGET_PATHS[@]}"; do
        local PROJECT_DIR="${TARGET_PATHS[$i]}"
        local PROJECT_NAME="${TARGET_NAMES[$i]}"

        local compose_file=""
        if [[ -f "$PROJECT_DIR/docker-compose.yml" ]]; then
            compose_file="$PROJECT_DIR/docker-compose.yml"
        elif [[ -f "$PROJECT_DIR/docker-compose.yaml" ]]; then
            compose_file="$PROJECT_DIR/docker-compose.yaml"
        fi

        if [[ -n "$compose_file" ]]; then
            echo -e "${CYAN}⏸️ 暂停容器: $PROJECT_NAME${RESET}"
            cd "$PROJECT_DIR" || continue
            docker compose down
        fi

        TIMESTAMP=$(date +%F_%H-%M-%S)
        BACKUP_FILE="$BACKUP_DIR/${PROJECT_NAME}_backup_$TIMESTAMP.tar.gz"
        echo -e "${CYAN}📦 正在备份 $PROJECT_NAME → $BACKUP_FILE${RESET}"
        
        tar czf "$BACKUP_FILE" \
            --exclude="$EXCLUDE_DIR_NAME" \
            -C "$PROJECT_DIR" .

        if [[ -n "$compose_file" ]]; then
            echo -e "${CYAN}🚀 启动容器: $PROJECT_NAME${RESET}"
            cd "$PROJECT_DIR" || continue
            docker compose up -d
        fi

        echo -e "${GREEN}✅ 本地备份完成: $BACKUP_FILE${RESET}"
        tg_send "本地备份完成: $PROJECT_NAME"
    done

    find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +"$RETAIN_DAYS" -exec rm -f {} \;
    tg_send "🗑️ 已清理 $RETAIN_DAYS 天以上旧备份"
}

# ================== 远程上传 ==================
backup_remote_all() {
    [[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}❌ 本地备份目录不存在: $BACKUP_DIR${RESET}"; return; }

    FILE_LIST=("$BACKUP_DIR"/*.tar.gz)
    [[ ${#FILE_LIST[@]} -eq 0 ]] && { echo -e "${RED}❌ 没有备份文件${RESET}"; return; }

    echo -e "${CYAN}📤 上传所有备份文件到远程: $REMOTE_USER@$REMOTE_IP:$REMOTE_DIR${RESET}"

    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$REMOTE_USER@$REMOTE_IP" "mkdir -p \"$REMOTE_DIR\" && rm -f \"$REMOTE_DIR\"/*.tar.gz"

    for FILE in "${FILE_LIST[@]}"; do
        scp -i "$SSH_KEY" "$FILE" "$REMOTE_USER@$REMOTE_IP:$REMOTE_DIR/" >> "$LOG_FILE" 2>&1
        tg_send "备份上传完成: $(basename "$FILE") → $REMOTE_IP"
    done

    echo -e "${GREEN}✅ 所有备份文件上传完成${RESET}"
}

# ================== 恢复 ==================
restore() {
    read -rp "请输入备份存放目录（默认 $BACKUP_DIR）: " INPUT_DIR
    BACKUP_DIR=${INPUT_DIR:-$BACKUP_DIR}

    [[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}❌ 目录不存在: $BACKUP_DIR${RESET}"; return; }
    FILE_LIST=("$BACKUP_DIR"/*.tar.gz)
    [[ ${#FILE_LIST[@]} -eq 0 ]] && { echo -e "${RED}❌ 没有找到任何备份文件${RESET}"; return; }

    echo -e "${CYAN}📂 本地备份文件列表:${RESET}"
    for i in "${!FILE_LIST[@]}"; do
        echo -e "${GREEN}$((i+1)). $(basename "${FILE_LIST[$i]}")${RESET}"
    done

    read -rp "请输入要恢复的序号（空格分隔，all 全选，latest 最新备份）: " SELECTION
    BACKUP_FILES=()
    if [[ "$SELECTION" == "all" ]]; then
        BACKUP_FILES=("${FILE_LIST[@]}")
    elif [[ "$SELECTION" == "latest" ]]; then
        BACKUP_FILES=($(ls -t "$BACKUP_DIR"/*.tar.gz | head -n1))
    else
        for num in $SELECTION; do
            [[ $num =~ ^[0-9]+$ ]] && (( num>=1 && num<=${#FILE_LIST[@]} )) && BACKUP_FILES+=("${FILE_LIST[$((num-1))]}") || echo -e "${RED}❌ 无效序号: $num${RESET}"
        done
    fi
    [[ ${#BACKUP_FILES[@]} -eq 0 ]] && { echo -e "${RED}❌ 没有选择有效文件${RESET}"; return; }

    read -rp "请输入恢复到的项目目录（默认 /opt/原项目名）: " PROJECT_DIR_INPUT
    for FILE in "${BACKUP_FILES[@]}"; do
        BASE_NAME=$(basename "$FILE" | sed 's/_backup_.*\.tar\.gz//')
        TARGET_DIR=${PROJECT_DIR_INPUT:-/opt/$BASE_NAME}
        mkdir -p "$TARGET_DIR"

        echo -e "${CYAN}📂 解压备份 $(basename "$FILE") → $TARGET_DIR${RESET}"
        tar xzf "$FILE" -C "$TARGET_DIR"

        if [[ -f "$TARGET_DIR/docker-compose.yml" ]] || [[ -f "$TARGET_DIR/docker-compose.yaml" ]]; then
            echo -e "${CYAN}🚀 启动容器...${RESET}"
            cd "$TARGET_DIR" || continue
            docker compose up -d
            echo -e "${GREEN}✅ 恢复完成: $TARGET_DIR${RESET}"
            tg_send "恢复完成: $BASE_NAME → $TARGET_DIR"
        else
            echo -e "${RED}❌ docker-compose 文件不存在，无法启动容器${RESET}"
        fi
    done
}

# ================== 配置菜单 ==================
configure_settings_menu() {
    load_config
    while true; do
        clear
        echo -e "${GREEN}====================================${RESET}"
        echo -e "${GREEN}      ◈       配置设置       ◈    ${RESET}"
        echo -e "${GREEN}====================================${RESET}"
        echo -e "${GREEN}1. Telegram Bot Token (当前:${RESET} ${YELLOW}$TG_TOKEN${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}2. Telegram Chat ID (当前:${RESET} ${YELLOW}$TG_CHAT_ID${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}3. 服务器名称 (当前:${RESET} ${YELLOW}$SERVER_NAME${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}4. 本地备份保留天数 (当前:${RESET} ${YELLOW}$RETAIN_DAYS${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}5. 本地备份目录 (当前:${RESET} ${YELLOW}$BACKUP_DIR${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}6. 远程服务器用户名 (当前:${RESET} ${YELLOW}$REMOTE_USER${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}7. 远程服务器 IP (当前:${RESET} ${YELLOW}$REMOTE_IP${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}8. 远程备份目录 (当前:${RESET} ${YELLOW}$REMOTE_DIR${RESET}${GREEN})${RESET}"
        echo -e "${GREEN}0. 返回上级菜单${RESET}"
        echo -e "${GREEN}====================================${RESET}"
        read -rp "$(echo -e "${GREEN}请选择操作: ${RESET}")" choice
        case $choice in
            1) read -rp "请输入 Telegram Bot Token: " input; [[ -n "$input" ]] && TG_TOKEN="$input" ;;
            2) read -rp "请输入 Telegram Chat ID: " input; [[ -n "$input" ]] && TG_CHAT_ID="$input" ;;
            3) read -rp "请输入服务器名称: " input; [[ -n "$input" ]] && SERVER_NAME="$input" ;;
            4) read -rp "请输入本地备份保留天数: " input; [[ -n "$input" ]] && RETAIN_DAYS="$input" ;;
            5) read -rp "请输入本地备份目录: " input; [[ -n "$input" ]] && BACKUP_DIR="$input" ;;
            6) read -rp "请输入远程服务器用户名: " input; [[ -n "$input" ]] && REMOTE_USER="$input" ;;
            7) read -rp "请输入远程服务器 IP: " input; [[ -n "$input" ]] && REMOTE_IP="$input" ;;
            8) read -rp "请输入远程备份目录: " input; [[ -n "$input" ]] && REMOTE_DIR="$input" ;;
            0) save_config; load_config; break ;;
            *) echo -e "${RED}❌ 无效选择${RESET}" ;;
        esac
        save_config
        load_config
        read -rp "$(echo -e "${GREEN}按回车继续...${RESET}")"
    done
}

# ================== 定时任务管理 ==================
list_cron() {
    mapfile -t lines < <(crontab -l 2>/dev/null | grep "$CRON_TAG")
    [ ${#lines[@]} -eq 0 ] && { echo -e "${YELLOW}暂无定时任务${RESET}"; return; }
    for i in "${!lines[@]}"; do
        cron=$(echo "${lines[$i]}" | sed "s|$INSTALL_PATH auto||;s|$CRON_TAG||")
        echo "$i) $cron"
    done
}

schedule_add() {
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}1. 每天0点${RESET}"
    echo -e "${GREEN}2. 每周一0点${RESET}"
    echo -e "${GREEN}3. 每月1号0点${RESET}"
    echo -e "${GREEN}4. 自定义cron${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    read -rp "$(echo -e "${GREEN}选择: ${RESET}")" t
    case $t in
        1) cron_expr="0 0 * * *" ;;
        2) cron_expr="0 0 * * 1" ;;
        3) cron_expr="0 0 1 * *" ;;
        4) read -p "请输入自定义 cron 表达式: " cron_expr ;;
        *) echo -e "${RED}❌ 无效选择${RESET}"; return ;;
    esac

    read -p "备份目录(空格分隔, 留空使用默认 $BACKUP_DIR): " dirs
    [[ -z "$dirs" ]] && dirs="$BACKUP_DIR"

    (crontab -l 2>/dev/null; \
    echo "$cron_expr /bin/bash \"$INSTALL_PATH\" auto \"$dirs\" >> \"$LOG_FILE\" 2>&1 $CRON_TAG") | crontab -
    echo -e "${GREEN}✅ 添加成功，cron 日志: $LOG_FILE${RESET}"
}

schedule_del_one() {
    mapfile -t lines < <(crontab -l 2>/dev/null | grep "$CRON_TAG")
    [ ${#lines[@]} -eq 0 ] && { echo -e "${YELLOW}暂无定时任务${RESET}"; return; }
    list_cron
    read -p "输入要删除的编号: " idx
    unset 'lines[idx]'
    (crontab -l 2>/dev/null | grep -v "$CRON_TAG"; for l in "${lines[@]}"; do echo "$l"; done) | crontab -
    echo -e "${GREEN}✅ 已删除${RESET}"
}

schedule_del_all() {
    crontab -l 2>/dev/null | grep -v "$CRON_TAG" | crontab -
    echo -e "${GREEN}✅ 已清空全部定时任务${RESET}"
}

schedule_menu() {
    while true; do
        clear
        echo -e "${GREEN}====================================${RESET}"
        echo -e "${GREEN}        ◈    定时任务管理    ◈       ${RESET}"
        echo -e "${GREEN}====================================${RESET}"
        echo -e "${GREEN}------------------------------------${RESET}"
        list_cron
        echo -e "${GREEN}------------------------------------${RESET}"
        echo -e "${GREEN}1. 添加任务${RESET}"
        echo -e "${GREEN}2. 删除任务${RESET}"
        echo -e "${GREEN}3. 清空全部${RESET}"
        echo -e "${GREEN}0. 返回${RESET}"
        echo -e "${GREEN}====================================${RESET}"
        read -p "$(echo -e "${GREEN}请选择:${RESET} ")" choice
        case $choice in
            1) schedule_add ;;
            2) schedule_del_one ;;
            3) schedule_del_all ;;
            0) break ;;
            *) echo -e "${RED}❌ 无效选择${RESET}" ;;
        esac
        read -rp "$(echo -e "${GREEN}按回车继续...${RESET}")"
    done
}

# ================== 卸载 ==================
uninstall() {
    echo -e "${YELLOW}正在彻底卸载...${RESET}"
    [[ -f "$CONFIG_FILE" ]] && rm -f "$CONFIG_FILE" && echo -e "${GREEN}✅ 配置文件已删除${RESET}"
    [[ -f "$REMOTE_SCRIPT_PATH" ]] && rm -f "$REMOTE_SCRIPT_PATH" && echo -e "${GREEN}✅ 文件已删除${RESET}"
    crontab -l 2>/dev/null | grep -v -E "($INSTALL_PATH|$CRON_TAG)" | crontab -
    [[ -d "$BASE_DIR" ]] && rm -rf "$BASE_DIR" && echo -e "${GREEN}✅ 本地备份目录已删除${RESET}"
    [[ -f "$SSH_KEY" ]] && rm -f "$SSH_KEY" "$SSH_KEY.pub" && echo -e "${GREEN}✅ SSH 密钥已删除: $SSH_KEY${RESET}"
    echo -e "${GREEN}✅ 卸载完成，所有文件和定时任务已清理干净${RESET}"
    exit 0
}

# ================== auto模式 ==================
if [[ "$1" == "auto" ]]; then
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    export HOME=/root
    load_config
    mkdir -p "$BACKUP_DIR"

    DIRS=()
    [[ -n "$2" ]] && IFS=' ' read -r -a DIRS <<< "$2"
    [[ ${#DIRS[@]} -eq 0 ]] && DIRS=("$BACKUP_DIR")

    for PROJECT_DIR in "${DIRS[@]}"; do
        [[ ! -d "$PROJECT_DIR" ]] && continue
        TIMESTAMP=$(date +%F_%H-%M-%S)
        
        # 兼容获取项目名称
        local P_NAME=$(basename "$PROJECT_DIR")
        local BACKUP_FILE="$BACKUP_DIR/${P_NAME}_backup_$TIMESTAMP.tar.gz"
        
        tar czf "$BACKUP_FILE" \
            --exclude="$EXCLUDE_DIR_NAME" \
            -C "$PROJECT_DIR" . >> "$LOG_FILE" 2>&1
        tg_send "自动备份完成: ${P_NAME} → $BACKUP_FILE"
    done

    find "$BACKUP_DIR" -type f -name "*.tar.gz" -mtime +"$RETAIN_DAYS" -exec rm -f {} \;
    tg_send "🗑️ 自动清理 $RETAIN_DAYS 天以上旧备份"

    if [[ -n "$REMOTE_USER" && -n "$REMOTE_IP" ]]; then
        backup_remote_all
    fi

    exit 0
fi

# ================== 主菜单 ==================
while true; do
    load_config
    clear

    if crontab -l 2>/dev/null | grep -q "$CRON_TAG"; then
        CRON_STATUS="${YELLOW}已开启${RESET}"
    else
        CRON_STATUS="${RED}已关闭${RESET}"
    fi

    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}  ◈ Docker compose 备份恢复管理 ◈   ${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN} 📂 当前备份目录: ${YELLOW}$BACKUP_DIR${RESET}"
    echo -e "${GREEN} ⏳  备份保留天数: ${YELLOW}$RETAIN_DAYS 天${RESET}"
    echo -e "${GREEN} ⏰  定时任务状态: $CRON_STATUS${RESET}"
    echo -e "${GREEN}====================================${RESET}"
    echo -e "${GREEN}1. 本地备份${RESET}"
    echo -e "${GREEN}2. 恢复项目${RESET}"
    echo -e "${GREEN}3. 设置SSH密钥自动登录${RESET}"
    echo -e "${GREEN}4. 配置设置（通知/保留天数/目录/远程信息）${RESET}"
    echo -e "${GREEN}5. 远程备份${RESET}"
    echo -e "${GREEN}6. 定时任务管理${RESET}"
    echo -e "${GREEN}7. 卸载${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}====================================${RESET}"

    read -p "$(echo -e ${GREEN}请选择操作: ${RESET})" CHOICE
    case $CHOICE in
        1) backup_local ;;
        2) restore ;;
        3) setup_ssh_key ;;
        4) configure_settings_menu ;;
        5) backup_remote_all ;;
        6) schedule_menu ;;
        7) uninstall ;;
        0) exit 0 ;;
        *) echo -e "${RED}❌ 无效选择${RESET}" ;;
    esac
    read -p "$(echo -e ${GREEN}按回车继续...${RESET})"
done
