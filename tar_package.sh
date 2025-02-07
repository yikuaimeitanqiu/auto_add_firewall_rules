#!/usr/bin/env bash


# Check if user is root 
if [ "$(id -u)" -ne 0 ]; then { echo "Error: You must be root to run this script"; exit 1; }; fi

# 脚本路径
TAR_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# 当前时间
NOW="$(date +%Y_%m%d_%H%M%S)"

# 删除生成目录
/usr/bin/rm -rf "${TAR_SCRIPT_PATH}"/distr/

# 创建目录
mkdir -p "${TAR_SCRIPT_PATH}"/distr/

# 删除脏数据
/bin/rm -rf "${TAR_SCRIPT_PATH}"/{logs,backup,log}

# 排除assembly目录,并生成tar安装包
tar --exclude="**/tar_package.sh" \
    --exclude="**/distr" \
    --exclude="**/.git" \
    --exclude="**/.gitkeep" \
    --exclude="**/.gitignore" \
    --exclude="**/publish_file_server.sh" \
    --exclude="**/.gitlab-ci.yml" \
    --exclude="**/push_storage.sh" \
    -cvzf "${TAR_SCRIPT_PATH}"/distr/auto_add_firewall_rules-x86_64-"${NOW}".tar.gz \
    -C "${TAR_SCRIPT_PATH}"/../ \
    ./auto_add_firewall_rules/


