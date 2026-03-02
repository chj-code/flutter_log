# 局域网 JSON 数据接收器

一个基于 Flutter 开发的桌面应用，用于在局域网内接收和展示来自其他设备发送的 JSON 数据。

## 功能特点

- ✅ **局域网服务器**：启动 HTTP 服务器，接收局域网内其他设备发送的 JSON 数据
- ✅ **多设备支持**：自动识别不同设备（通过 IP 地址），并支持设备间快速切换
- ✅ **实时展示**：接收到的数据实时展示在界面上，带有 JSON 语法高亮
- ✅ **内存存储**：数据仅存储在内存中，无需本地持久化，重启后自动清空
- ✅ **数据管理**：支持删除单条数据、删除指定设备的所有数据、清空所有数据
- ✅ **跨平台**：支持 macOS、Windows、Linux 桌面平台

## 快速开始

### 1. 启动应用

```bash
cd /Users/10900/Desktop/flutter_log
flutter run -d macos  # macOS
# 或
flutter run -d windows  # Windows
# 或
flutter run -d linux  # Linux
```

### 2. 启动服务器

- 点击右上角的播放按钮启动服务器
- 服务器默认监听在 `10010` 端口（如果端口被占用，会自动尝试其他端口）
- 启动后会显示局域网 IP 地址和端口号，例如：`192.168.1.100:10010`

### 3. 发送数据

从局域网内的其他设备向服务器发送 JSON 数据：

#### 使用 curl

```bash
curl -X POST http://192.168.1.100:10010/event \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "value": 123, "timestamp": "2024-03-02T10:30:00Z"}'
```

#### 使用 Python

```python
import requests
import json

data = {
    "message": "Hello from Python",
    "value": 456,
    "items": ["item1", "item2", "item3"]
}

response = requests.post(
    "http://192.168.1.100:10010/event",
    json=data
)

print(response.json())
```

#### 使用 JavaScript (Node.js)

```javascript
const axios = require('axios');

const data = {
    message: "Hello from Node.js",
    value: 789,
    active: true
};

axios.post('http://192.168.1.100:10010/event', data)
    .then(response => console.log(response.data))
    .catch(error => console.error(error));
```

## API 端点

### POST /event

接收 JSON 数据

- **Content-Type**: `application/json`
- **Body**: 任意有效的 JSON 数据
- **Response**: 
  ```json
  {
    "status": "ok",
    "message": "Data received successfully"
  }
  ```

### GET /

查看服务器状态

- **Response**:
  ```json
  {
    "status": "running",
    "server": "LAN JSON Server",
    "endpoint": "/event",
    "method": "POST",
    "devices": 2,
    "total_entries": 15
  }
  ```

## 使用说明

### 设备切换

- 应用会自动识别不同的发送设备（通过 IP 地址）
- 在设备选择栏中点击不同的设备标签即可切换
- 每个设备标签后面会显示该设备的数据条数

### 删除数据

1. **删除单条数据**：点击数据卡片右上角的删除图标
2. **删除当前设备数据**：点击右上角菜单 → "删除当前设备数据"
3. **清空所有数据**：点击右上角菜单 → "清空所有数据"

### 停止服务器

点击右上角的停止按钮即可停止服务器

## 项目结构

```
lib/
├── main.dart          # 主应用和 UI 界面
├── server.dart        # HTTP 服务器管理
├── store.dart         # 数据存储（内存）
└── data_entry.dart    # 数据模型
```

## 技术栈

- **Flutter**: 跨平台 UI 框架
- **Dart HTTP Server**: 内置 HTTP 服务器
- **flutter_highlight**: JSON 语法高亮
- **window_size**: 桌面窗口管理

## 注意事项

1. **防火墙**：确保防火墙允许应用监听端口
2. **网络**：确保发送端和接收端在同一局域网内
3. **数据持久化**：应用关闭后，所有数据会自动清空
4. **IP 地址**：应用会自动获取局域网 IP 地址，通常是 192.168.x.x 或 10.x.x.x

## 编译发布

### macOS

```bash
flutter build macos
```

生成的应用位于：`build/macos/Build/Products/Release/lan_json_server.app`

### Windows

```bash
flutter build windows
```

生成的应用位于：`build/windows/runner/Release/`

### Linux

```bash
flutter build linux
```

生成的应用位于：`build/linux/x64/release/bundle/`

## 许可证

MIT License


## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
