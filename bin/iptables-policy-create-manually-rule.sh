#!/usr/bin/env bash

# 根据输入参数手动添加防火墙富规则策略
#

# Check if user is root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 获取当前脚本所在的目录路径
BIN_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${BIN_SCRIPT_PATH}"/../modules/color.sh &>/dev/null

# 引用检测参数
. "${BIN_SCRIPT_PATH}"/../lib/detectionParameter.sh 

# 执行输入参数,并引入 "IPV4地址/端口号/协议类型/动作" 变量
. "${BIN_SCRIPT_PATH}"/../lib/inputControl.sh iptables
. "${BIN_SCRIPT_PATH}"/../lib/iptablesInputDetection.sh

# 引用 防火墙富规则
. "${BIN_SCRIPT_PATH}"/../lib/iptablesPolicy.sh


# 检测并开启防火墙
IPTABLES_STATUS

echo -e "\n"

# 防火墙富规则检测
REMOTE_ADDR_RULES
LOCAL_ADDR_RULES
REMOTE_LOCAL_ADDR_RULES
REMOTE_LOCAL_ADDR_NULL_RULES
ONLY_REMOTE_LOCAL_ADDR_RULES

# 判断未能匹配到规则时提示
if [ -z "${IPTABLES_RULES}" ]; then
    echo -e "${RED_COLOR}未能匹配到默认设置的表链规则，请检查参数，重新设置\n${RES}"
    exit 0
fi

# 根据检测规则输出提示进入选择执行
read -e -r -p "$(echo -e "${BLUE_COLOR}请确认: 是否使用以上手动添加防火墙策略?  (y/n)  ${RES}")" YesNo

if [ "${YesNo}" == "y" ] || [ "${YesNo}" == "Y" ]; then

    if ! iptables --table filter --check ${IPTABLES_RULES} 2>/dev/null; then

        # 先备份一下 filter 策略
        BACKUP_IPTABLES_RULES

        if iptables --table filter --append ${IPTABLES_RULES} &>/dev/null; then
            echo -e "${GREEN_COLOR}\t\t\t添加防火墙策略成功\n${RES}"
        else
            echo -e "${RED_COLOR}\t\t\t添加防火墙策略失败，请检查参数，重新设置\n${RES}"
        fi
    else
        echo -e "${GREEN_COLOR}\t\t\t添加防火墙策略成功\n${RES}"
    fi

elif [ "${YesNo}" == "n" ] || [ "${YesNo}" == "N" ]; then
    echo -e "不执行当前策略，立即退出.\n" && exit 1

else
    echo -e "${RED_COLOR}Please input : y/n \n请正确输入提示符 y/n \n${RES}" 
    exit 1

fi

# 输出对应的链表规则
if [ "${TABLE_CHAIN}" == "INPUT" ]; then 
    # 输出 INPUT 链规则
    IPTABLES_INPUT_RULES
elif [ "${TABLE_CHAIN}" == "OUTPUT" ]; then 
    # 输出 OUTPUT 链规则
    IPTABLES_OUTPUT_RULES
elif [ "${TABLE_CHAIN}" == "FORWARD" ]; then 
    # 输出 FORWARD 链规则
    IPTABLES_FORWARD_RULES
fi

exit 0


