#!/usr/bin/env bash


# 脚本描述
# 1. 推送到网盘


# 获取当前脚本路径
PUBLISH_SCRIPT_PATH="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"


# 上传到目录
TARGET_DIR="自动配置防火墙策略(三级等保)_Linux"

# 判断生成压缩才才执行
if [ -f "${PUBLISH_SCRIPT_PATH}"/distr/*.tar.gz ]; then

    # gitlab runner 已做好ssh免密访问网盘，只需要保证上传路径无误即可
    # 推送软件包到网盘指定目录
    scp "${PUBLISH_SCRIPT_PATH}"/distr/*.tar.gz\
        root@storage.rdapp.com:/opt/lampp/htdocs/apps/vfm/uploads/common/Packages/基础环境部署包/等保/"${TARGET_DIR}"/

    # 修改软件包属组
    ssh root@storage.rdapp.com "chown -R daemon:daemon /opt/lampp/htdocs/apps/vfm/uploads/common/Packages/"

    echo -e "Push completed."

else
    echo -e "The file to be uploaded was not found. Please check whether there are errors in the packaging process."
    exit 127
fi



