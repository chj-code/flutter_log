#!/usr/bin/env python3
"""
测试脚本 - 向局域网 JSON 接收器发送测试数据
使用方法: python3 test_send.py <服务器IP> <端口>
示例: python3 test_send.py 192.168.1.100 10010
"""

import requests
import json
import sys
import time
from datetime import datetime

def send_test_data(host, port):
    """发送测试数据到服务器"""
    url = f"http://{host}:{port}/event"

    # 测试数据示例
    test_cases = [
        {
            "type": "sensor_data",
            "temperature": 25.5,
            "humidity": 60,
            "timestamp": datetime.now().isoformat()
        },
        {
            "type": "user_action",
            "action": "click",
            "button": "submit",
            "user_id": "user_12345",
            "timestamp": datetime.now().isoformat()
        },
        {
            "type": "system_log",
            "level": "INFO",
            "message": "Application started successfully",
            "module": "main",
            "timestamp": datetime.now().isoformat()
        },
        {
            "type": "metrics",
            "cpu_usage": 45.2,
            "memory_usage": 67.8,
            "disk_usage": 82.1,
            "network_rx": 1024000,
            "network_tx": 512000,
            "timestamp": datetime.now().isoformat()
        },
        {
            "type": "api_response",
            "endpoint": "/api/users",
            "status_code": 200,
            "response_time_ms": 125,
            "data": {
                "users_count": 150,
                "active_users": 42
            },
            "timestamp": datetime.now().isoformat()
        }
    ]

    print(f"开始向 {url} 发送测试数据...\n")

    for i, data in enumerate(test_cases, 1):
        try:
            print(f"[{i}/{len(test_cases)}] 发送: {data['type']}")
            response = requests.post(url, json=data, timeout=5)

            if response.status_code == 200:
                print(f"  ✓ 成功: {response.json()}")
            else:
                print(f"  ✗ 失败: HTTP {response.status_code}")
                print(f"    {response.text}")

            # 间隔1秒
            if i < len(test_cases):
                time.sleep(1)

        except requests.exceptions.RequestException as e:
            print(f"  ✗ 错误: {e}")
            break

    print("\n测试完成！")

def check_server_status(host, port):
    """检查服务器状态"""
    url = f"http://{host}:{port}/"
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            info = response.json()
            print(f"服务器状态:")
            print(f"  状态: {info.get('status')}")
            print(f"  端点: {info.get('endpoint')}")
            print(f"  设备数: {info.get('devices')}")
            print(f"  总条目: {info.get('total_entries')}")
            return True
    except Exception as e:
        print(f"无法连接到服务器: {e}")
        return False
    return False

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("使用方法: python3 test_send.py <服务器IP> <端口>")
        print("示例: python3 test_send.py 192.168.1.100 10010")
        sys.exit(1)

    host = sys.argv[1]
    port = sys.argv[2]

    print(f"目标服务器: {host}:{port}\n")

    # 先检查服务器状态
    print("检查服务器连接...")
    if check_server_status(host, port):
        print("✓ 服务器连接正常\n")
        send_test_data(host, port)
    else:
        print("✗ 无法连接到服务器，请确保:")
        print("  1. 服务器已启动")
        print("  2. IP 地址和端口正确")
        print("  3. 防火墙允许连接")
        sys.exit(1)

