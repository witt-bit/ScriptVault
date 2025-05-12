#!/usr/bin/python3

import json

import json

class NestedObjectEncoder(json.JSONEncoder):
    def default(self, obj):
        # 若对象有 __dict__ 属性（如自定义类），提取其字段
        if hasattr(obj, '__dict__'):
            return obj.__dict__
        # 处理其他不可序列化的类型（如 datetime、bytes 等）
        elif isinstance(obj, (datetime, date)):
            return obj.isoformat()
        elif isinstance(obj, bytes):
            return obj.decode('utf-8')
        # 默认情况：调用父类方法
        return super().default(obj)

class JsonUtil:
    @staticmethod
    def to_string(obj)->str:
        return json.dumps(obj, cls=NestedObjectEncoder, ensure_ascii=False)

if __name__ == '__main__':
    # 示例：嵌套对象
    class Address:
        def __init__(self, city, zipcode):
            self.city = city
            self.zipcode = zipcode

    class Person:
        def __init__(self, name, age, address):
            self.name = name
            self.age = age
            self.address = address  # 嵌套对象

    # 序列化
    p = Person("Alice", 30, Address("Shanghai", "200000"))
    json_str = json.dumps(p, cls=NestedObjectEncoder, ensure_ascii=False)
    json_str1 = JsonUtil.to_string(p)
    print(json_str)
    print(json_str1)


# vim: set ts=4 sw=4 et:
