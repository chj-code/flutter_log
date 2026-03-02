# 使用指南

## 快速开始步骤

### 1. 安装依赖

首次使用前，请确保已安装 Flutter SDK，然后运行：

```bash
cd /Users/10900/Desktop/flutter_log
flutter pub get
```

### 2. 运行应用

#### macOS
```bash
flutter run -d macos
```

#### Windows
```bash
flutter run -d windows
```

#### Linux
```bash
flutter run -d linux
```

### 3. 启动服务器

1. 应用启动后，点击右上角的**播放按钮**（▶️）启动服务器
2. 服务器启动后，界面会显示局域网 IP 地址和端口号
3. 例如：`192.168.1.100:10010`

### 4. 发送测试数据

项目提供了两个测试脚本：

#### 使用 Python 脚本（推荐）

```bash
# 安装 requests 库（如果还没安装）
pip3 install requests

# 运行测试脚本，替换为实际的 IP 和端口
python3 test_send.py 192.168.1.100 10010
```

#### 使用 Bash 脚本

```bash
# 运行测试脚本，替换为实际的 IP 和端口
./test_send.sh 192.168.1.100 10010
```

#### 使用 curl 命令

```bash
curl -X POST http://192.168.1.100:10010/event \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "value": 123}'
```

## 功能说明

### 主界面

- **顶部状态栏**：显示当前服务器监听的 IP 地址和端口
- **设备选择栏**：显示所有发送过数据的设备，点击可切换查看
- **数据列表**：显示当前选中设备的所有数据，按时间倒序排列

### 操作按钮

1. **启动/停止服务器**：右上角的播放/停止按钮
2. **菜单选项**（右上角三点图标）：
   - 删除当前设备数据
   - 清空所有数据
3. **删除单条数据**：每条数据卡片右上角的删除图标

## 常见问题

### Q: 服务器启动失败

**A:** 可能是端口被占用。应用会自动尝试以下端口：
- 10010（默认）
- 8080（备用）
- 随机端口（最后选择）

### Q: 无法从其他设备连接

**A:** 请检查：
1. 两个设备是否在同一局域网内
2. 防火墙是否允许应用监听端口
3. macOS 用户需要在"系统设置 > 隐私与安全性 > 防火墙"中允许应用

### Q: 数据没有实时更新

**A:** 数据是实时接收的，如果没有更新：
1. 确认数据发送成功（查看响应码）
2. 检查设备选择是否正确
3. 尝试切换设备标签

### Q: 应用关闭后数据丢失

**A:** 这是正常的。应用使用内存存储，关闭后数据会自动清空。这是设计行为，确保隐私和性能。

## API 文档

### 接收数据端点

**URL**: `POST /event`

**请求头**:
```
Content-Type: application/json
```

**请求体**: 任意有效的 JSON 对象

**成功响应** (200):
```json
{
  "status": "ok",
  "message": "Data received successfully"
}
```

**错误响应**:

- 400 Bad Request: JSON 格式无效或请求体为空
- 500 Internal Server Error: 服务器内部错误

### 服务器状态端点

**URL**: `GET /`

**成功响应** (200):
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

## 编程语言示例

### Python

```python
import requests

data = {"temperature": 25.5, "humidity": 60}
response = requests.post("http://192.168.1.100:10010/event", json=data)
print(response.json())
```

### JavaScript (Node.js)

```javascript
const axios = require('axios');

const data = {temperature: 25.5, humidity: 60};
axios.post('http://192.168.1.100:10010/event', data)
    .then(res => console.log(res.data));
```

### Java

```java
import java.net.http.*;
import java.net.URI;

HttpClient client = HttpClient.newHttpClient();
HttpRequest request = HttpRequest.newBuilder()
    .uri(URI.create("http://192.168.1.100:10010/event"))
    .header("Content-Type", "application/json")
    .POST(HttpRequest.BodyPublishers.ofString("{\"temperature\": 25.5}"))
    .build();

HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
System.out.println(response.body());
```

### C#

```csharp
using System;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

var client = new HttpClient();
var json = "{\"temperature\": 25.5, \"humidity\": 60}";
var content = new StringContent(json, Encoding.UTF8, "application/json");
var response = await client.PostAsync("http://192.168.1.100:10010/event", content);
var result = await response.Content.ReadAsStringAsync();
Console.WriteLine(result);
```

## 高级用法

### 自动化测试

可以使用测试脚本进行自动化测试，例如定时发送数据：

```bash
# 每 5 秒发送一次数据（Linux/macOS）
while true; do
  curl -X POST http://192.168.1.100:10010/event \
    -H "Content-Type: application/json" \
    -d "{\"timestamp\": \"$(date -Iseconds)\", \"random\": $RANDOM}"
  sleep 5
done
```

### 集成到现有项目

将应用作为日志接收器，在你的项目中发送日志：

```python
import logging
import requests
import json

class LANLogHandler(logging.Handler):
    def __init__(self, host, port):
        super().__init__()
        self.url = f"http://{host}:{port}/event"
    
    def emit(self, record):
        log_entry = {
            "level": record.levelname,
            "message": record.getMessage(),
            "timestamp": record.created,
            "module": record.module,
            "line": record.lineno
        }
        try:
            requests.post(self.url, json=log_entry, timeout=1)
        except:
            pass

# 使用
logger = logging.getLogger()
logger.addHandler(LANLogHandler("192.168.1.100", 10010))
logger.info("This will be sent to the LAN server")
```

## 性能说明

- **并发连接**: 支持多个设备同时发送数据
- **数据大小**: 建议单个 JSON 不超过 1MB
- **存储**: 仅内存存储，受系统内存限制
- **实时性**: 数据接收后立即显示，延迟 < 100ms

## 技术支持

如遇到问题，请检查：

1. Flutter 版本：`flutter --version`
2. 依赖安装：`flutter pub get`
3. 编译错误：`flutter analyze`
4. 查看日志：应用会在终端输出详细日志

## 更新日志

### Version 1.0.0 (2024-03-02)

- ✅ 初始版本发布
- ✅ 支持局域网 JSON 数据接收
- ✅ 多设备支持和切换
- ✅ 内存存储模式
- ✅ 数据管理功能（删除、清空）
- ✅ JSON 语法高亮显示
- ✅ 跨平台支持（macOS、Windows、Linux）

