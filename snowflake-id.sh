#!/bin/bash

# 定义起始时间戳（2024-01-01 00:00:00 UTC）
EPOCH=$(date -d "2000-01-01 00:00:00" +%s%3N)

# 从MAC地址中提取MACHINE_ID
MACHINE_ID=$(ip link show | grep -Po 'link/ether \K[0-9a-f:]{17}' | head -n 1 | tr -d ':' | cut -c1-8 | xxd -r -p | od -An -t u4 | tr -d ' ' | awk '{print $1 % 1024}')

# 从IP地址中提取DATACENTER_ID
IP_ADDRESS=$(ip -4 addr show scope global | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n 1)
DATACENTER_ID=$(echo $IP_ADDRESS | cut -d'.' -f3 | awk '{print $1 % 1024}')

# 序列号初始化为0
SEQUENCE=0

# 上一次的时间戳
LAST_TIMESTAMP=0

# 生成Snowflake ID的函数
next-id() {
    # 获取当前时间戳（毫秒）
    local current_timestamp=$(date +%s%N | cut -b1-13)

    # 如果当前时间戳小于上次的时间戳，则报错
    if [ "${current_timestamp}" -lt "${LAST_TIMESTAMP}" ]; then
        echo "Clock error : offset : $((LAST_TIMESTAMP - current_timestamp)) ms" >&2
        return 1
    fi

    # 如果时间戳相同，则递增序列号
    local timestamp_diff=$((current_timestamp - LAST_TIMESTAMP))
    if [ "${timestamp_diff}" -le 10 ]; then
        SEQUENCE=$(( (SEQUENCE + 1) & 4095 ))  # 12位，最大4095
        if [ "$SEQUENCE" -eq 0 ]; then
            # 序列号溢出，等待下一毫秒
            sleep 0.001
            current_timestamp=$(date +%s%N | cut -b1-13)
        fi
    else
        SEQUENCE=0
    fi

    # 更新上次的时间戳
    LAST_TIMESTAMP=$current_timestamp

    # 计算偏移时间戳
    local time_diff=$((current_timestamp - EPOCH))

    # 检查时间戳是否超过41位的限制
    local max_time_diff=$(( (1 << 41) - 1 ))
    if [ "${time_diff}" -gt "${max_time_diff}" ]; then
        echo "Time over flow : ${time_diff} > ${max_time_diff}" >&2
        return 2
    fi

    # 构建64位ID,丢进全局变量，因为$()赋值会开启子shell,导致id重复
    lastGenerateId=$(((time_diff << 22) | (DATACENTER_ID << 17) | (MACHINE_ID << 7) | SEQUENCE))
}


# 测试生成多个Snowflake ID
#for i in {1..10}; do
#    next-id 
#	echo "${lastGenerateId}";
#done
