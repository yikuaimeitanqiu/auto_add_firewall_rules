#!/bin/bash

# 检测防火墙策略所需的 "IPV4地址/端口号/协议类型/动作" 函数
# 用于添加删除防火墙策略时作为变量检测使用

# 获取当前脚本所在的目录路径
LIB_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 获取字体颜色
source "${LIB_SCRIPT_PATH}"/../conf/color.sh &>/dev/null


# 输入远端地址参数,只匹配IPV4
REMOTE_ADDR_TEST () {
if [ -n "${REMOTE_ADDR}" ]; then
	if [[ "${REMOTE_ADDR}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		:
	elif [[ "${REMOTE_ADDR}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
		REMOTE_MASK=$(awk -F / '{printf $2}' <<< "${REMOTE_ADDR}")
		if [ "${REMOTE_MASK}" -lt "0" -o "${REMOTE_MASK}" -gt "32" ]; then
			printf "${RED_COLOR}请正确输入远端网络地址的掩码号范围： 0-32 \n${RES}"
			exit 1
		fi
	else
		printf "${RED_COLOR}请正确输入远端网络地址 x.x.x.x | x.x.x.x/xx \n${RES}"
    exit 1
	fi
fi
}

# 输入本地地址参数,只匹配IPV4
LOCAL_ADDR_TEST () {
if [ -n "${LOCAL_ADDR}" ]; then
	if [[ "${LOCAL_ADDR}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
		:
	elif [[ "${LOCAL_ADDR}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
		LOCAL_MASK=$(awk -F / '{printf $2}' <<< "${LOCAL_ADDR}")
		if [ "${LOCAL_MASK}" -lt "0" -o "${LOCAL_MASK}" -gt "32" ]; then
			printf "${RED_COLOR}请正确输入本地网络地址的掩码号范围： 0-32 \n${RES}"
			exit 1
		fi
	else
		printf "${RED_COLOR}请正确输入本地网络地址 x.x.x.x | x.x.x.x/xx \n${RES}"
    exit 1
	fi
fi
}

# 输入远端端口号,并检测正确性
REMOTE_PORT_TEST () {
if [ -n "${REMOTE_PORT}" ]; then
  REMOTE_PORT_NUM_1=$(grep -E '^[[:digit:]]*$' <<< "${REMOTE_PORT}")
  REMOTE_PORT_NUM_2=$(grep -E '^[[:digit:]]*-[[:digit:]]*$' <<< "${REMOTE_PORT}")
  if [ -n "${REMOTE_PORT_NUM_1}" ]; then
  	if [ "${REMOTE_PORT_NUM_1}" -lt "1" -o "${REMOTE_PORT_NUM_1}" -gt "65535" ]; then
  		printf "${RED_COLOR}请正确输入远端端口号范围： 1-65535 \n${RES}"
      exit 1
  	fi
  elif [ -n "${REMOTE_PORT_NUM_2}" ]; then
  	REMOTE1=$(awk -F - '{printf $1}' <<< "${REMOTE_PORT_NUM_2}")
  	REMOTE2=$(awk -F - '{printf $2}' <<< "${REMOTE_PORT_NUM_2}")
    REMOTE1_NUM=$(grep -E '^[[:digit:]]*$' <<< "${REMOTE1}")
    REMOTE2_NUM=$(grep -E '^[[:digit:]]*$' <<< "${REMOTE2}")
  	if [ -n "${REMOTE1_NUM}" -o -n "${REMOTE2_NUM}" ]; then
  		if [ "${REMOTE1}" -lt "1" -o "${REMOTE1}" -gt "65535" ]; then
  			printf "${RED_COLOR}请正确输入远端端口号范围： (1-65535)-(1-65535) \n${RES}"
  			exit 1
  		fi
      if [ "${REMOTE2}" -lt "1" -o "${REMOTE2}" -gt "65535" ]; then
	      printf "${RED_COLOR}请正确输入远端端口号范围： (1-65535)-(1-65535) \n${RES}"
  	    exit 1
  	  fi
  	else
  		printf "${RED_COLOR}请正确输入远端端口号范围： (1-65535)-(1-65535) \n${RES}"
      exit 1
  	fi
  else
    printf "${RED_COLOR}请正确输入数字类型的远端端口号范围 \n${RES}"
    exit 1
  fi
fi
}

# 输入本地端口号,并检测正确性
LOCAL_PORT_TEST () {
if [ -n "${LOCAL_PORT}" ]; then
  LOCAL_PORT_NUM_1=$(grep -E '^[[:digit:]]*$' <<< "$LOCAL_PORT")
  LOCAL_PORT_NUM_2=$(grep -E '^[[:digit:]]*-[[:digit:]]*$' <<< "$LOCAL_PORT")
  if [ -n "${LOCAL_PORT_NUM_1}" ]; then
  	if [ "${LOCAL_PORT_NUM_1}" -lt "1" -o "${LOCAL_PORT_NUM_1}" -gt "65535" ]; then
  		printf "${RED_COLOR}请正确输入本地端口号范围： 1-65535 \n${RES}"
      exit 1
  	fi
  elif [ -n "${LOCAL_PORT_NUM_2}" ]; then
  	LOCAL1=$(awk -F - '{printf $1}' <<< "${LOCAL_PORT_NUM_2}")
  	LOCAL2=$(awk -F - '{printf $2}' <<< "${LOCAL_PORT_NUM_2}")
    LOCAL1_NUM=$(grep -E '^[[:digit:]]*$' <<< "${LOCAL1}")
    LOCAL2_NUM=$(grep -E '^[[:digit:]]*$' <<< "${LOCAL2}")
  	if [ -n "${LOCAL1_NUM}" -o -n "${LOCAL2_NUM}" ]; then
  		if [ "${LOCAL1}" -lt "1" -o "${LOCAL1}" -gt "65535" ]; then
  			printf "${RED_COLOR}请正确输入本地端口号范围： (1-65535)-(1-65535) \n${RES}"
  			exit 1
  		fi
      if [ "${LOCAL2}" -lt "1" -o "${LOCAL2}" -gt "65535" ]; then
        printf "${RED_COLOR}请正确输入本地端口号范围： (1-65535)-(1-65535) \n${RES}"
        exit 1
      fi
  	else
  		printf "${RED_COLOR}请正确输入本地端口号范围： (1-65535)-(1-65535) \n${RES}"
      exit 1
  	fi
  else
    printf "${RED_COLOR}请正确输入数字类型的本地端口号范围\n${RES}"
    exit 1
  fi
fi
}

# 远端端口号与本地端口号只能开放一个
REMOTE_LOCAL_PORT_TEST () {
# 在未配置地址时,判断到远端端口和本地端口均输入，退出脚本,因防火墙富规则只允许指定一个端口号
if [ -z "${REMOTE_ADDR}" -a -z "${LOCAL_ADDR}" -a -n "${REMOTE_PORT}" -a -n "${LOCAL_PORT}" ]; then 
	printf "${RED_COLOR}\n请正确填入限制的端口访问的位置，不可同时选择远端端口及本地端口\n${RES}"
	exit 1
fi

# 在未配置地址时,判断到远端端口和本地端口均为空，退出脚本,因防火墙富规则至少指定一个端口号
if [ -z "${REMOTE_ADDR}" -a -z "${LOCAL_ADDR}" -a -z "${REMOTE_PORT}" -a -z "${LOCAL_PORT}" ]; then 
	printf "${RED_COLOR}\n请正确填入限制的端口访问的位置，远端地址和端口及本地地址和端口不可同时为空\n${RES}"
	exit 1
fi

# 在配置远端地址后,判断同时配置远端端口和本地端口，退出脚本,因防火墙富规则只允许指定一个端口号
if [ -n "${REMOTE_ADDR}" -a -z "${LOCAL_ADDR}" -a -n "${REMOTE_PORT}" -a -n "${LOCAL_PORT}" ]; then 
	printf "${RED_COLOR}\n请正确填入限制的端口访问的位置，不可同时选择远端端口及本地端口\n${RES}"
	exit 1
fi

# 在配置本地地址后,判断同时配置远端端口和本地端口，退出脚本,因防火墙富规则只允许指定一个端口号
if [ -z "${REMOTE_ADDR}" -a -n "${LOCAL_ADDR}" -a -n "${REMOTE_PORT}" -a -n "${LOCAL_PORT}" ]; then 
	printf "${RED_COLOR}\n请正确填入限制的端口访问的位置，不可同时选择远端端口及本地端口\n${RES}"
	exit 1
fi
}

# 输入协议类型
PROTOCOL_TEST () {
# 匹配系统中储存的协议文件格式,该文件是根据IANA列表创建,详情请看/etc/protocols
PROTOCOL_NULL=$(grep -v -E "^$" /etc/protocols | grep -v -E "^#" | awk -F " " '{print $1}' | grep -E "^${PROTOCOL}$")
if [ -z "${PROTOCOL_NULL}" ]; then
    # 判断存在端口号,则要求传入协议类型
    if [ -n "${REMOTE_PORT}" -o -n "${LOCAL_PORT}" ]; then
	    printf "${RED_COLOR}请正确输入协议类型\n${RES}"
	    exit 1
    fi
fi
}

# 输入防火墙策略的动作类型(数字类型)
ACCEPT_DROP_TEST_NUM () {
if [ "${ACCEPT_DROP}" -eq "1" ]; then
    ACCEPT_DROP='accept'
elif [ "${ACCEPT_DROP}" -eq "2" ]; then
    ACCEPT_DROP='drop'
else
	printf "${RED_COLOR}请正确按提示输入 1/2 \n${RES}"
  exit 1
fi
}

# 输入防火墙策略的动作类型(英文类型)
ACCEPT_DROP_TEST_LETTER () {
if [ "${ACCEPT_DROP}" == "accept" -a "${ACCEPT_DROP}" == "drop" ]; then
	printf "${RED_COLOR}请正确输入指定的动作策略 accept/drop \n${RES}"
    exit 1
fi
}
