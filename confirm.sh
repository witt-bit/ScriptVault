#!/bin/bash

# 定义 usage 信息
usage() {
  cat <<EOF
Usage: $(basename "$0") [options]
该脚本用于确认危险操作，将在CONFIRM_TIMEOUT(1800)秒后超时退出，需要用户手动确认下一步操作
使用前需要预加载该脚本

Functions:
  doConfirm        确认函数


Aguments:
  CONFIRM_TIMEOUT 等待确认超时时间，默认1800秒

Examples:
  doConfirm "Exec SQL Script : missing_exams.sql"
EOF
}

# 判断全局变量__LOG_LEVEL_COLORS不存在，则执行脚本log.sh
if [ -z "${__LOG_LEVEL_COLORS+x}" ]; then
  source ./log.sh
fi

# 确认选项，在执行数据变更操作前调用
CONFIRM_TIMEOUT=1800
doConfirm() {
	if ! read -r -t "${CONFIRM_TIMEOUT}" -n 1 -p  "Continue $1 [y/n] ?" input ; then
		# 超时
		log "${LOG_LEVEL_ERROR}" "Confirm timeout , exit ...";
	    exit 2;
	fi

	# 根据用户输入决定是否继续
	case "${input}" in
	    [Yy])
			echo -e "\nConfirmed ! Continue ...";
			log "${LOG_LEVEL_INFO}" "Confirmed ! Continue ...";
	        ;;
	    [Nn])
			echo -e "\nUser cancel !";
			log "${LOG_LEVEL_WARN}" "User cancel !";
	        exit 0
	        ;;
	    *)
	        echo -e "\nInvalid input ${input}, exit ...";
			log "${LOG_LEVEL_ERROR}" "Invalid input ${input}, exit ...";
	        exit 4
	        ;;
	esac
}
