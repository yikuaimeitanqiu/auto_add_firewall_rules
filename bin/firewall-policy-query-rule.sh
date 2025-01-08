#!/bin/bash

# Check if user is root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 获取当前脚本所在的目录路径
BIN_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
source "${BIN_SCRIPT_PATH}"/../conf/color.sh &>/dev/null

# 判断防火墙未运行,不打印
Firewall_State="$(firewall-cmd --state &>/dev/null && echo 'running')"
if [ -z "${Firewall_State}" ]; then
    printf "${RED_COLOR}\n防火墙未运行,未能查询成功!\n\n${RES}" 
    exit 1
fi

# 查询已生效的防火墙规则
firewall-cmd --list-all

#read -e -p "请问查看哪个防火墙信息？ 1.firewalld 2.iptables (1/2) : " QUERY_INFO
#if [ "$QUERY_INFO" == "1" ]; then
#	firewall-cmd --list-all
#elif [ "$QUERY_INFO" == "2" ]; then
#	iptables -t filter -L -nv --line-numbers
#else
#	printf "请正确输入选项 (1/2) \n"
#fi
