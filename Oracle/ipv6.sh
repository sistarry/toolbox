#!/bin/bash

# 确认提示
read -p $'\033[31m即将运行添加V6是否继续？(y/n): \033[0m' choice

if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
    echo -e "\033[31m开始执行脚本...\033[0m"
    bash <(curl -L -s jhb.ovh/jb/v6.sh)
else
    echo -e "\033[31m已取消执行。\033[0m"
fi
