#!/bin/bash

# 打印已生效的防火墙策略,并给策略编排号码展示
# 通过用户输入编号删除对应防火墙策略

# Check if user is root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 获取当前脚本所在的目录路径
BIN_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 生成时间变量
TIME="$(date +%Y%m%d_%H%M%S)"

# 引用 防火墙富规则
. "${BIN_SCRIPT_PATH}"/../lib/richRulesPolicy.sh

# 获取字体颜色
. "${BIN_SCRIPT_PATH}"/../conf/color.sh &>/dev/null

# 判断防火墙未运行,退出
Firewall_Status_Stop

# 判断防火墙富规则为空，则打印提示，并退出
RICH_RULES_NULL=$(firewall-cmd --list-rich-rules)
if [ -z "${RICH_RULES_NULL}" ]; then
	printf "${RED_COLOR}当前防火墙未生效任何富规则策略。\n${RES}"
    exit 1 
fi

# 查询已生效的防火墙策略，并输出文件记录,主要用作记录防火墙历史策略,可回溯策略
firewall-cmd --list-rich-rules | awk '{print NR,"#",$0}'  2>&1 | tee "${BIN_SCRIPT_PATH}"/../log/create/firewall_rules_before_"${TIME}".log

# 选择删除策略
read -e -p "
$(echo -e "${RED_COLOR}请输入要删除防火墙策略的对应编号: ${RES}")" DELETE_NUM

# 判断是否为纯数字字符串,否则不执行
if [[ "${DELETE_NUM}" =~ ^[0-9]+$ ]]; then
    # 输入编码小于1,提示退出
    if [ "${DELETE_NUM}" -lt 1 ]; then
	    printf "${RED_COLOR}编号输入有误，请重新执行。\n${RES}"
        exit 1 
    fi

    # 判断无此编号防火墙策略,提示退出
    DELETE_NUM_RULE=$(awk "NR==${DELETE_NUM}" "${BIN_SCRIPT_PATH}"/../log/create/firewall_rules_before_"${TIME}".log | awk -F "#" '{print $2}')
    if [ -z "${DELETE_NUM_RULE}" ]; then
        printf "${RED_COLOR}无此编号策略,退出删除\n${RES}"
        exit 1
    fi
else
    printf "${RED_COLOR}请输入数字编号\n${RES}"
    exit 1
fi

# 打印选中的待删除的已生效的防火墙策略
printf "${RED_COLOR}\n%s\n${RES}" "${DELETE_NUM_RULE}"

# 进一步提示确认是否执行删除防火墙策略
read -e -p "
$(echo -e "${BLUE_COLOR}请确认删除当前选中防火墙策略? (y/n) ${RES}")" YesNo
if [ "${YesNo}" == "Y" -o "${YesNo}" == "y" ]; then
	firewall-cmd --permanent --remove-rich-rule="${DELETE_NUM_RULE}" &>/dev/null
	[ $? -eq 0 ] && printf "${GREEN_COLOR}防火墙策略删除成功\n${RES}"	
    firewall-cmd --reload &>/dev/null

elif [ "${YesNo}" == "N" -o "${YesNo}" == "n" ]; then
	printf "${GREEN_COLOR}不删除选中的防火墙策略\n${RES}"

else 
	printf "${RED_COLOR}请输入正确的 (y/n) \n${RES}"
fi

