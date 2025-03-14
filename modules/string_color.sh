#!/bin/bash

# 脚本描述
# 1. 提示输出颜色信息提示
#

# 循环查找支持 -e 参数的 echo 可执行文件
# 初始化变量 echo 为默认的 echo 命令
export echo=echo

# 遍历可能的 echo 命令路径
for COMMAND in echo /bin/echo; do
    # 测试当前命令是否可执行（通过检查其输出是否出错）
    ${COMMAND} >/dev/null 2>&1 || continue
    
    # 检查当前命令是否支持 -e 参数
    if ! ${COMMAND} -e "" | grep -qE '^-e'; then
        # 如果支持 -e 参数，则将命令路径赋值给变量 echo
        export echo=${COMMAND}
        # 结束循环，不再检查其他候选命令
        break
    fi
done

# 定义字体颜色变量
# 红色文字
RED="\\033[31m"

# 绿色文字
GREEN="\\033[32m"

# 黄色文字
YELLOW="\\033[33m"

# 恢复默认文字颜色（黑色）
BLACK="\\033[0m"

# 控制光标位置到第60列
# 第 60 列对齐输出，保证输出内容的整齐排列
POS="\\033[60G"


# 成功提示函数
# succeed_msg() {
SUCCEED_MSG() {
    # 使用 echo 打印成功信息，带绿色字体
    echo -e "${GREEN}[ SUCCEED ]: ${1}${POS}${BLACK}"
    # 输出一个空行
    echo ""
}


# 失败提示函数
FAILED_MSG() {
    # 使用 echo 打印失败信息，带红色字体
    echo -e "${RED}[ FAILED ]: ${1}${POS}${BLACK}"
    # 输出一个空行
    echo ""
}


# 警告提示函数
WARN_MSG() {
    # 使用 echo 打印警告信息，带黄色字体
    echo -e "${YELLOW}[ WARN ]: ${1}${POS}${BLACK}"
    # 输出一个空行
    echo ""
}


# 错误提示函数
ERROR_MSG() {
    # 使用 echo 打印错误提示信息，带红色字体
    echo -e "${RED}[ ERROR ]: ${1}${POS}${BLACK}"
    # 输出一个空行
    echo ""
}


# 提示函数
TIPS_MSG() {
    # 使用 echo 打印提示信息，带绿色字体
    echo -e "${GREEN}${1}${POS}${BLACK}"
    # 输出一个空行
    echo ""
}



