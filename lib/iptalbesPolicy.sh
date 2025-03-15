#!/usr/bin/env bash

# 针对 iptables 检查
#
#

# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${LIB_SCRIPT_PATH}"/../modules/color.sh &>/dev/null

# 默认添加 SSH 服务连接,防止会话连接中断
Iptables_SSH () {

    # 获取可能已调整的 ssh 端口号
    if [ -f /etc/ssh/sshd_config ]; then
        NEW_SSH_PORT="$( grep -E '^Port ' /etc/ssh/sshd_config | grep -oE '[0-9]{1,5}')"
        if [ -n "${NEW_SSH_PORT}" ]; then
            iptables --table filter --append INPUT --protocol tcp --destination-port "${NEW_SSH_PORT}" --jump ACCEPT
        fi
    fi
}

# 检查防火墙是否开启,未运行则运行,如果运行失败则不往下执行
Iptables_Status () {

# 检查 iptables 命令
if ! command -v iptables 1>/dev/null; then
    echo -e "${RED_COLOR}iptables 命令未能检查到，无法配置防火墙.\n${RES}" 
    exit 127
fi

# 获取系统架构
ARCH="$(arch)"

# 检查 busybox
if [ -f "${LIB_SCRIPT_PATH}/../packages/busybox/${ARCH}/busybox" ]; then
    Iptables_LSMOD="$( "${LIB_SCRIPT_PATH}/../packages/busybox/${ARCH}"/busybox lsmod | grep 'iptable_filter' )"
else
    Iptables_LSMOD="$( lsmod | grep 'iptable_filter' )"
fi

# 检查 filter 表链
Iptables_State="$(iptables -t filter -L -n -v &>/dev/null && echo 'running')"

if [ -n "${Iptables_State}" ] && [ -n "${Iptables_LSMOD}" ]; then
    echo -e "${GREEN_COLOR}iptables 服务正在运行\n${RES}" 
else
    echo -e "${RED_COLOR}iptables 服务检测失败,请检查原因,再执行此脚本.\n${RES}" 
    exit 1
fi
}



