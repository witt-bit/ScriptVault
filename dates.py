#!/usr/bin/python3

import sys
import argparse
from datetime import datetime, timedelta


'''
抛出异常并结束程序
'''
def throw_error(message, exit_code=1):
    print(f"错误：{message}", file=sys.stderr)
    sys.exit(exit_code)

fmts = (
    '%Y-%m-%d %H:%M:%S',
    '%Y-%m-%d %H:%M:%S.%f',
    '%Y年%m月%d日 %H时%M分%S秒',
    '%Y/%m/%d %H:%M:%S',
    '%Y/%m/%d %H:%M:%S.%f',
    '%Y-%m-%d',
    '%Y年%m月%d日',
    '%Y/%m/%d',
    '%Y%m%d%H%M%S',
    '%Y%m%d%H%M%S%f',
    '%s',
    '%s000'
);
def parse_datetime(dt_str):
    if dt_str.isdigit():
        if len(dt_str) == 13:
            dt = datetime.fromtimestamp(int(dt_str) / 1000)
        else:
            dt = datetime.fromtimestamp(int(dt_str))
        # print(f"解析成功: {dt_str} -> {dt}")
        return dt;

    # 尝试多种常见格式解析
    for fmt in fmts:
        # print(f"尝试解析格式: {fmt} -> {dt_str}")
        try:
            if fmt == '%s' and len(dt_str) == 10:
                dt = datetime.fromtimestamp(int(dt_str));
            elif fmt == '%s':
                dt = datetime.fromtimestamp(int(dt_str) / 1000);
            else:
                dt = datetime.strptime(dt_str, fmt);
            # print(f"解析成功: {dt_str} -> {dt}")
            return dt
        except ValueError:
            continue
    throw_error(f"无法解析的日期格式: {dt_str}");


def now(args):
    dt = datetime.now()
    print(dt.strftime(args.format or "%Y-%m-%d %H:%M:%S"))


def format_time(args):
    dt = parse_datetime(args.datetime)
    print(dt.strftime(args.format))


def parse_time(args):
    dt = parse_datetime(args.datetime)
    print(int(dt.timestamp()))


def add_time(args):
    dt = parse_datetime(args.datetime)
    delta = timedelta(days=args.days, hours=args.hours, minutes=args.minutes, seconds=args.seconds)
    new_dt = dt + delta
    print(new_dt.strftime(args.format or "%Y-%m-%d %H:%M:%S"))


def timestamp(args):
    dt = args.datetime
    if not dt:
        dt = datetime.now();
    else:
        dt = parse_datetime(dt)

    # 10位时间戳
    if args.style == 10:
        print(int(dt.timestamp()));
        sys.exit(0)

    # 毫秒级 (13位)
    print(int(dt.timestamp() * 1000))

def help_info(_):
    parser.print_help()


# 命令映射
commands = {
    'now': now,
    'format': format_time,
    'parse': parse_time,
    'add': add_time,
    'timestamp': timestamp,
    'help': help_info
}


# 参数解析器
parser = argparse.ArgumentParser(description="常用时间日期函数集")
subparsers = parser.add_subparsers(dest='command')

# now 子命令
now_parser = subparsers.add_parser('now', help='输出当前时间')
now_parser.add_argument('--format', help='指定输出格式，默认: %%Y-%%m-%%d %%H:%%M:%%S')

# format 子命令
format_parser = subparsers.add_parser('format', help='格式化时间')
format_parser.add_argument('--datetime', required=True, help='输入的日期时间字符串')
format_parser.add_argument('--format', required=True, help='目标格式')

# parse 子命令
parse_parser = subparsers.add_parser('parse', help='将日期字符串转为时间戳')
parse_parser.add_argument('--datetime', required=True, help='输入的日期时间字符串')

# add 子命令
add_parser = subparsers.add_parser('add', help='给时间增加天数、小时、分钟、秒')
add_parser.add_argument('--datetime', required=True, help='输入的日期时间字符串')
add_parser.add_argument('--days', type=int, default=0)
add_parser.add_argument('--hours', type=int, default=0)
add_parser.add_argument('--minutes', type=int, default=0)
add_parser.add_argument('--seconds', type=int, default=0)
add_parser.add_argument('--format', help='输出格式')

# timestamp 子命令
ts_parser = subparsers.add_parser('timestamp', help='获取时间戳')
ts_parser.add_argument('--datetime', help='可选的时间点')
ts_parser.add_argument('--style', help='输出格式', choices=[10, 13], default=13, type=int)

# help 子命令
subparsers.add_parser('help', help='显示帮助信息')


if __name__ == "__main__":
    args = parser.parse_args()
    if args.command in commands:
        commands[args.command](args)
    else:
        parser.print_help()