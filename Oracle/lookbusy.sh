#!/bin/bash

# 菜单字体颜色
GREEN="\033[32m"
RED="\033[31m"
RESET="\033[0m"

# 安装 Docker（如果未安装）
install_docker() {
  if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}正在安装 Docker...${RESET}"
    curl -fsSL https://get.docker.com | bash
    systemctl enable docker --now
  else
    echo -e "${GREEN}Docker 已安装${RESET}"
  fi
}

# 发送统计（可选）
send_stats() {
  echo -e "${GREEN}执行操作:${RESET} $1"
}

# 获取容器参数函数
get_container_envs() {
  ENV_VARS=$(docker inspect lookbusy --format '{{range .Config.Env}}{{println .}}{{end}}')
  CPU_CORE=$(echo "$ENV_VARS" | grep "CPU_CORE" | cut -d= -f2)
  CPU_UTIL=$(echo "$ENV_VARS" | grep "CPU_UTIL" | cut -d= -f2)
  MEM_UTIL=$(echo "$ENV_VARS" | grep "MEM_UTIL" | cut -d= -f2)
  SPEEDTEST_INTERVAL=$(echo "$ENV_VARS" | grep "SPEEDTEST_INTERVAL" | cut -d= -f2)
}

# 查看活跃脚本运行状态
status_lookbusy() {
  clear
  if docker ps -a --format '{{.Names}}' | grep -qw "lookbusy"; then
    echo -e "${GREEN}活跃脚本容器存在${RESET}"
    if docker ps --format '{{.Names}}' | grep -qw "lookbusy"; then
      echo -e "运行状态: ${GREEN}运行中${RESET}"
    else
      echo -e "运行状态: ${RED}已停止${RESET}"
    fi

    get_container_envs

    echo
    echo -e "${GREEN}容器参数:${RESET}"
    echo "CPU核心: $CPU_CORE"
    echo "CPU占用: $CPU_UTIL"
    echo "内存占用: $MEM_UTIL"
    echo "Speedtest间隔: $SPEEDTEST_INTERVAL 秒"

    echo
    echo -e "${GREEN}Docker 资源使用情况:${RESET}"
    docker stats --no-stream lookbusy
  else
    echo -e "${RED}未安装活跃脚本容器${RESET}"
  fi
  echo
  read -e -p "按回车返回菜单..." _
}

# 安装活跃脚本
install_lookbusy() {
  clear
  echo -e "${GREEN}活跃脚本: CPU占用10-20% 内存占用20% ${RESET}"
  read -e -p "确定安装吗？(Y/N): " choice
  case "$choice" in
    [Yy])
      install_docker

      # 默认值
      DEFAULT_CPU_CORE=1
      DEFAULT_CPU_UTIL="10-20"
      DEFAULT_MEM_UTIL=20
      DEFAULT_SPEEDTEST_INTERVAL=120

      # 用户输入参数，回车使用默认值
      read -e -p "请输入CPU核心数 [默认: $DEFAULT_CPU_CORE]: " cpu_core
      cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

      read -e -p "请输入CPU占用百分比范围 (如 10-20) [默认: $DEFAULT_CPU_UTIL]: " cpu_util
      cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

      read -e -p "请输入内存占用百分比 [默认: $DEFAULT_MEM_UTIL]: " mem_util
      mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

      read -e -p "请输入Speedtest间隔时间(秒) [默认: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
      speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

      # 启动容器
      docker run -itd --name=lookbusy --restart=always \
        -e TZ=Asia/Shanghai \
        -e CPU_UTIL="$cpu_util" \
        -e CPU_CORE="$cpu_core" \
        -e MEM_UTIL="$mem_util" \
        -e SPEEDTEST_INTERVAL="$speedtest_interval" \
        fogforest/lookbusy

      send_stats "甲骨文云安装活跃脚本"
      ;;
    [Nn])
      echo "已取消安装。"
      ;;
    *)
      echo "无效的选择，请输入 Y 或 N。"
      ;;
  esac
}

# 卸载活跃脚本
uninstall_lookbusy() {
  clear
  docker rm -f lookbusy 2>/dev/null
  docker rmi fogforest/lookbusy 2>/dev/null
  send_stats "甲骨文云卸载活跃脚本"
  read -e -p "按回车返回菜单..." _
}

# 修改参数
modify_lookbusy() {
  clear
  if ! docker ps -a --format '{{.Names}}' | grep -qw "lookbusy"; then
    echo -e "${RED}容器不存在，请先安装！${RESET}"
    read -e -p "按回车返回菜单..." _
    return
  fi

  get_container_envs

  echo -e "${GREEN}当前容器参数:${RESET}"
  echo "CPU核心: $CPU_CORE"
  echo "CPU占用: $CPU_UTIL"
  echo "内存占用: $MEM_UTIL"
  echo "Speedtest间隔: $SPEEDTEST_INTERVAL 秒"
  echo

  # 用户输入新的参数，回车保留旧值
  read -e -p "请输入CPU核心数 [默认: $CPU_CORE]: " cpu_core
  cpu_core=${cpu_core:-$CPU_CORE}

  read -e -p "请输入CPU占用百分比范围 (如 10-20) [默认: $CPU_UTIL]: " cpu_util
  cpu_util=${cpu_util:-$CPU_UTIL}

  read -e -p "请输入内存占用百分比 [默认: $MEM_UTIL]: " mem_util
  mem_util=${mem_util:-$MEM_UTIL}

  read -e -p "请输入Speedtest间隔时间(秒) [默认: $SPEEDTEST_INTERVAL]: " speedtest_interval
  speedtest_interval=${speedtest_interval:-$SPEEDTEST_INTERVAL}

  # 重建容器（先删后建）
  docker rm -f lookbusy
  docker run -itd --name=lookbusy --restart=always \
    -e TZ=Asia/Shanghai \
    -e CPU_UTIL="$cpu_util" \
    -e CPU_CORE="$cpu_core" \
    -e MEM_UTIL="$mem_util" \
    -e SPEEDTEST_INTERVAL="$speedtest_interval" \
    fogforest/lookbusy

  send_stats "修改活跃脚本参数"
  read -e -p "参数已更新，按回车返回菜单..." _
}

# 主菜单
while true; do
  clear
  echo -e "${GREEN}=== 甲骨文云 活跃脚本管理菜单 ===${RESET}"
  echo -e "${GREEN}1) 安装活跃脚本${RESET}"
  echo -e "${GREEN}2) 卸载活跃脚本${RESET}"
  echo -e "${GREEN}3) 查看活跃脚本状态${RESET}"
  echo -e "${GREEN}4) 修改活跃脚本参数${RESET}"
  echo -e "${GREEN}0) 退出${RESET}"
 read -e -p "$(echo -e ${GREEN}请输入选项: ${RESET})" opt

  case "$opt" in
    1) install_lookbusy ;;
    2) uninstall_lookbusy ;;
    3) status_lookbusy ;;
    4) modify_lookbusy ;;
    0) exit 0 ;;
    *) echo -e "${RED}无效选择${RESET}"; sleep 1 ;;
  esac
done
