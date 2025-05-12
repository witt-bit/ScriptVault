#!/bin/bash

# 定义 usage 信息
log_usage() {
  cat <<EOF
Log usage: $(basename "$0") [options]
该脚本用于输出日志到文件和控制台，提供DEBUG、INFO、WARN、ERROR四个日志级别
使用前需要预加载该脚本

Functions:
  log level msg   打印日志


Aguments:
  WORK_HOME              required,工作目录
  logLevel               optional,默认日志级别,默认INFO
  LOGFILE                optional,日志文件路径,默认为WORK_HOME/std.log
  LOG_CONSOLE_ENABLE     optional,是否启用日志追加终端输出
  LOG_LEVEL_DEBUG        常量,DEBUG级别
  LOG_LEVEL_INFO         常量,INFO级别
  LOG_LEVEL_WARN         常量,WARN级别
  LOG_LEVEL_ERROR        常量,ERROR级别

Examples:
  log "\$\{LOG_LEVEL_DEBUG\}" "debug msg"
  log "\$\{LOG_LEVEL_INFO\}" "info msg"
  log "\$\{LOG_LEVEL_WRAN\}" "wran msg"
  log "\$\{LOG_LEVEL_ERROR\}" "error msg"
EOF
}

# logLevel
logLevel=1;
# 是否同时将日志输出到控制台
LOG_CONSOLE_ENABLE=0;
LOG_FILE_ENABLE=1;

LOG_LEVEL_DEBUG=0;
LOG_LEVEL_INFO=1;
LOG_LEVEL_WARN=2;
LOG_LEVEL_ERROR=3;
LOG_LEVELS=("DEBUG" "INFO" "WARN" "ERROR");
__LOG_LEVEL_COLORS=("\033[37m" "\033[32m" "\033[33m" "\033[31m");

# 日志输出到所有目的地
logAppenderAll(){
  LOG_FILE_ENABLE=1;
  LOG_CONSOLE_ENABLE=1;
}

# 仅输出到终端
logAppenderConsole(){
  LOG_FILE_ENABLE=0;
  LOG_CONSOLE_ENABLE=1;
}

# 初始化日志的全局变量
_init_log_variable(){
  if [ "${LOG_FILE_ENABLE}" -eq 0 ]; then
    return;
  fi

  if [ -z "${WORK_HOME}" ]; then
    WORK_HOME=".";
    echo -e "\033[33mWORK_HOME unset,use . as WORK_HOME.\033[0m";
  fi

  if [ -n "${LOGFILE}" ]; then
    return;
  fi

  # 日志定义
  LOGFILE="${WORK_HOME}/std.log";
}

# 日志函数
log() {
  _init_log_variable;

  if [ "${LOG_FILE_ENABLE}" -eq 0 ] && [ "${LOG_CONSOLE_ENABLE}" -eq 0 ]; then
    colorEcho "${LOG_LEVEL_ERROR}" "No log appender found !";
    exit 124;
  fi

	local level="$1";
	# level不是数字或不在0-3,重置为INFO
    if ! [[ "${level}" =~ ^[0-9]+$ ]] || [ "${level}" -lt 0 ] || [ "${level}" -gt 3 ]; then
        log "${LOG_LEVEL_INFO}" "$1";
        return;
    fi

    # 非级别忽略
	if [ "${level}" -lt "${logLevel}" ]; then
		return;
	fi

	local logTime=$(date +"%Y-%m-%d %H:%M:%S.%3N");
	local color="${__LOG_LEVEL_COLORS[$level]:-__LOG_LEVEL_COLORS[1]}";
  local log_line=$(printf "${color}%s [%-5s] %s\033[0m\n" "${logTime}" "${LOG_LEVELS[$level]}" "${2}");

  # 文件
  if [ "${LOG_FILE_ENABLE}" -eq 1 ]; then
      echo "${log_line}" >> "${LOGFILE}";
  fi

  # 终端
  if [ "${LOG_CONSOLE_ENABLE}" -eq 1 ]; then
      echo "${log_line}";
      return 0;
  fi
}

# level名称转顺序
log_level_name_to_ordinal() {
  case "$1" in
    "DEBUG")
      return 0;
    ;;
    "INFO")
      return 1;
    ;;
    "WARN")
      return 2;
    ;;
    "ERROR")
      return 3;
    ;;
    *)
      echo "Unknown level $1";
      exit 1;
    ;;
  esac;
}

# 使用指定的颜色渲染字符串
colorEcho() {
  local level_ordinal=$(log_level_name_to_ordinal "$1");
  local color=$(${__LOG_LEVEL_COLORS[$level_ordinal]:-__LOG_LEVEL_COLORS[1]})
  echo -e "${color}$2\033[0m\n";
}
