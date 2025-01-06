#!/bin/bash
set -e

# 获取系统类型信息
id_like=$(grep 'ID_LIKE' /etc/os-release)
os_id=$(grep '^ID=' /etc/os-release | awk -F '=' '{print $2}' | tr -d '\"')
is_huawei=$(grep "Huawei" /etc/os-release > /dev/null && echo "true"  || echo "false")
is_aliyun=$(grep "Alibaba" /etc/os-release > /dev/null && echo "true"  || echo "false")
is_euler=$(grep "openEuler" /etc/os-release > /dev/null && echo "true"  || echo "false")
is_anolis=$(grep "Anolis" /etc/os-release > /dev/null && echo "true"  || echo "false")

# 根据系统类型设置os变量
if [[ "$id_like" =~ "rhel" || "$id_like" =~ "fedora" || "$id_like" =~ "centos" ]]; then
    os="centos"
elif [[ "$is_huawei" == "true" || "$is_aliyun" == "true" || "$is_euler" == "true" || "$is_anolis" == "true" ]]; then
    os="centos"
elif [[ "$os_id" == "debian" || "$id_like" =~ "debian" ]]; then
    os="debian"
else
    os="unknown"
fi

# 根据操作系统类型执行相应操作
if [[ "$os" == "centos" ]]; then
    # 在CentOS上安装git并克隆、安装软件
    echo "在类CentOS8系统上安装MyFreeSWITCH..."
    if [[ ! -e "centos/myfs.latest.so.centos8.bin"  ]];then
        yum install -y git
        git clone https://e.coding.net/g-yzfk7380/myfs/centos.git
    fi
    cd centos
    chmod 755 myfs.latest.so.centos8.bin && ./myfs.latest.so.centos8.bin install
elif [[ "$os" == "debian" ]]; then
    # 在Debian上安装git并克隆、安装软件
    echo "在类Debian12系统上安装MyFreeSWITCH..."
    if [[ ! -e "centos/myfs.latest.so.debian.bin"  ]];then
        apt update && apt install -y git
        git clone https://e.coding.net/g-yzfk7380/myfs/debian.git
    fi
    cd debian
    chmod 755 myfs.latest.so.debian.bin && ./myfs.latest.so.debian.bin install
else
    echo "未知的操作系统类型"
    exit 255
fi
