#!/bin/bash

get_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo $ID
  else
    echo "unknown"
  fi
}

install_tools() {
  distro=$(get_distro)
  echo "检测到的发行版: $distro"
  
  case $distro in
    "ubuntu"|"debian")
      install_sudo "apt"
      install_iproute2 "apt"
      install_dhclient "apt"
      ;;
    "centos"|"rhel")
      install_sudo "yum"
      install_iproute2 "yum"
      install_dhclient "yum"
      ;;
    "fedora")
      install_sudo "dnf"
      install_iproute2 "dnf"
      install_dhclient "dnf"
      ;;
    "arch")
      install_sudo "pacman"
      install_iproute2 "pacman"
      install_dhclient "pacman"
      ;;
    "opensuse")
      install_sudo "zypper"
      install_iproute2 "zypper"
      install_dhclient "zypper"
      ;;
    *)
      echo "不支持的发行版，请手动安装工具。"
      exit 1
      ;;
  esac
}

install_sudo() {
  package_manager=$1
  if ! command -v sudo > /dev/null; then
    echo "sudo 未安装，正在尝试安装..."
    $package_manager install -y sudo
  else
    echo "sudo 已安装。"
  fi
}

install_iproute2() {
  package_manager=$1
  if ! command -v ip > /dev/null; then
    echo "正在安装 iproute2 工具..."
    $package_manager install -y iproute2
  else
    echo "iproute2 已安装。"
  fi
}

install_dhclient() {
  package_manager=$1
  if ! command -v dhclient > /dev/null; then
    echo "正在安装 dhclient 工具..."
    $package_manager install -y isc-dhcp-client
  else
    echo "dhclient 已安装。"
  fi
}

get_main_network_interface() {
  interface=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo | head -n 1)
  echo "$interface"
}

configure_ipv6_in_interfaces() {
  distro=$(get_distro)
  interface=$(get_main_network_interface)
  
  case $distro in
    "ubuntu"|"debian")
      configure_ipv6_in_interfaces_debian "$interface"
      ;;
    "centos"|"rhel"|"fedora")
      configure_ipv6_in_interfaces_rhel "$interface"
      ;;
    "arch"|"opensuse")
      configure_ipv6_in_interfaces_other "$interface"
      ;;
    *)
      echo "不支持的网络配置方式，请手动配置。"
      exit 1
      ;;
  esac
}

configure_ipv6_in_interfaces_debian() {
  interface=$1
  interfaces_file="/etc/network/interfaces"
  if ! grep -q "iface $interface inet6" "$interfaces_file"; then
    echo "未找到 IPv6 配置，正在添加..."
    echo -e "\n# 配置 IPv6 DHCP\niface $interface inet6 dhcp" | sudo tee -a "$interfaces_file" > /dev/null
    echo "IPv6 配置已添加到 /etc/network/interfaces 文件中。"
  else
    echo "IPv6 配置已存在，无需修改。"
  fi
}

configure_ipv6_in_interfaces_rhel() {
  interface=$1
  ifcfg_file="/etc/sysconfig/network-scripts/ifcfg-$interface"
  if ! grep -q "IPV6INIT" "$ifcfg_file"; then
    echo "未找到 IPv6 配置，正在添加..."
    echo -e "\nIPV6INIT=yes\nIPV6_AUTOCONF=yes" | sudo tee -a "$ifcfg_file" > /dev/null
    echo "IPv6 配置已添加到 $ifcfg_file 文件中。"
  else
    echo "IPv6 配置已存在，无需修改。"
  fi
}

configure_ipv6_in_interfaces_other() {
  interface=$1
  echo "自动配置IPv6地址的其他方式 (系统：$interface) "
}

check_ipv6() {
  ip -6 addr show | grep -q "inet6.*global"
  if [[ $? -eq 0 ]]; then
    echo "你的 IPv6 已经正常配置，无需修改。"
    return 0
  else
    echo "当前网络不支持自动获取 IPv6，尝试手动配置。"
    return 1
  fi
}

request_ipv6_for_all_interfaces() {
  echo "正在为所有接口请求 IPv6 地址..."
  interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep -v lo)

  success=0
  for interface in $interfaces; do
    if [[ $interface == veth* || $interface == docker* ]]; then
      continue
    fi

    if ! ip link show dev $interface | grep -q "state UP"; then
      echo "$interface 接口未启用，跳过配置。"
      continue
    fi

    echo "请求 $interface 的 IPv6 地址..."
    sudo dhclient -6 $interface &> /dev/null &
    pid=$!
    
    retries=5
    while ps -p $pid > /dev/null && [ $retries -gt 0 ]; do
      sleep 5
      retries=$((retries - 1))
    done

    if ps -p $pid > /dev/null; then
      sudo kill -9 $pid &> /dev/null
    else
      if ip -6 addr show dev $interface | grep -q "inet6 .*global"; then
        success=1
        break
      fi
    fi
  done

  return $success
}

manual_ipv6_configuration() {
  interface=$(get_main_network_interface)
  echo "检测到的网口: $interface"
  read -p "请输入手动配置的 IPv6 地址: " ipv6_address
  read -p "请输入子网掩码 (例如 64): " subnet_mask
  read -p "请输入默认网关: " gateway
  sudo ip -6 addr add ${ipv6_address}/${subnet_mask} dev ${interface}
  sudo ip -6 route add default via ${gateway} dev ${interface}
  echo "$interface 手动配置 IPv6 地址成功。"
}

find_default_gateway() {
  echo "正在查找默认 IPv6 网关..."
  gateway=$(ip -6 route | grep default | awk '{print $3}')
  interface=$(get_main_network_interface)

  if [[ -n $gateway && -n $interface ]]; then
    echo "找到的默认网关: $gateway"
    echo "使用接口: $interface"
    
    if ! ip -6 route | grep -q "default via $gateway dev $interface"; then
      sudo ip -6 route add default via $gateway dev $interface
      echo "已添加默认路由。"
    else
      echo "默认路由已存在，无需重复添加。"
    fi
  else
    echo "未找到默认网关，请手动配置。"
  fi
}

main() {
  check_ipv6
  if [[ $? -eq 0 ]]; then
    echo "IPv6 配置正常，脚本已跳过配置。"
    exit 0
  fi
  
  install_tools
  configure_ipv6_in_interfaces

  echo "请选择获取 IPv6 地址的方式:"
  echo "1) 自动获取 IPv6"
  echo "2) 手动填写 IPv6"
  read -p "请输入选项 (1 或 2): " choice

  case $choice in
    1)
      request_ipv6_for_all_interfaces
      if [[ $? -eq 0 ]]; then
        check_ipv6
        find_default_gateway
      else
        echo "自动获取 IPv6 地址失败，请选择手动配置。"
      fi
      ;;
    2)
      manual_ipv6_configuration
      ;;
    *)
      echo "无效选项，请选择 1 或 2。"
      exit 1
      ;;
  esac
}

main
