#!/bin/bash
# 测试脚本 - 使用 curl 发送测试数据到局域网 JSON 接收器
# 使用方法: ./test_send.sh <服务器IP> <端口>
# 示例: ./test_send.sh 192.168.1.100 10010

if [ $# -ne 2 ]; then
    echo "使用方法: ./test_send.sh <服务器IP> <端口>"
    echo "示例: ./test_send.sh 192.168.1.100 10010"
    exit 1
fi

HOST=$1
PORT=$2
URL="http://${HOST}:${PORT}/event"

echo "目标服务器: ${HOST}:${PORT}"
echo ""

# 测试1: 传感器数据
echo "测试 1/5: 发送传感器数据..."
curl -X POST "${URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sensor_data",
    "temperature": 25.5,
    "humidity": 60,
    "timestamp": "2024-03-02T10:30:00Z"
  }'
echo -e "\n"
sleep 1

# 测试2: 用户行为
echo "测试 2/5: 发送用户行为数据..."
curl -X POST "${URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "user_action",
    "action": "click",
    "button": "submit",
    "user_id": "user_12345"
  }'
echo -e "\n"
sleep 1

# 测试3: 系统日志
echo "测试 3/5: 发送系统日志..."
curl -X POST "${URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "system_log",
    "level": "INFO",
    "message": "Application started successfully",
    "module": "main"
  }'
echo -e "\n"
sleep 1

# 测试4: 性能指标
echo "测试 4/5: 发送性能指标..."
curl -X POST "${URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "metrics",
    "cpu_usage": 45.2,
    "memory_usage": 67.8,
    "disk_usage": 82.1
  }'
echo -e "\n"
sleep 1

# 测试5: 复杂嵌套数据
echo "测试 5/5: 发送复杂嵌套数据..."
curl -X POST "${URL}" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "api_response",
    "endpoint": "/api/users",
    "status_code": 200,
    "response_time_ms": 125,
    "data": {
      "users": [
        {"id": 1, "name": "Alice", "active": true},
        {"id": 2, "name": "Bob", "active": false}
      ],
      "meta": {
        "total": 2,
        "page": 1
      }
    }
  }'
echo -e "\n"

echo "测试完成！"

