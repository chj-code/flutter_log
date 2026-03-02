#!/usr/bin/env python3
"""
快速测试脚本 - 测试本地服务器
自动检测本地运行的服务器并发送测试数据
"""

import requests
import json
from datetime import datetime

def find_local_server():
    """尝试找到本地运行的服务器"""
    ports = [10010, 8080, 8000, 9000]
    hosts = ['127.0.0.1', 'localhost']

    for host in hosts:
        for port in ports:
            try:
                url = f"http://{host}:{port}/"
                response = requests.get(url, timeout=1)
                if response.status_code == 200:
                    data = response.json()
                    if 'server' in data and 'LAN JSON Server' in data.get('server', ''):
                        print(f"✓ 找到服务器: {host}:{port}")
                        return host, port
            except:
                continue

    return None, None

def send_quick_test(host, port):
    """发送快速测试数据"""
    url = f"http://{host}:{port}/event"

    test_data = {
        "type": "quick_test",
        "message": "这是一条测试消息",
        "timestamp": datetime.now().isoformat(),
        "test_number": 12345,
        "test_array": [1, 2, 3, 4, 5],
        "test_object": {
            "name": "测试",
            "value": 100,
            "active": True
        }
    }

    print(f"\n发送测试数据到 {url}...")
    print(f"数据内容: {json.dumps(test_data, ensure_ascii=False, indent=2)}\n")

    try:
        response = requests.post(url, json=test_data, timeout=5)
        print(f"响应状态码: {response.status_code}")
        print(f"响应内容: {response.json()}")

        if response.status_code == 200:
            print("\n✓ 测试成功！请查看应用界面确认数据已接收")
            return True
        else:
            print("\n✗ 测试失败")
            return False

    except Exception as e:
        print(f"\n✗ 发送失败: {e}")
        return False

if __name__ == "__main__":
    print("快速测试脚本 - 局域网 JSON 接收器")
    print("=" * 50)

    print("\n正在搜索本地服务器...")
    host, port = find_local_server()

    if host and port:
        send_quick_test(host, port)
    else:
        print("\n✗ 未找到运行中的服务器")
        print("\n请确保:")
        print("  1. 应用已启动")
        print("  2. 已点击播放按钮启动服务器")
        print("  3. 服务器正在监听常用端口 (10010, 8080, 8000, 9000)")
        print("\n如果服务器在其他端口，请使用:")
        print("  python3 test_send.py <IP> <端口>")

