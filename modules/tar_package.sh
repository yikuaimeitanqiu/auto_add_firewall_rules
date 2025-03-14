#!/bin/bash

# 脚本描述:
# 将 redis 生成 tar/zip 安装包


# Check if user is root 
if [ "$(id -u)" -ne 0 ]; then { echo "Error: You must be root to run this script"; exit 1; }; fi

# 脚本路径
TAR_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 第一个入参
COMMAND_FIRST="${1}"

# 引用配置文件
# . "${TAR_SCRIPT_PATH}"/../config/general_config.conf &>/dev/null

# 引用字体颜色输出模块
. "${TAR_SCRIPT_PATH}"/string_color.sh &>/dev/null 

# 创建编译打包目录
if [ ! -d "${TAR_SCRIPT_PATH:?}"/../distr ]; then
    /usr/bin/mkdir -p "${TAR_SCRIPT_PATH:?}"/../distr/
fi

# 生成压缩包名称
# 获取当前脚本路径上两级目录文件夹名称
PARENT_NAME="$( basename "$(dirname "${TAR_SCRIPT_PATH}")" )"

# 创建 tar 安装包
# 入参为 tar 或空入参时
if [ "${COMMAND_FIRST}" == 'tar' ] || [ -z "${COMMAND_FIRST}" ]; then

    # 查找tar命令
    if command -v tar 1>/dev/null; then

        # 删除已存在的文件
        if [ -e "${TAR_SCRIPT_PATH:?}"/../distr/"${PARENT_NAME:?}".tar.gz ]; then
            /usr/bin/rm -f "${TAR_SCRIPT_PATH:?}"/../distr/"${PARENT_NAME:?}".tar.gz
        fi

        # 生成tar安装包
        if tar -cvzf "${TAR_SCRIPT_PATH}"/../distr/"${PARENT_NAME:?}".tar.gz \
            -C "${TAR_SCRIPT_PATH:?}/../../" \
            --exclude="**/.git" \
            --exclude="**/.gitkeep" \
            --exclude="**/.gitignore" \
            --exclude="**/logs" \
            --exclude="**/log" \
            --exclude="**/distr" \
            --exclude="**/backup" \
            --exclude="**/.gitlab-ci.yml" \
            --exclude="**/tar_package.sh" \
            --exclude="**/build_package.sh" \
            --exclude="**/scp_files_storage.sh" \
            --exclude="**/publish_file_server.sh" \
            "${PARENT_NAME:?}"/ ; 
        then

            # 打印成功提示
            TIPS_MSG "Packaged output path: "${TAR_SCRIPT_PATH}"/../distr/"${PARENT_NAME}".tar.gz"
            SUCCEED_MSG "End"

        # 压缩失败
        else
            ERROR_MSG "Failed to execute successfully!"
            exit 127
        fi
    # 未找到tar命令提示
    else
        FAILED_MSG "tar command not found!"
        exit 127
    fi

fi


