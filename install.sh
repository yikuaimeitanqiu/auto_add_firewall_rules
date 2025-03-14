#!/usr/bin/env bash

# 检测用户是否为root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 入参数
COMMAND="${1}"

# 获取当前脚本所在的目录路径
SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${SCRIPT_PATH}"/modules/color.sh &>/dev/null

# 验证操作系统是debian系还是centos
OS='None'

# 判断操作系统类型
if [ -e "/etc/os-release" ]; then
    # 查找匹配文件中的ID值
    ID="$(grep -E "^ID=" /etc/os-release | awk -F '=' '{print$2}' | tr -d '"')"
    case ${ID} in
        "debian" | "ubuntu" | "devuan")
            OS='Debian'
            ;;
        "centos" | "rhel fedora" | "rhel")
            OS='Centos'
            ;;
        *)
            ;;
    esac
fi

# 无法匹配文件找到时,通过命令匹配
if [ "${OS}" == 'None' ]; then
    if command -v apt-get >/dev/null 2>&1; then
        OS='Debian'
    elif command -v yum >/dev/null 2>&1; then
        OS='Centos'
    else
        echo -e "${RED_COLOR}\n不支持这个系统\n已退出\n\n${RES}"
        exit 127
    fi

# 此工具暂没适配 iptable
elif [ "${OS}" == 'Debian' ]; then
    echo -e "${RED_COLOR}\n不支持这个系统\n已退出\n\n${RES}"
    exit 127
fi


# 引用 防火墙富规则
. "${SCRIPT_PATH}"/lib/richRulesPolicy.sh


# 如果入参是 add 则自动完成默认防火墙添加
if [ "${COMMAND}" == "add" ]; then
    echo -e "${GREEN_COLOR}开始添加防火墙策略，请耐心等待...${RES}\n"	
    bash "${SCRIPT_PATH}"/bin/firewall-policy-create-auto-rule.sh 2>&1 | \
        tee -a "${SCRIPT_PATH}"/log/create/create-auto-firewall-"$(date +%Y-%m%d-%H%M%S)".log
    exit 0

# 如果入参是 del 则自动完成默认防火墙删除
elif [ "${COMMAND}" == "del" ]; then
    # 防火墙未运行不执行自动删除策略
    Firewall_Status_Stop
    echo -e "${RED_COLOR}开始删除防火墙策略，请耐心等待...${RES}\n"	
    bash "${SCRIPT_PATH}"/bin/firewall-policy-delete-auto-rule.sh 2>&1 | \
        tee -a "${SCRIPT_PATH}"/log/delete/delete-auto-firewall-"$(date +%Y-%m%d-%H%M%S)".log
    exit 0
fi


#打印菜单
MENU () {
echo -e "${BLUE_COLOR}\n##############################${RES}
${RED_COLOR}1.${RES} ${BLUE_COLOR}自动添加 *默认* 相关防火墙策略${RES}
${RED_COLOR}2.${RES} ${BLUE_COLOR}自动删除 *默认* 相关防火墙策略${RES}
${RED_COLOR}3.${RES} ${BLUE_COLOR}手动添加防火墙策略${RES}${RED_COLOR}(慎重)${RES}
${RED_COLOR}4.${RES} ${BLUE_COLOR}手动删除防火墙策略${RES}${RED_COLOR}(慎重)${RES}
${RED_COLOR}5.${RES} ${BLUE_COLOR}查看已生效的防火墙策略${RES}
${RED_COLOR}6.${RES} ${BLUE_COLOR}手动启动防火墙服务${RES}
${RED_COLOR}7.${RES} ${BLUE_COLOR}手动停止防火墙服务${RES}
${RED_COLOR}8.${RES} ${BLUE_COLOR}已完成确认，确认退出.${RES}${RED_COLOR}(请勿强制退出)${RES}
${BLUE_COLOR}##############################${RES}\n"
}


# 菜单
MENU

# 判断不存在目录则创建
if [ ! -d "${SCRIPT_PATH}"/log ]; then
    /bin/mkdir -p "${SCRIPT_PATH}"/log/{create,delete,query}
fi

# 提示语
ADD_TIPS="请问添加防火墙策略时，是否需要保险，防止被锁在墙外。添加自动定时任务，15分钟后关闭防火墙。(y/n)"
DEL_TIPS="请问删除防火墙策略时，是否需要保险，防止被锁在墙外。添加自动定时任务，15分钟后关闭防火墙。(y/n)"

#选项执行
while read -r -e -p "$(echo -e "${RED_COLOR}请选择输入数字: ${RES}")" Number; do

    case ${Number} in

        "1")
            echo -e "${GREEN_COLOR}开始添加防火墙策略，请耐心等待...${RES}\n"	
            bash "${SCRIPT_PATH}"/bin/firewall-policy-create-auto-rule.sh 2>&1 | \
                tee -a "${SCRIPT_PATH}"/log/create/create-auto-firewall-"$(date +%Y-%m%d-%H%M%S)".log
            MENU
            ;;

        "2")
            # 防火墙未运行不执行自动删除策略
            Firewall_Status_Stop
            echo -e "${GREEN_COLOR}开始删除防火墙策略，请耐心等待...${RES}\n"	
            bash "${SCRIPT_PATH}"/bin/firewall-policy-delete-auto-rule.sh 2>&1 | \
                tee -a "${SCRIPT_PATH}"/log/delete/delete-auto-firewall-"$(date +%Y-%m%d-%H%M%S)".log
            MENU
            ;;

        "3")
            read -e -r -p "$(echo -e "${RED_COLOR}${ADD_TIPS} ${RES}")" YesNo

            if [ "${YesNo}" == "Y" ] || [ "${YesNo}" == "y" ]; then
                # 将已配置的定时间隔关闭防火墙任务到crond服务下管理
                /bin/cp -rf "${SCRIPT_PATH}"/modules/wait_until_stopped_firewalld \
                            /etc/cron.d/wait_until_stopped_firewalld
                /bin/chown root:root /etc/cron.d/wait_until_stopped_firewalld
                /bin/chmod 0644 /etc/cron.d/wait_until_stopped_firewalld

                bash "${SCRIPT_PATH}"/bin/firewall-policy-create-manually-rule.sh 2>&1 | \
                    tee -a "${SCRIPT_PATH}"/log/create/create-manually-firewall-"$(date +%Y-%m%d-%H%M%S)".log

            elif [ "${YesNo}" == "N" ] || [ "${YesNo}" == "n" ]; then
                # 从crond服务中移除定时间隔关闭防火墙任务
                /bin/rm -f /etc/cron.d/wait_until_stopped_firewalld &>/dev/null
                bash "${SCRIPT_PATH}"/bin/firewall-policy-create-manually-rule.sh 2>&1 | \
                    tee -a "${SCRIPT_PATH}"/log/create/create-manually-firewall-"$(date +%Y-%m%d-%H%M%S)".log

            else
                echo -e "${RED_COLOR}请正确输入选项: (y/n) \n${RES}"
            fi
            MENU
            ;;

        "4")
            # 防火墙未运行不执行自动删除策略
            Firewall_Status_Stop

            read -e -r -p "$(echo -e "${RED_COLOR}${DEL_TIPS} ${RES}")" YesNo

            if [ "${YesNo}" == "Y" ] || [ "${YesNo}" == "y" ]; then
                # 将已配置的定时间隔关闭防火墙任务到crond服务下管理
                /bin/cp -rf "${SCRIPT_PATH}"/modules/wait_until_stopped_firewalld \
                            /etc/cron.d/wait_until_stopped_firewalld
                chown root:root /etc/cron.d/wait_until_stopped_firewalld
                chmod 0644 /etc/cron.d/wait_until_stopped_firewalld

                bash "${SCRIPT_PATH}"/bin/firewall-policy-delete-manually-rule.sh 2>&1 | \
                    tee -a "${SCRIPT_PATH}"/log/delete/delete-manually-firewall-"$(date +%Y-%m%d-%H%M%S)".log

            elif [ "${YesNo}" == "N" ] || [ "${YesNo}" == "n" ]; then
                # 从crond服务中移除定时间隔关闭防火墙任务
                /bin/rm -f /etc/cron.d/wait_until_stopped_firewalld &>/dev/null

                bash "${SCRIPT_PATH}"/bin/firewall-policy-delete-manually-rule.sh 2>&1 | \
                    tee -a "${SCRIPT_PATH}"/log/delete/delete-manually-firewall-"$(date +%Y-%m%d-%H%M%S)".log
            else

                echo -e "${RED_COLOR}请正确输入选项: (y/n) ${RES}\n"
            fi
            MENU
            ;;

        "5")
            bash "${SCRIPT_PATH}"/bin/firewall-policy-query-rule.sh 2>&1 | \
                tee -a "${SCRIPT_PATH}"/log/query/query-"$(date +%Y-%m%d-%H%M%S)".log
            MENU
            ;;

        "6")
            FIREWALLD_MANUAL_START
            FIREWALLD_TIP
            MENU
            ;;

        "7")
            FIREWALLD_MANUAL_STOP
            FIREWALLD_TIP
            MENU
            ;;

        "8")
            # 从crond服务中移除定时间隔关闭防火墙任务
            /bin/rm -f /etc/cron.d/wait_until_stopped_firewalld &>/dev/null 
            FIREWALLD_TIP
            exit 0
            ;;

        *)
            echo -e "${RED_COLOR}请正确输入选项：（1/2/3/4/5/6/7/8）\n${RES}"
            MENU
            ;;

    esac

done

