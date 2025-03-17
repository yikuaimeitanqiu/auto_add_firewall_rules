#!/usr/bin/env bash


# 脚本描述:
#
#



# 检测用户是否为root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 获取当前脚本所在的目录路径
SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${SCRIPT_PATH}"/modules/color.sh &>/dev/null
. "${SCRIPT_PATH}"/modules/string_color.sh &>/dev/null

# 检查 iptables 状态
. "${SCRIPT_PATH}"/lib/iptablesPolicy.sh &>/dev/null

# 检查防火墙状态
IPTABLES_STATUS

# 添加上ssh服务
IPTABLES_SSH

# 添加禁用icmp规则
IPTABLES_DROP_ICMP

#打印菜单
MENU () {
echo -e "${BLUE_COLOR}\n##############################${RES}
${RED_COLOR}1.${RES} ${BLUE_COLOR}手动添加防火墙策略${RES}${RED_COLOR}(慎重)${RES}
${RED_COLOR}2.${RES} ${BLUE_COLOR}手动删除防火墙策略${RES}${RED_COLOR}(慎重)${RES}
${RED_COLOR}3.${RES} ${BLUE_COLOR}退出${RES}
${BLUE_COLOR}##############################${RES}\n"
}

# 菜单
MENU

# 判断不存在目录则创建
if [ ! -d "${SCRIPT_PATH}"/log ]; then
    /usr/bin/mkdir -p "${SCRIPT_PATH}"/log/{create,delete,query}
fi


#选项执行
while read -r -e -p "$(echo -e "${RED_COLOR}请选择输入数字: ${RES}")" Number; do

    case ${Number} in

        "1")
            # 手动添加规则
            bash "${SCRIPT_PATH}"/bin/iptables-policy-create-manually-rule.sh 2>&1 | \
                tee -a "${SCRIPT_PATH}"/log/create/create-iptables-"$(date +%Y-%m%d-%H%M%S)".log
            MENU
            ;;

        "2")
            # 手动删除规则
            bash "${SCRIPT_PATH}"/bin/iptalbes-policy-delete-manually-rule.sh 2>&1 | \
                tee -a "${SCRIPT_PATH}"/log/delete/delete-iptables-"$(date +%Y-%m%d-%H%M%S)".log
            MENU
            ;;

        "3")
            exit 0
            ;;

        *)
            echo -e "${RED_COLOR}请正确输入选项：（1/2/3）\n${RES}"
            MENU
            ;;

    esac

done

exit 0

