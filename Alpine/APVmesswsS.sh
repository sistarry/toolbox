#!/usr/bin/env bash
#
# Alpine sing-box VMess+WS 专属管理面板 
# SPDX-License-Identifier: MIT
#
set -Eop pipefail
export LANG=en_US.UTF-8

# =========================================================
# 1. 核心控制与全局环境初始化
# =========================================================
readonly BINARY_PATH="/usr/local/bin/sing-box-vmess"
readonly VMESS_CONFIG="/etc/sing-box-vmess/config.json"
readonly SB_DIR="/root/proxynode/vmessws"
CONFIG_DIR="/etc/sing-box-vmess"
OPENRC_SERVICE_PATH="/etc/init.d/sing-box-vmess"
LOG_FILE="/var/log/sing-box-vmess.log"
RUN_USER="singbox-vmess"

TMP_DIR=$(mktemp -d -t sb-vmess.XXXXXX)

# 颜色标准规范
GREEN="\033[32m"
RED="\033[31m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
RESET="\033[0m"

info() { echo -e "${GREEN}[信息] $*${RESET}" >&2; }
warn() { echo -e "${YELLOW}[警告] $*${RESET}" >&2; }
error() { echo -e "${RED}[错误] $*${RESET}" >&2; }
pause() { echo; read -n 1 -s -r -p "$(echo -e ${GREEN}"按任意键返回菜单..."${RESET})" || true; echo; }

cleanup() {
  [[ -d "$TMP_DIR" ]] && rm -rf "$TMP_DIR"
}
trap cleanup EXIT INT TERM

generate_uuid() {
  if command -v uuidgen &>/dev/null; then
    uuidgen | tr '[:upper:]' '[:lower:]'
  else
    cat /proc/sys/kernel/random/uuid 2>/dev/null || echo "cf866946-b816-43ad-8d96-037340e4f208"
  fi
}

is_alpine() {
  [[ -f /etc/alpine-release ]]
}

install_packages() {
  info "正在刷新 Alpine 仓库并安装核心依赖..."
  apk update
  apk add --no-cache bash curl wget tar openrc iproute2 jq grep sed coreutils bind-tools util-linux gcompat
}

create_user() {
  getent group "$RUN_USER" &>/dev/null || addgroup -S "$RUN_USER"
  id "$RUN_USER" &>/dev/null || adduser -S -D -H -G "$RUN_USER" -s /sbin/nologin "$RUN_USER"
}

detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    aarch64|arm64) echo "arm64" ;;
    armv7l|armv7) echo "armv7" ;;
    *) error "不支持当前架构: $(uname -m)"; exit 8 ;;
  esac
}

check_environment() {
  if ! is_alpine; then
    error "本脚本仅支持 Alpine Linux 系统。"
    exit 95
  fi
  install_packages
  create_user
}

get_installed_version() {
  if [[ -f "$BINARY_PATH" ]]; then
    "$BINARY_PATH" version 2>/dev/null | head -n1 | awk '{print $3}' || echo "未知版本"
  else
    echo "未安装"
  fi
}

get_latest_version() {
  info "正在从 GitHub 获取 sing-box 最新版本号..."
  local latest_v
  latest_v=$(curl -fsSL "https://api.github.com/repos/SagerNet/sing-box/releases/latest" | jq -r .tag_name | sed 's/^v//')
  
  if [[ -z "$latest_v" || "$latest_v" == "null" ]]; then
    warn "通过 API 获取最新版本失败，尝试备用匹配方案..."
    latest_v=$(curl -fsSL "https://github.com/SagerNet/sing-box/releases/latest" | grep -oE 'releases/tag/v[0-9.]+' | head -n1 | sed 's|releases/tag/v||')
  fi

  if [[ -n "$latest_v" ]]; then
    SINGBOX_VERSION="$latest_v"
    info "成功获取最新版本: v$SINGBOX_VERSION"
  else
    SINGBOX_VERSION="1.13.12"
    warn "无法获取最新版本，将使用保底版本: v$SINGBOX_VERSION"
  fi
}

# =========================================================
# 4. 网络诊断与配置管理辅助
# =========================================================
get_public_ip() {
    local ip_addr
    for cmd in "curl -4s --max-time 5" "wget -4qO- --timeout=5"; do
        for url in "https://api.ipify.org" "https://ip.sb" "https://checkip.amazonaws.com"; do
            ip_addr=$($cmd "$url" 2>/dev/null) && [[ -n "$ip_addr" ]] && echo "$ip_addr" && return
        done
    done
    for cmd in "curl -6s --max-time 5" "wget -6qO- --timeout=5"; do
        for url in "https://api64.ipify.org" "https://ip.sb"; do
            ip_addr=$($cmd "$url" 2>/dev/null) && [[ -n "$ip_addr" ]] && echo "$ip_addr" && return
        done
    done
    echo "127.0.0.1"
}

check_port() {
  local port_chk="$1"
  if ss -tunlp | grep -E -q ":$port_chk "; then
    return 1
  fi
  return 0
}

is_valid_port() { [[ "$1" =~ ^[0-9]+$ ]] && [[ "$1" -ge 1 ]] && [[ "$1" -le 65535 ]]; }

get_random_port() {
  local rand_port
  while true; do
    rand_port=$(shuf -i 2000-65535 -n 1)
    if check_port "$rand_port"; then
      echo "$rand_port" && return 0
    fi
  done
}

get_vmess_status() {
  if rc-service sing-box-vmess status 2>/dev/null | grep -q "started"; then
    echo "RUNNING"
  else
    echo "STOPPED"
  fi
}

get_current_port_display() {
  if [[ -f "$VMESS_CONFIG" ]]; then
    jq -r '.inbounds[0].listen_port // empty' "$VMESS_CONFIG" 2>/dev/null || echo "-"
  else echo "-"; fi
}

# =========================================================
# 5. 面板节点配置生成核心逻辑 (完美剥离 alter_id 字段)
# =========================================================
inst_port() {
  local default_port=""
  if [[ -f "$VMESS_CONFIG" ]]; then
    default_port=$(jq -r '.inbounds[0].listen_port // empty' "$VMESS_CONFIG" 2>/dev/null)
  fi

  local prompt_msg="设置 VMess 服务端监听端口 [1-65535] (回车随机分配): "
  [[ -n "$default_port" ]] && prompt_msg="设置 VMess 服务端监听端口 [当前: ${default_port}, 回车不修改]: "

  while true; do
    read -rp "$prompt_msg" port
    if [[ -z "$port" ]]; then
      if [[ -n "$default_port" ]]; then port="$default_port" && break
      else
        port=$(get_random_port)
        info "已为您随机分配未被占用端口: $port" && break
      fi
    elif is_valid_port "$port"; then
      if [[ "$port" != "$default_port" ]] && ! check_port "$port"; then
        error "端口 ${port} 已被其它程序占用，请更换。" && continue
      fi
      break
    else error "请输入有效的端口数字 (1-65535)"; fi
  done
}

write_and_show_config() {
  local url_ip
  url_ip=$(get_public_ip)

  local headers_json="{}"
  if [[ -n "$ws_host" ]]; then
    headers_json="{\"Host\": \"$ws_host\"}"
  fi

  # 1. 写入服务端隔离配置文件 (完全去除旧内核兼容的 alter_id 字段，规避报错)
  cat << EOF > "$VMESS_CONFIG"
{
  "log": {
    "level": "info",
    "output": "$LOG_FILE",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vmess",
      "tag": "vmess-in",
      "listen": "::",
      "listen_port": $port,
      "users": [
        {
          "uuid": "$auth_uuid"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "$ws_path",
        "headers": $headers_json
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ],
  "route": {
    "final": "direct"
  }
}
EOF

  chmod 640 "$VMESS_CONFIG"
  chown -R ${RUN_USER}:${RUN_USER} "$CONFIG_DIR"
  mkdir -p "$SB_DIR"
  
  # 2. 写入通用客户端备份
  cat << EOF > "$SB_DIR/sb-client.json"
{
  "log": {
    "level": "info"
  },
  "outbounds": [
    {
      "type": "vmess",
      "tag": "vmess-out",
      "server": "$url_ip",
      "server_port": $port,
      "uuid": "$auth_uuid",
      "security": "auto",
      "transport": {
        "type": "ws",
        "path": "$ws_path",
        "headers": $headers_json
      }
    },
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

  rc-service sing-box-vmess restart
  if rc-service sing-box-vmess status | grep -q "started"; then
    info "sing-box VMess+WS 服务运行环境安全就绪！"
  else
    error "核心服务启动失败，请进入菜单 8 查看隔离日志。"
  fi
  showconf
}

# =========================================================
# 6. 安装、更新与卸载核心流控
# =========================================================
write_openrc_script() {
  cat << 'EOF' > "$OPENRC_SERVICE_PATH"
#!/sbin/openrc-run

name="sing-box-vmess"
description="sing-box VMess+WS OpenRC Isolated Service"
cfgfile="/etc/sing-box-vmess/config.json"
logfile="/var/log/sing-box-vmess.log"
command="/usr/local/bin/sing-box-vmess"
command_args="run -c /etc/sing-box-vmess/config.json"

depend() {
    need net
    after firewall
}

start_pre() {
    if [ ! -f "$cfgfile" ]; then
        eerror "Configuration file $cfgfile missing!"
        return 1
    fi
    
    touch "$logfile"
    chown singbox-vmess:singbox-vmess "$logfile"
    chmod 644 "$logfile"
    
    command_background="yes"
    pidfile="/run/${RC_SVCNAME}.pid"
    
    output_log="$logfile"
    error_log="$logfile"
    
    local port
    port=$(jq -r '.inbounds[0].listen_port // 0' "$cfgfile" 2>/dev/null)
    if [ "$port" -lt 1024 ] && [ "$port" -ne 0 ]; then
        command_user="root:root"
    else
        command_user="singbox-vmess:singbox-vmess"
    fi
}
EOF
  chmod +x "$OPENRC_SERVICE_PATH"
  rc-update add sing-box-vmess default >/dev/null 2>&1 || true
}

download_core() {
  local arch url
  arch=$(detect_arch)
  get_latest_version
  url=$(printf 'https://github.com/SagerNet/sing-box/releases/download/v%s/sing-box-%s-linux-%s.tar.gz' "$SINGBOX_VERSION" "$SINGBOX_VERSION" "$arch")
  
  info "正在下载官方核心 sing-box v$SINGBOX_VERSION..."
  cd "$TMP_DIR"
  if ! wget -O sing-box.tar.gz -q "$url"; then
    curl -fsSL -o sing-box.tar.gz "$url" || { error "下载核心文件失败"; return 1; }
  fi
  
  tar -xzf sing-box.tar.gz -C "$TMP_DIR"
  local extracted
  extracted=$(find "$TMP_DIR" -type f -name sing-box | head -n 1)
  [[ -n "$extracted" ]] || { error "解压目标核心错误"; return 1; }
  
  rc-service sing-box-vmess stop >/dev/null 2>&1 || true
  install -m 755 "$extracted" "$BINARY_PATH"
  info "sing-box-vmess 核心释放完毕。"
  return 0
}

install_vmess() {
  echo -e "${GREEN}[信息] 开始在 Alpine 下部署专属隔离的 sing-box VMess+WS 环境 ...${RESET}"
  check_environment
  mkdir -p "$CONFIG_DIR" "$SB_DIR"

  if ! download_core; then return 1; fi

  write_openrc_script
  inst_port
  
  read -rp "设置 VMess 验证 UUID (回车自动分配高强随机 UUID): " auth_uuid
  auth_uuid=${auth_uuid:-$(generate_uuid)}

  read -rp "设置 WebSocket 路径 (形如 /ws，直接回车默认 /ws): " ws_path
  ws_path=${ws_path:-/ws}
  [[ "$ws_path" != /* ]] && ws_path="/$ws_path"

  read -rp "设置自定义伪装域名 Host (回车留空不限制): " ws_host

  write_and_show_config
}

update_vmess() {
  if [[ ! -f "$BINARY_PATH" ]]; then
    error "当前系统未检测到核心，无法执行覆盖升级。"
    return 1
  fi
  info "检测到已有环境，正在执行纯净原地覆盖核心升级..."
  if download_core; then
    rc-service sing-box-vmess start
    info "sing-box-vmess 核心纯净升级覆盖成功，服务已安全启动！"
  else
    error "核心升级遭遇未预期中断。"
  fi
}

unstvmess() {
  warn "即将执行全面清洁卸载..."

  rc-service sing-box-vmess stop || true
  rc-update del sing-box-vmess default >/dev/null 2>&1 || true
  
  rm -f "$BINARY_PATH" "$OPENRC_SERVICE_PATH" "$LOG_FILE"
  rm -rf "$CONFIG_DIR" "$SB_DIR"
  
  info "VMess+WS 专属隔离服务及相关配置已被彻底清洁卸载！"
}

changeconf() {
  if [[ ! -f "$VMESS_CONFIG" ]]; then
    error "配置文件不存在，请先选择选项 1 安装"
    return 1
  fi

  local old_uuid old_path old_host
  old_uuid=$(jq -r '.inbounds[0].users[0].uuid // empty' "$VMESS_CONFIG")
  old_path=$(jq -r '.inbounds[0].transport.path // "/ws"' "$VMESS_CONFIG")
  old_host=$(jq -r '.inbounds[0].transport.headers.Host // empty' "$VMESS_CONFIG")

  clear
  echo -e "${GREEN}====== 修改 VMess+WS 专属配置 ======${RESET}"
  echo "提示：直接敲回车将保持原有配置不变"
  echo "---------------------------------------------"
  
  inst_port 

  local auth_uuid
  read -rp "设置 VMess 验证 UUID [当前: ${old_uuid}, 回车不修改]: " auth_uuid
  auth_uuid=${auth_uuid:-$old_uuid}

  local ws_path
  read -rp "设置 WebSocket 路径 [当前: ${old_path}, 回车不修改]: " ws_path
  ws_path=${ws_path:-$old_path}
  [[ "$ws_path" != /* ]] && ws_path="/$ws_path"

  local ws_host
  read -rp "设置伪装域名 Host [当前: ${old_host:-无}, 回车不修改]: " ws_host
  ws_host=${ws_host:-$old_host}

  write_and_show_config
  info "配置与客户端备份刷新修改成功！"
}

# =========================================================
# 5. 核心业务展示模块（动态提取参数 + 精准对齐 Host 的 VMess 格式）
# =========================================================
showconf() {
  if [[ ! -f "$VMESS_CONFIG" ]]; then
    error "未发现核心配置文件，请先选择选项 1 安装。"
    return
  fi

  # 实时从服务端核心配置中提取参数，确保 100% 准确
  local hostname=$(hostname -s | sed 's/ /_/g')
  local main_port=$(jq -r '.inbounds[0].listen_port' "$VMESS_CONFIG" 2>/dev/null || echo "18055")
  local auth_uuid=$(jq -r '.inbounds[0].users[0].uuid' "$VMESS_CONFIG" 2>/dev/null || echo "uuid")
  local ws_path=$(jq -r '.inbounds[0].transport.path' "$VMESS_CONFIG" 2>/dev/null || echo "/ws")
  local ws_host=$(jq -r '.inbounds[0].transport.headers.Host' "$VMESS_CONFIG" 2>/dev/null || echo "")
  
  local ip=$(get_public_ip)
  local url_ip="$ip"
  if [[ "$ip" =~ ":" ]]; then 
    url_ip="[$ip]"
  fi

  # 构造带自定义 Host 信息的 V2rayN 标准 VMess:// Base64 订阅链接 (不包含已废弃的 aid 混淆)
  local vmess_json_str
  vmess_json_str=$(printf '{"v":"2","ps":"%s-VMess_WS","add":"%s","port":"%s","id":"%s","aid":"0","scy":"auto","net":"ws","type":"none","host":"%s","path":"%s","tls":""}' "$hostname" "$ip" "$main_port" "$auth_uuid" "$ws_host" "$ws_path")
  local vmess_b64
  vmess_b64=$(echo -n "$vmess_json_str" | base64 | tr -d '\n\r ')

  local surge_headers=""
  if [[ -n "$ws_host" ]]; then
    surge_headers=", ws-headers=Host:${ws_host}"
  fi

  echo -e "${GREEN}====== 节点信息 ======${RESET}"
  echo -e "${YELLOW}IP        : ${ip}${RESET}"
  echo -e "${YELLOW}端口      : ${main_port}${RESET}"
  echo -e "${YELLOW}UUID      : ${auth_uuid}${RESET}"
  echo -e "${YELLOW}传输类型   : websocket (ws)${RESET}"
  echo -e "${YELLOW}WS 路径    : ${ws_path}${RESET}"
  echo -e "${YELLOW}伪装 Host  : ${ws_host:-未限制 (无)}${RESET}"
  echo -e "${GREEN}---------------------------${RESET}"
  echo -e "${YELLOW}📄 V6VPS 请自行替换 IP 地址为 V6 ★${RESET}"
  echo -e "${YELLOW}[信息] V2rayN 订阅链接：${RESET}"
  echo -e "${CYAN}vmess://${vmess_b64}${RESET}"
  echo -e "${YELLOW}[信息] Surge 配置：${RESET}"
  echo -e "${CYAN}${hostname}-VMess = vmess, ${url_ip}, ${main_port}, username=${auth_uuid}, ws=true, ws-path=${ws_path}, vmess-aead=true${RESET}"
  echo -e "${YELLOW}---------------------------------${RESET}"
  
}

# =========================================================
# 7. 面板交互菜单 
# =========================================================
menu() {
  while true; do
    clear
    local raw_status status version port_show
    raw_status=$(get_vmess_status)
    status=""
    if [[ "$raw_status" == "RUNNING" ]]; then
      status="${GREEN}● 运行中${RESET}"
    else
      status="${RED}● 未运行${RESET}"
    fi

    version=$(get_installed_version)
    port_show=$(get_current_port_display)

    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}     Sing-box Vmess-ws  面板     ${RESET}"
    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}状态   :${RESET} ${status}"
    echo -e "${GREEN}版本   :${RESET} ${YELLOW}${version}${RESET}"
    echo -e "${GREEN}端口   :${RESET} ${YELLOW}${port_show}${RESET}"
    echo -e "${GREEN}================================${RESET}"
    echo -e "${GREEN}1. 安装 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}2. 更新 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}3. 卸载 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}4. 修改配置${RESET}"
    echo -e "${GREEN}5. 启动 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}6. 停止 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}7. 重启 Sing-box Vmess-ws${RESET}"
    echo -e "${GREEN}8. 查看日志${RESET}"
    echo -e "${GREEN}9. 查看节点配置${RESET}"
    echo -e "${GREEN}0. 退出${RESET}"
    echo -e "${GREEN}================================${RESET}"

    local choice=""
    read -r -p $'\033[32m请输入选项: \033[0m' choice || true
    [[ -z "$choice" ]] && continue

    case "$choice" in
      1) install_vmess; pause ;;
      2) update_vmess; pause ;;
      3) unstvmess; pause ;;
      4) changeconf; pause ;;
      5) rc-service sing-box-vmess start && info "服务已成功启动！"; pause ;;
      6) rc-service sing-box-vmess stop && info "服务已成功停止！"; pause ;;
      7) rc-service sing-box-vmess restart && info "服务已成功重启！"; pause ;;
      8) if [[ -f "$LOG_FILE" ]]; then tail -n 50 "$LOG_FILE"; else warn "未发现运行日志文件。"; fi; pause ;;
      9) showconf; pause ;;
      0) exit 0 ;;
      *) error "无效输入，请重新选择. "; sleep 1 ;;
    esac
  done
}

if [[ ${EUID} -ne 0 ]]; then
  error "请切换至 root 用户运行此面板脚本。"
  exit 1
fi

menu "$@"
