import 'dart:convert';
import 'dart:io';
import 'data_entry.dart';
import 'store.dart';

class ServerManager {
  HttpServer? _server;
  int? _port;
  String? _address;
  final DataStore store;
  void Function(DataEntry entry)? onDataReceived;

  ServerManager(this.store);

  int? get port => _port;
  String? get address => _address;
  bool get isRunning => _server != null;

  /// 启动HTTP服务器
  Future<void> start({int port = 0}) async {
    if (_server != null) {
      throw Exception('Server is already running');
    }

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      _port = _server!.port;
      _address = _server!.address.address;
      _server!.listen(_handleRequest);
      print('Server started on ${_address}:${_port}');
    } catch (e) {
      // 如果指定端口绑定失败，尝试其他端口
      if (port != 0) {
        print('Failed to bind to port $port, trying port 8080...');
        try {
          _server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
          _port = _server!.port;
          _address = _server!.address.address;
          _server!.listen(_handleRequest);
          print('Server started on ${_address}:${_port}');
        } catch (e2) {
          print('Failed to bind to port 8080, trying random port...');
          _server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
          _port = _server!.port;
          _address = _server!.address.address;
          _server!.listen(_handleRequest);
          print('Server started on ${_address}:${_port}');
        }
      } else {
        rethrow;
      }
    }
  }

  /// 获取本机局域网IP地址
  Future<String> getLocalIp() async {
    try {
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          // 过滤出IPv4且非回环地址
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            // 优先返回局域网地址 (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
            final ip = addr.address;
            if (ip.startsWith('192.168.') ||
                ip.startsWith('10.') ||
                (ip.startsWith('172.') && _isPrivateClass(ip))) {
              return ip;
            }
          }
        }
      }
    } catch (e) {
      print('Error getting local IP: $e');
    }
    return '0.0.0.0';
  }

  bool _isPrivateClass(String ip) {
    final parts = ip.split('.');
    if (parts.length >= 2) {
      final second = int.tryParse(parts[1]) ?? 0;
      return second >= 16 && second <= 31;
    }
    return false;
  }

  /// 处理HTTP请求
  void _handleRequest(HttpRequest request) async {
    // 添加CORS头，允许跨域请求
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'POST, GET, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    try {
      // 处理OPTIONS预检请求
      if (request.method == 'OPTIONS') {
        request.response.statusCode = 200;
        await request.response.close();
        return;
      }

      // 处理POST请求到/event端点
      if (request.method == 'POST' && request.uri.path == '/event') {
        final content = await utf8.decoder.bind(request).join();

        if (content.isEmpty) {
          request.response.statusCode = 400;
          request.response.write('{"error": "Empty request body"}');
          await request.response.close();
          return;
        }

        dynamic jsonObj;
        try {
          jsonObj = jsonDecode(content);
        } catch (e) {
          request.response.statusCode = 400;
          request.response.write('{"error": "Invalid JSON format"}');
          await request.response.close();
          return;
        }

        // 获取客户端IP作为设备标识
        final device = request.connectionInfo?.remoteAddress.address ?? 'unknown';

        final entry = DataEntry(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          device: device,
          timestamp: DateTime.now(),
          json: jsonEncode(jsonObj),
        );

        await store.add(entry);
        onDataReceived?.call(entry);

        print('Received data from $device at ${entry.timestamp}');

        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"status": "ok", "message": "Data received successfully"}');
        await request.response.close();
      }
      // 处理GET请求到根路径，返回状态信息
      else if (request.method == 'GET' && request.uri.path == '/') {
        final devices = store.devices();
        final info = {
          'status': 'running',
          'server': 'LAN JSON Server',
          'endpoint': '/event',
          'method': 'POST',
          'devices': devices.length,
          'total_entries': store.totalCount,
        };
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(info));
        await request.response.close();
      }
      else {
        request.response.statusCode = 404;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error": "Not Found", "message": "Use POST /event to send data"}');
        await request.response.close();
      }
    } catch (e) {
      print('Error handling request: $e');
      try {
        request.response.statusCode = 500;
        request.response.headers.contentType = ContentType.json;
        request.response.write('{"error": "Internal Server Error", "message": "$e"}');
        await request.response.close();
      } catch (_) {
        // 忽略关闭响应时的错误
      }
    }
  }

  /// 停止服务器
  Future<void> stop() async {
    if (_server != null) {
      await _server!.close();
      // ignore: avoid_print
      print('Server stopped');
      _server = null;
      _port = null;
      _address = null;
    }
  }
}
