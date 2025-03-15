#!/usr/bin/env bash


# 脚本描述:
#
#



# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${LIB_SCRIPT_PATH}"/../modules/color.sh &>/dev/null

# 输入防火墙策略的动作类型(数字类型)
TABLE_CHAIN_TEST_NUM () {
if [ "${TABLE_CHAIN_NUM}" -eq "1" ]; then
    TABLE_CHAIN='INPUT'
elif [ "${TABLE_CHAIN_NUM}" -eq "2" ]; then
    TABLE_CHAIN='OUTPUT'
elif [ "${TABLE_CHAIN_NUM}" -eq "3" ]; then
    TABLE_CHAIN='FORWARD'
else
    echo -e "${RED_COLOR}请正确按提示输入 1/2/3 \n${RES}"
    exit 1
fi
}
# 输入防火墙策略的动作类型
read -e -r -p "$(\
echo -e "${BLUE_COLOR}请选择添加到默认filter表下的哪个链中：1.INPUT 2.OUTPUT 3.FORWARD (1/2/3):  ${RES}"\
)" TABLE_CHAIN_NUM

TABLE_CHAIN_TEST_NUM

