#!/usr/bin/env bash

# 针对 iptables 检查
#
#

# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${LIB_SCRIPT_PATH}"/../modules/color.sh &>/dev/null
. "${LIB_SCRIPT_PATH}"/../modules/string_color.sh &>/dev/null

# 默认添加 SSH 服务连接,防止会话连接中断
IPTABLES_SSH () {
    # 获取可能已调整的 ssh 端口号
    if [ -f /etc/ssh/sshd_config ]; then
        NEW_SSH_PORT="$( grep -E '^Port ' /etc/ssh/sshd_config | grep -oE '[0-9]{1,5}')"
        if [ -n "${NEW_SSH_PORT}" ]; then
            if ! iptables --table filter --check INPUT \
                --protocol tcp --destination-port "${NEW_SSH_PORT}" --jump ACCEPT 2>/dev/null;
            then
                iptables --table filter --append INPUT \
                    --protocol tcp --destination-port "${NEW_SSH_PORT}" --jump ACCEPT
            fi
        fi
    fi
}

# 添加丢弃 icmp 协议
IPTABLES_DROP_ICMP () {
# 向默认的 OUTPUT/FORWARD 链 添加丢弃 icmp 规则
for item in OUTPUT FORWARD ; do
    if ! iptables --table filter --check "${item}" --protocol icmp --jump DROP 2>/dev/null; then
        iptables --table filter --append "${item}" --protocol icmp --jump DROP
    fi
done
}

# 检查防火墙是否开启,未运行则运行,如果运行失败则不往下执行
IPTABLES_STATUS () {
# 检查 iptables 命令
if ! command -v iptables 1>/dev/null; then
    echo -e "${RED_COLOR}iptables 命令未能检查到，无法配置防火墙.\n${RES}" 
    exit 127
fi

# 获取系统架构
ARCH="$(arch)"
# 检查 busybox
if [ -f "${LIB_SCRIPT_PATH}/../packages/busybox/${ARCH}/busybox" ]; then
    IPTABLES_LSMOD="$( "${LIB_SCRIPT_PATH}/../packages/busybox/${ARCH}"/busybox lsmod | grep 'iptable_filter' )"
else
    IPTABLES_LSMOD="$( lsmod | grep 'iptable_filter' )"
fi

# 检查 filter 表链
IPTABLES_STATE="$(iptables -t filter -L -n -v &>/dev/null && echo 'running')"

if [ -z "${IPTABLES_STATE}" ] && [ -z "${IPTABLES_LSMOD}" ]; then
#     echo -e "${GREEN_COLOR}iptables 服务正在运行\n${RES}" 
# else
    echo -e "${RED_COLOR}iptables 服务检测失败,请检查原因,再执行此脚本.\n${RES}" 
    exit 1
fi
}



# 输出 INPUT 链规则
IPTABLES_INPUT_RULES () {
    TIPS_MSG "filter 表 INPUT 链下的规则"
    if command -v column &>/dev/null; then
        iptables --table filter --list INPUT --line-numbers --numeric --verbose --exact | column -t
    else
        iptables --table filter --list INPUT --line-numbers --numeric --verbose --exact
    fi
    TIPS_MSG "----------------------------------------------------------------\n"
}


# 输出 OUTPUT 链规则
IPTABLES_OUTPUT_RULES () {
    TIPS_MSG "filter 表 OUTPUT 链下的规则："
    if command -v column &>/dev/null; then
        iptables --table filter --list OUTPUT --line-numbers --numeric --verbose --exact | column -t
    else
        iptables --table filter --list OUTPUT --line-numbers --numeric --verbose --exact
    fi
    TIPS_MSG "----------------------------------------------------------------\n"
}

# 输出 FORWARD 链规则
IPTABLES_FORWARD_RULES () {
    TIPS_MSG "filter 表 FORWARD 链下的规则："
    if command -v column &>/dev/null; then
        iptables --table filter --list FORWARD --line-numbers --numeric --verbose --exact | column -t
    else
        iptables --table filter --list FORWARD --line-numbers --numeric --verbose --exact
    fi
    TIPS_MSG "----------------------------------------------------------------\n"
}




# 远端地址不空，本地地址为空
REMOTE_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ];then

    # 允许指定远端地址访问本地端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址:${REMOTE_ADDR} 访问本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止指定远端地址访问本地端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址:${REMOTE_ADDR} 访问本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump DROP"

    # 允许指定的远端地址及指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址:${REMOTE_ADDR} 指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --protocol ${PROTOCOL} --source-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止指定的远端地址及指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址:${REMOTE_ADDR} 指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --protocol ${PROTOCOL} --source-port ${LOCAL_PORT} --jump DROP"
    fi
fi
}


# 远端地址为空，本地地址不为空
LOCAL_ADDR_RULES () {
if [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ];then
	
    # 允许任意远端地址及端口访问指定本地地址及指定本地端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许任意远端地址及端口访问指定本地地址:${LOCAL_ADDR} 指定本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止任意远端地址及端口访问指定本地地址及指定本地端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止任意远端地址及端口访问指定本地地址:${LOCAL_ADDR} 指定本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump DROP"

    # 允许任意远端地址及指定远端端口访问指定本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许任意远端地址及指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址:${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump ACCEPT"

    # 禁止任意远端地址及指定端口访问指定本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止任意远端地址及指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址:${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump DROP"
    fi
fi
}


# 远端地址及本地地址均不为空
REMOTE_LOCAL_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ]; then

    # 允许指定远端地址访问指定本地地址的指定端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址：${REMOTE_ADDR} 访问指定本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止指定远端地址访问指定本地地址的指定端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址：${REMOTE_ADDR} 访问指定本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump DROP"

    # 允许指定远端地址通过指定远端端口访问指定本地地址
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump ACCEPT"

    # 禁止指定远端地址通过指定远端端口访问指定本地地址
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump DROP"

    # 允许指定远端地址通过指定远端端口访问指定本地地址的指定端口
    elif [ -n "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --destination-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止指定远端地址通过指定远端端口访问指定本地地址的指定端口
    elif [ -n "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --destination-port ${LOCAL_PORT} --jump DROP"
    fi
fi
}


# 远端地址及本地地址均为空
REMOTE_LOCAL_ADDR_NULL_RULES () {
if [ -z "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ]; then

    # 允许任意远端地址及端口访问本地指定端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许任意远端地址及端口访问本地指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump ACCEPT"

    # 禁止任意远端地址及端口访问本地指定端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止任意远端地址及端口访问本地指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --protocol ${PROTOCOL} --destination-port ${LOCAL_PORT} --jump DROP"

    # 允许任意远端地址通过指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许任意远端地址通过指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump ACCEPT"

    # 禁止任意远端地址通过指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止任意远端地址通过指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --protocol ${PROTOCOL} --source-port ${REMOTE_PORT} --jump DROP"
    fi
fi
}

# 只添加远端地址及本地地址
ONLY_REMOTE_LOCAL_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] || [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ -z "${PROTOCOL}" ]; then

    # 允许指定远端地址访问
    if [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址：${REMOTE_ADDR} 访问${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --jump ACCEPT"

    # 禁止指定远端地址访问
    elif [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址：${REMOTE_ADDR} 访问${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --jump DROP"

    # 允许指定本地地址被访问
    elif [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定本地地址：${LOCAL_ADDR} 被访问${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --jump ACCEPT"

    # 禁止指定本地地址被访问
    elif [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定访问本地地址：${LOCAL_ADDR} 被访问${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --destination ${LOCAL_ADDR} --jump DROP"

    # 允许指定远端地址访问本地地址
    elif [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：允许指定远端地址: ${REMOTE_ADDR} 访问本地地址: ${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --jump ACCEPT"

    # 禁止指定远端地址访问本地地址
    elif [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}在 filter 表 ${TABLE_CHAIN} 链下添加：禁止指定远端地址: ${REMOTE_ADDR} 访问本地地址: ${LOCAL_ADDR}${RES}"
        IPTABLES_RULES="${TABLE_CHAIN} --source ${REMOTE_ADDR} --destination ${LOCAL_ADDR} --jump DROP"
    fi

fi
}






