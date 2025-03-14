#!/bin/bash

# 防火墙富规则策略
# 通过远端地址和本地地址 四种组合的完成富规则设置

# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${LIB_SCRIPT_PATH}"/../modules/color.sh &>/dev/null

# 默认添加 SSH 服务连接,防止会话连接中断
Firewall_SSH () {

    # 获取可能已调整的 ssh 端口号
    if [ -f /etc/ssh/sshd_config ]; then
        NEW_SSH_PORT="$( grep -E '^Port ' /etc/ssh/sshd_config | grep -oE '[0-9]{1,5}')"
        if [ -n "${NEW_SSH_PORT}" ]; then
            firewall-cmd --permanent --add-port="${NEW_SSH_PORT}"/tcp &>/dev/null
        fi
    fi

    # 添加默认ssh服务
    firewall-cmd --permanent --add-service=ssh &>/dev/null
    firewall-cmd --reload &>/dev/null
}

# 检查防火墙是否开启,未运行则运行,如果运行失败则不往下执行
Firewall_Status () {
Firewall_State="$(firewall-cmd --state &>/dev/null && echo 'running')"
if [ -z "${Firewall_State}" ]; then
    # 默认发行版本已用 systemctl 管理服务
    if ! command -v systemctl 1>/dev/null; then
        echo -e "${RED_COLOR}systemctl 命令未能检查到，无法启动防火墙.\n${RES}" 
        exit 127
    fi

    # 检查防火墙，并尝试启动
    if systemctl start firewalld 1>/dev/null; then
        if firewall-cmd --state &>/dev/null ; then
            echo -e "${GREEN_COLOR}防火墙已开启\n${RES}" 
        else
            systemctl status firewalld
            echo -e "${RED_COLOR}防火墙开启失败,请检查原因,再执行此脚本.\n${RES}" 
            exit 1
        fi
    else
        systemctl status firewalld
        echo -e "${RED_COLOR}防火墙开启失败,请检查原因,再执行此脚本.\n${RES}" 
        exit 1
    fi
fi
}

# 检查防火墙未开启,不往下执行
Firewall_Status_Stop () {
Firewall_State="$( grep -E '^running$' <<< "$(firewall-cmd --state)" )"
if [ -z "${Firewall_State}" ]; then
    echo -e "${RED_COLOR}当前防火墙未在运行状态,执行删除策略可能会存在问题,将不执行脚本,退出.\n${RES}" 
    exit 1
fi
}

# 远端地址不空，本地地址为空
REMOTE_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ];then

    # 允许指定远端地址访问本地端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址:${REMOTE_ADDR} 访问本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} accept"

    # 禁止指定远端地址访问本地端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址:${REMOTE_ADDR} 访问本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} drop"

    # 允许指定的远端地址及指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址:${REMOTE_ADDR} 指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} accept"

    # 禁止指定的远端地址及指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址:${REMOTE_ADDR} 指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} drop"
    fi
fi
}


# 远端地址为空，本地地址不为空
LOCAL_ADDR_RULES () {
if [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ];then
	
    # 允许任意远端地址及端口访问指定本地地址及指定本地端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许任意远端地址及端口访问指定本地地址:${LOCAL_ADDR} 指定本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 destination address=${LOCAL_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} accept"

    # 禁止任意远端地址及端口访问指定本地地址及指定本地端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止任意远端地址及端口访问指定本地地址:${LOCAL_ADDR} 指定本地端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 destination address=${LOCAL_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} drop"

    # 允许任意远端地址及指定远端端口访问指定本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许任意远端地址及指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址:${LOCAL_ADDR}${RES}"
        RichRules="rule family=ipv4 destination address=${LOCAL_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} accept"

    # 禁止任意远端地址及指定端口访问指定本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止任意远端地址及指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址:${LOCAL_ADDR}${RES}"
    RichRules="rule family=ipv4 destination address=${LOCAL_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} drop"
    fi
fi
}


# 远端地址及本地地址均不为空
REMOTE_LOCAL_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ]; then

    # 允许指定远端地址访问指定本地地址的指定端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址：${REMOTE_ADDR} 访问指定本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} destination address=${LOCAL_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} accept"

    # 禁止指定远端地址访问指定本地地址的指定端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址：${REMOTE_ADDR} 访问指定本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} destination address=${LOCAL_ADDR} port port=${LOCAL_PORT} protocol=${PROTOCOL} drop"

    # 允许指定远端地址通过指定远端端口访问指定本地地址
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} destination address=${LOCAL_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} accept"

    # 禁止指定远端地址通过指定远端端口访问指定本地地址
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} destination address=${LOCAL_ADDR} source-port port=${REMOTE_PORT} protocol=${PROTOCOL} drop"

    # 允许指定远端地址通过指定远端端口访问指定本地地址的指定端口
    elif [ -n "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}${RES}"
        echo -e "\n\n${RED_COLOR}远端端口与本地端口不可时存在规则中,无法完成添加!!!${RES}\n"
        RichRules=""

    # 禁止指定远端地址通过指定远端端口访问指定本地地址的指定端口
    elif [ -n "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址：${REMOTE_ADDR} 通过指定远端端口:${REMOTE_PORT}/${PROTOCOL} 访问本地地址：${LOCAL_ADDR} 的指定端口:${LOCAL_PORT}${RES}"
        echo -e "\n\n${RED_COLOR}远端端口与本地端口不可时存在规则中,无法完成添加!!!${RES}\n"
        RichRules=""
    fi
fi
}


# 远端地址及本地地址均为空
REMOTE_LOCAL_ADDR_NULL_RULES () {
if [ -z "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -n "${PROTOCOL}" ]; then

    # 允许任意远端地址及端口访问本地指定端口
    if [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许任意远端地址及端口访问本地指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 port port=${LOCAL_PORT} protocol=${PROTOCOL} accept"

    # 禁止任意远端地址及端口访问本地指定端口
    elif [ -z "${REMOTE_PORT}" ] && [ -n "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止任意远端地址及端口访问本地指定端口:${LOCAL_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 port port=${LOCAL_PORT} protocol=${PROTOCOL} drop"

    # 允许任意远端地址通过指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许任意远端地址通过指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source-port port=${REMOTE_PORT} protocol=${PROTOCOL} accept"

    # 禁止任意远端地址通过指定远端端口访问本地
    elif [ -n "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止任意远端地址通过指定远端端口:${REMOTE_PORT}/${PROTOCOL}${RES}"
        RichRules="rule family=ipv4 source-port port=${REMOTE_PORT} protocol=${PROTOCOL} drop"
    fi
fi
}

# 只添加远端地址及本地地址
ONLY_REMOTE_LOCAL_ADDR_RULES () {
if [ -n "${REMOTE_ADDR}" ] || [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ -z "${PROTOCOL}" ]; then

    # 允许指定远端地址访问
    if [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址：${REMOTE_ADDR} 访问${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} accept"

    # 禁止指定远端地址访问
    elif [ -n "${REMOTE_ADDR}" ] && [ -z "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址：${REMOTE_ADDR} 访问${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} drop"

    # 允许指定本地地址被访问
    elif [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定本地地址：${LOCAL_ADDR} 被访问${RES}"
        RichRules="rule family=ipv4 destination address=${LOCAL_ADDR} accept"

    # 禁止指定本地地址被访问
    elif [ -z "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定访问本地地址：${LOCAL_ADDR} 被访问${RES}"
        RichRules="rule family=ipv4 destination address=${LOCAL_ADDR}  drop"

    # 允许指定远端地址访问本地地址
    elif [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "accept" ]; then
        echo -e "${RED_COLOR}允许指定远端地址: ${REMOTE_ADDR} 访问本地地址: ${LOCAL_ADDR}${RES}"
        RichRules="rule family=ipv4 source address=${REMOTE_ADDR} destination address=${LOCAL_ADDR} accept"

    # 禁止指定远端地址访问本地地址
    elif [ -n "${REMOTE_ADDR}" ] && [ -n "${LOCAL_ADDR}" ] && [ -z "${REMOTE_PORT}" ] && [ -z "${LOCAL_PORT}" ] && [ "${ACCEPT_DROP}" == "drop" ]; then
        echo -e "${RED_COLOR}禁止指定远端地址: ${REMOTE_ADDR} 访问本地地址: ${LOCAL_ADDR}${RES}"
        RichRules="rule family=ipv4 source addres=${REMOTE_ADDR} destination address=${LOCAL_ADDR} drop"
    fi

fi
}

# 手动启动防火墙服务
FIREWALLD_MANUAL_START () {
    systemctl enable firewalld &>/dev/null
    systemctl start firewalld &>/dev/null
}

# 手动停止防火墙服务
FIREWALLD_MANUAL_STOP () {
    systemctl disable firewalld &>/dev/null
    systemctl stop firewalld &>/dev/null
}

# 防火墙状态提示
FIREWALLD_TIP () {
    # 检测退出时,防火墙的运行状态
    firewall-cmd --state &>/dev/null \
      && echo -e "${RED_COLOR}\n温馨提醒:防火墙处在运行中.\n\n${RES}" \
      || echo -e "${RED_COLOR}\n温馨提醒:防火墙未运行!\n\n${RES}"
}



