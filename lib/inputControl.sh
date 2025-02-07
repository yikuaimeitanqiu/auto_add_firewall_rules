#!/bin/bash

# 输入防火墙策略所需的 "IPV4地址/端口号/协议类型/动作" 参数
# 用于手动添加防火墙策略时作为变量使用

# 函数通过其它脚本中引用,如果在当前脚本引用会因目录层级问题,导致引用路径变量问题失败

# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
source "${LIB_SCRIPT_PATH}"/../conf/color.sh &>/dev/null

# 输入远端地址参数,只匹配IPV4
read -e -p "$(echo -e "${BLUE_COLOR}请输入限制访问的远端地址(x.x.x.x | x.x.x.x/xx):  ${RES}")" REMOTE_ADDR
REMOTE_ADDR_TEST

# 输入本地地址参数,只匹配IPV4
read -e -p "$(echo -e "${BLUE_COLOR}请输入限制访问的本地地址(x.x.x.x | x.x.x.x/xx):  ${RES}")" LOCAL_ADDR
LOCAL_ADDR_TEST

# 输入远端端口号,并检测正确性
read -e -p "$(echo -e "${BLUE_COLOR}请输入限制访问的远端端口号(远端与本地只能二选一  xx | xxx-xxx)： ${RES}")" REMOTE_PORT
REMOTE_PORT_TEST

# 输入本地端口号,并检测正确性
read -e -p "$(echo -e "${BLUE_COLOR}请输入限制访问的本地端口号(远端与本地只能二选一  xx | xxx-xxx)： ${RES}")" LOCAL_PORT
LOCAL_PORT_TEST

# 远端端口号与本地端口号只能开放一个
REMOTE_LOCAL_PORT_TEST

# 输入协议类型
read -e -p "$(echo -e "${BLUE_COLOR}请输入限制访问的协议类型(常用：tcp/udp)： ${RES}")" PROTOCOL
PROTOCOL_TEST

# 输入防火墙策略的动作类型
read -e -p "$(echo -e "${BLUE_COLOR}请选择处理规则：1.允许访问 2.拒绝访问 (1/2):  ${RES}")" ACCEPT_DROP
ACCEPT_DROP_TEST_NUM

