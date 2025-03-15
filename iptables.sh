#!/usr/bin/env bash


# 脚本描述:
#
#



# 检测用户是否为root
[ "$(id -u)" -ne 0 ] && { echo "Error: You must be root to run this script"; exit 1; }

# 获取当前脚本所在的目录路径
SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
. "${SCRIPT_PATH}"/modules/string_color.sh &>/dev/null

# 检查 iptables 状态
. "${SCRIPT_PATH}"/lib/iptablesPolicy.sh &>/dev/null

# 检查防火墙状态
IPTABLES_STATUS

# 添加上ssh服务
IPTABLES_SSH

# 添加禁用icmp规则
IPTABLES_DROP_ICMP

# 手动添加规则
"${SCRIPT_PATH}"/bin/iptables-policy-create-manually-rule.sh


