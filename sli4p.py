#!/usr/bin/python3

import inspect
import signal
import os
import atexit

from enum import Enum
from datetime import datetime

'''
日志级别定义
'''
class LogLevel(Enum):
    DEBUG = 0
    INFO = 1
    WARN = 2
    ERROR = 3

'''
日志输出目的地定义
'''
class LogDest(Enum):
    ALL = 0
    CONSOLE = 1
    FILE = 2

'''
日志类
提供日志记录功能
'''
class Logger:
    COLORS = {
        "reset": "0",
        "black": "30",
        "red": "31",
        "green": "32",
        "yellow": "33",
        "blue": "34",
        "magenta": "35",
        "cyan": "36",
        "white": "37",
        "bg_black": "40",
        "bg_red": "41",
        "bg_green": "42",
        "bg_yellow": "43",
        "bg_blue": "44",
        "bg_magenta": "45",
        "bg_cyan": "46",
        "bg_white": "47",
        "light_black": "1;30",
        "light_red": "1;31",
        "light_green": "1;32",
        "light_yellow": "1;33",
        "light_blue": "1;34",
        "light_magenta": "1;35",
        "light_cyan": "1;36",
        "light_white": "1;37",
        "light_bg_black": "100",
        "light_bg_red": "101",
        "light_bg_green": "102",
        "light_bg_yellow": "103",
        "light_bg_blue": "104",
        "light_bg_magenta": "105",
        "light_bg_cyan": "106",
        "light_bg_white": "107",
    }

    def __init__(self, LogDest=LogDest.ALL, level=LogLevel.INFO, time_format="%Y-%m-%d %H:%M:%S.%f"):
        self.level = level
        self.dest = LogDest
        self.time_format = time_format
        self.dest_file = 'std.log'
        self.file = None
        self.level_corlor = {
            LogLevel.DEBUG: 'white',
            LogLevel.INFO: 'green',
            LogLevel.WARN: 'yellow',
            LogLevel.ERROR: 'red'
        }

    def _file_close(self):
        if not self.file.closed:
            self.file.close();

    def _init_file(self):
        if self.dest == LogDest.CONSOLE:
            return

        if self.file is not None:
            return

        self.file = open(self.dest_file, 'a', encoding='utf-8', buffering=1<<16)
        # 注册关闭钩子，处理文件句柄
        atexit.register(self._file_close)
        signal.signal(signal.SIGINT, self._file_close)
        signal.signal(signal.SIGTERM, self._file_close)

    def set_dest_file(self, file_path):
        if file_path is None:
            return
        if self.dest == LogDest.CONSOLE:
            self.dest = LogDest.ALL
        self.dest_file = file_path;

    '''
    设置日志级别
    :param level: 日志级别
    :return: None
    :raise ValueError: 如果日志级别无效
    '''
    def set_level(self, level):
        if level not in LogLevel:
            raise ValueError(f"Invalid log level: {level}")
        self.level = level

    '''
    设置日志级别的颜色
    :param level: 日志级别
    :param color_name: 颜色名称
    :return: None
    :raise ValueError: 如果日志级别或颜色名称无效
    '''
    def set_level_color(self, level, color_name):
        if level not in self.level_corlor:
            raise ValueError(f"Invalid log level: {level}")
        if color_name not in self.COLORS or color_name == 'reset':
            raise ValueError(f"Invalid color name: {color_name}")
        self.level_corlor[level] = color_name

    def __color_value_of(self, color_name):
        if color_name not in self.COLORS:
            raise ValueError(f"Invalid color name: {color_name}")
        ansi_code = self.COLORS[color_name];
        return f'\033[{ansi_code}m';

    # level转颜色
    def __level_to_color(self, level):
        color_name = self.level_corlor.get(level, "white")
        return self.__color_value_of(color_name)

    '''
    获取调用者信息
    :return: 调用者信息
    '''
    def __who_call_me(self) -> str:
        stack = inspect.stack();
         # 遍历调用栈，获得调用者
        found = False;
        position_frame = None;
        for frame_info in stack[1:]:
            # 提取帧信息
            filename = frame_info.filename
            if filename != __file__:
                # 找到调用者
                found = True;

            if found == False:
                continue

            position_frame = frame_info;
            break

        # 测试case调用
        if position_frame is None:
            position_frame = stack[-1];

        lineno = position_frame.lineno
        funcname = position_frame.function
        module = inspect.getmodule(position_frame.frame);
        filename = position_frame.filename;
        filename = os.path.basename(filename);

        if funcname == '<module>' and module is not None:
            # if module is not None:
            module_name = module.__name__;
            return f"{filename}#{module_name}:{lineno}L";

        return f"{filename}#{funcname}:{lineno}L";

    def _format(self, level, caller, message, error)->str:
        now = datetime.now()
        # 格式化时间
        formatted_time = now.strftime(self.time_format)[:-3]
        color = self.__level_to_color(level);
        if error is None:
            error = '';
        return f"{color}{formatted_time} [{level.name:<5}] {caller} {message} {error}{self.__color_value_of('reset')}"

    def _is_console_open(self):
        return self.dest != LogDest.FILE;

    '''
    内部日志函数
    :param level: 日志级别
    :param message: 日志内容
    :param error: 错误信息
    '''
    def _log(self, level, message, error=None):
        if self.level.value > level.value:
            return
        self._init_file();

        caller = self.__who_call_me();
        formatted_message = self._format(level, caller, message, error);

        # 控制台
        if self._is_console_open():
            print(f"{formatted_message}")

        # 文件
        if self.file is not None:
            self.file.write(f"{formatted_message}\n")
            self.file.flush();

    '''
    debug级别日志
    '''
    def debug(self, message, error=None):
        self._log(LogLevel.DEBUG, message, error)

    '''
    info级别日志
    '''
    def info(self, message, error=None):
        self._log(LogLevel.INFO, message, error)

    '''
    warn级别日志
    '''
    def warn(self, message, error=None):
        self._log(LogLevel.WARN, message, error)

    '''
    error级别日志
    '''
    def error(self, message, error=None):
        self._log(LogLevel.ERROR, message, error)

'''
    日志工厂类
    提供静态方法创建不同类型的日志对象
'''
class LoggerFactory:
    '''
    创建仅终端输出的日志对象
    '''
    @staticmethod
    def consoleLogger(level=LogLevel.INFO):
        return Logger(LogDest.CONSOLE, level)

    '''
    创建标准日志对象
    '''
    @staticmethod
    def newLogger(level=LogLevel.INFO):
        return Logger(LogDest.ALL, level)


if __name__ == '__main__':
    logger = Logger(LogDest.ALL, LogLevel.DEBUG)
    logger.set_dest_file('test.log')
    logger.debug('This is a debug message')
    logger.info('This is an info message')
    logger.warn('This is a warning message')
    logger.error('This is an error message')

# vim: set ts=4 sw=4 et:
