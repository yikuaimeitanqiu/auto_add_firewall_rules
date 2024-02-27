#!/bin/bash

# 根据自定义模板,自动添加防火墙富规则策略
# 将读取模板目录下所有的".conf"文件,并按行匹配富规则,最终生成防火墙策略

# 获取当前脚本所在的目录路径
BIN_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
source "${BIN_SCRIPT_PATH}"/../conf/color.sh &>/dev/null

# 引用 "IPV4地址/端口号/协议类型/动作策略" 检测函数
source "${BIN_SCRIPT_PATH}"/../lib/detectionParameter.sh

# 引用 防火墙富规则
source "${BIN_SCRIPT_PATH}"/../lib/richRulesPolicy.sh

# 检测并开启防火墙
Firewall_Status

# 默认添加"SSH"服务连接
Firewall_SSH

# 自动装配的配置文件路径
Import_Path="$(find "${BIN_SCRIPT_PATH}"/../conf -type f | grep -E ".conf$")"

# 正则表达式,匹配模板策略
REGULAR='^#.+([0-9]+|.*-.*)#.+#(accept|drop)#$'

# 循环取自定义配置模板,并进行配置
echo "${Import_Path}" | while read Import_Paths; do 

    # 匹配过滤符合规则的防火墙策略,不符合的不执行添加
    grep -E "${REGULAR}" "${Import_Paths}" | while read ListStrategy; do
  
        # 远端地址
        REMOTE_ADDR=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $2}')
        REMOTE_ADDR_TEST
        # 远端端口
        REMOTE_PORT=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $3}')
        REMOTE_PORT_TEST
        # 本地地址
        LOCAL_ADDR=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $4}')
        LOCAL_ADDR_TEST
        # 本地端口
        LOCAL_PORT=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $5}')
        LOCAL_PORT_TEST
        # 检测远端与本地端口只能填写一个
        REMOTE_LOCAL_PORT_TEST
        # 协议类型
        PROTOCOL=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $6}')
        PROTOCOL_TEST
        # 动作策略
        ACCEPT_DROP=$(grep -E "${REGULAR}" <<< "${ListStrategy}" | awk -F '#' '{print $7}')
        ACCEPT_DROP_TEST_LETTER


        # 防火墙富规则检测
        REMOTE_ADDR_RULES
        LOCAL_ADDR_RULES
        REMOTE_LOCAL_ADDR_RULES 
        REMOTE_LOCAL_ADDR_NULL_RULES
        ONLY_REMOTE_LOCAL_ADDR_RULES

        # 从富规则检测出来变量进行添加防火墙策略,并输出结果
        firewall-cmd --permanent --add-rich-rule="${RichRules}" &>/dev/null
        if [ $? = 0 ]; then 
            printf "${GREEN_COLOR}\t添加防火墙策略成功\n${RES}" 
            firewall-cmd --reload &>/dev/null 
        else
            printf "${RED_COLOR}\t添加防火墙策略失败，请检查参数，重新设置\n${RES}"
        fi

  done 

done
