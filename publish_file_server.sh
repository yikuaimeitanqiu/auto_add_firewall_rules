#!/bin/bash


# 脚本描述:
# 1. 推送安装包到smb服务器上
#

# Check if user is root
if [ "$(id -u)" -ne 0 ]; then { echo "Error: You must be root to run this script"; exit 1; }; fi

# 脚本路径
SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# 自动读取当前环境的系统架构
ARCH="$(arch)"

# SMB登陆帐号
SMB_USER='guweisheng@genew.cn'

# SMB登陆密码
# base64 加密密码: echo -n 'xxxx' | base64
SMB_BASE64_PASS='TnVjbGV1cyExMjM='

# SMB服务器配置:
# 需要填写到共享文件夹路径,以unix共享路径 "/"
SMB_HOST='//10.8.1.2/Test'

# 不同版本上传至对应目录下
# x86_64 版本
if [ "${ARCH}" == "x86_64" ]; then
    # SMB上传目录路径
    # 从共享路径下上传时,需要切换到windows的路径 "\"
    SMB_UPLOAD_PATH='TestVer\NuMax\support\Centos\自动配置防火墙策略(三级等保)_Linux'

# aarch64 版本
elif [ "${ARCH}" == "aarch64" ]; then
    # SMB上传目录路径
    # 从共享路径下上传时,需要切换到windows的路径 "\"
    SMB_UPLOAD_PATH='TestVer\NuMax\support\Centos\自动配置防火墙策略(三级等保)_Linux'
fi

# 使用入参1
COMMAND="${1}"

# 推送到smb文件服务器中,在Linux下适用
if [ "${COMMAND}" == 'publish_smb' ]; then

    # 安装smb客户端(samba-client.x86_64 : Samba client programs)
    if ! grep -E "^samba-client" <<< "$(rpm -qa)" 1>/dev/null; then
        yum install samba-client -y
    fi

    # 获取打包生成安装包
    UPLOAD_FILE_PATH="$(find "${SCRIPT_PATH}"/distr/ -type f -name "*.tar.gz" )"

    # 判断 distr 下存在对应安装zip包,则执行上传
    if [ -f "${UPLOAD_FILE_PATH}" ]; then
        echo -e "\033[0;33m\nStart to publish to SMB...\n\033[0m"

        # 获取安装包文件名
        UPLOAD_FILE="$(basename "${UPLOAD_FILE_PATH}" )"

        # 判断是否存在 base64 可执行命令
        command -v base64 1>/dev/null
        if [ $? -eq 0 ]; then

            # 解密密码
            SMB_PASS="$(echo -n "${SMB_BASE64_PASS}" | base64 -d)"

            # 上传smb文件,覆盖形式
            # EOF 中间需要前导的制表符,结尾不允许任何其它字符
            smbclient "${SMB_HOST}" -U "${SMB_USER}"%"${SMB_PASS}" <<-EOF
				cd "${SMB_UPLOAD_PATH}"
				prompt
				put "${UPLOAD_FILE_PATH}" "${UPLOAD_FILE}"
				exit
			EOF

            echo -e "\033[0;32m\nEnd...\n\n\033[0m"

        else 
            echo -e "\033[0;31m\nbase64 command not found!!!\n\033[0m"
            exit 1
        fi
    fi

# 没有入参数,则提示
else
    echo -e "\033[0;31m\nIf you need to push to the file server, enter \"publish_smb\" as the input parameter\n\033[0m"
    exit 1

fi

exit 0


