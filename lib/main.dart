import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:window_size/window_size.dart';
import 'store.dart';
import 'data_entry.dart';
import 'server.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    setWindowMinSize(const Size(400, 400));
    setWindowFrame(const Rect.fromLTWH(100, 100, 800, 600));
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN JSON Server',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late DataStore store;
  late ServerManager server;
  bool isRunning = false;
  String? lanAddress;
  int? port;
  String? selectedDevice;
  String? selectedEventName;
  String eventSearch = '';
  final TextEditingController _eventSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initStoreAndServer();
  }

  @override
  void dispose() {
    _eventSearchController.dispose();
    server.stop();
    super.dispose();
  }

  Future<void> _initStoreAndServer() async {
    store = DataStore();
    await store.init();
    server = ServerManager(store);
    server.onDataReceived = (entry) {
      setState(() {
        // 如果是新设备，自动选中
        selectedDevice ??= entry.device;
      });
    };
  }

  Future<void> _startServer() async {
    try {
      await server.start(port: 10000);
      final ip = await server.getLocalIp();
      setState(() {
        isRunning = true;
        lanAddress = ip;
        port = server.port;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('启动服务失败: $e')),
        );
      }
    }
  }

  Future<void> _stopServer() async {
    await server.stop();
    setState(() {
      isRunning = false;
      port = null;
      lanAddress = null;
    });
  }

  void _deleteCurrentDevice() {
    final devices = store.devices();
    if (devices.isEmpty) return;

    final deviceToDelete = selectedDevice ?? devices.first;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除设备 "$deviceToDelete" 的所有数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              store.deleteDevice(deviceToDelete);
              final remainingDevices = store.devices();
              setState(() {
                if (remainingDevices.isEmpty) {
                  selectedDevice = null;
                } else if (selectedDevice == deviceToDelete) {
                  selectedDevice = remainingDevices.first;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _clearAllData() {
    if (store.totalCount == 0) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有设备的数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              store.clearAll();
              setState(() {
                selectedDevice = null;
              });
              Navigator.pop(context);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final now = DateTime.now();
    final diff = now.difference(local);

    if (diff.inSeconds < 60) {
      return '${diff.inSeconds}秒前';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}分钟前';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}小时前';
    }

    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}:${local.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Firebase埋点监控',
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        elevation: 2,
        actions: [
          if (isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Chip(
                  avatar: const Icon(Icons.wifi, size: 16, color: Colors.green),
                  label: Text(
                    '${lanAddress ?? 'unknown'}:${port ?? '?'}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green[50],
                ),
              ),
            ),
          IconButton(
            icon: Icon(isRunning ? Icons.stop_circle : Icons.play_circle),
            iconSize: 28,
            tooltip: isRunning ? '停止服务' : '启动服务',
            onPressed: isRunning ? _stopServer : _startServer,
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: store.totalCount > 0 ? _deleteCurrentDevice : null,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: const Text('删除当前设备'),
          ),
          TextButton.icon(
            onPressed: store.totalCount > 0 ? _clearAllData : null,
            icon: const Icon(Icons.delete_forever, size: 18, color: Colors.red),
            label: const Text('清空所有数据'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final devices = store.devices();

    if (!isRunning) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '服务未启动',
              style: TextStyle(fontSize: 24, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角播放按钮启动服务',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    if (devices.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.devices, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '等待设备发送数据...',
              style: TextStyle(fontSize: 20, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '如何发送数据：',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'POST http://${lanAddress ?? 'YOUR_IP'}:${port ?? 'PORT'}/event',
                    style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Content-Type: application/json',
                    style: TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Body: ',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '''{
  "event_name": "your_event",
  "parameters": {
    "param1": "value1",
    "param2": 123
  },
  "items": [
    {"item_id": "item1", "item_name": "Item One"},
    {"item_id": "item2", "item_name": "Item Two"}
  ]
}''',
                    style: TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 确保选中的设备存在
    if (selectedDevice == null || !devices.contains(selectedDevice)) {
      selectedDevice = devices.first;
      selectedEventName = '全部';
    }

    final deviceEntries = store.entriesForDevice(selectedDevice!);
    final eventCounts = _collectEventCounts(deviceEntries, eventSearch);
    final eventNames = ['全部', ...eventCounts.keys.toList()..sort()];
    if (selectedEventName == null || !eventNames.contains(selectedEventName)) {
      selectedEventName = '全部';
    }

    return Column(
      children: [
        _buildDeviceSelector(devices),
        _buildEventSearchAndTabs(eventNames, eventCounts, deviceEntries.length),
        Expanded(
          child:
              _buildDataList(selectedDevice!, selectedEventName, eventSearch),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector(List<String> devices) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.devices_other, size: 20),
          const SizedBox(width: 8),
          const Text(
            '设备:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: devices.map((device) {
                  final isSelected = device == selectedDevice;
                  final count = store.entriesForDevice(device).length;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$device ($count)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedDevice = device;
                            selectedEventName = '全部';
                          });
                        }
                      },
                      selectedColor: Colors.indigo[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.indigo[900] : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventSearchAndTabs(
    List<String> eventNames,
    Map<String, int> eventCounts,
    int totalCount,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _eventSearchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '搜索 event_name',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() {
                eventSearch = value.trim();
                selectedEventName = '全部';
              });
            },
          ),
          const SizedBox(height: 8),
          if (eventNames.length == 1)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('暂无匹配的 event_name'),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: eventNames.map((eventName) {
                  final isSelected = eventName == selectedEventName;
                  final count = eventName == '全部'
                      ? totalCount
                      : (eventCounts[eventName] ?? 0);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$eventName ($count)'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            selectedEventName = eventName;
                          });
                        }
                      },
                      selectedColor: Colors.indigo[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.indigo[900] : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDataList(String device, String? eventName, String search) {
    final entries = store.entriesForDevice(device);

    final filteredEntries = entries.where((entry) {
      final name = _extractEventName(entry.json);
      final matchesEventName =
          eventName == null || eventName == '全部' || name == eventName;
      final matchesSearch = search.isEmpty || name.contains(search);
      return matchesEventName && matchesSearch;
    }).toList();

    if (filteredEntries.isEmpty) {
      return Center(
        child: Text(
          '该设备暂无数据',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    final sortedEntries = List<DataEntry>.from(filteredEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        return _buildDataCard(entry, index);
      },
    );
  }

  Widget _buildDataCard(DataEntry entry, int index) {
    final payload = _parsePayload(entry.json);
    final eventName = _extractEventName(entry.json);
    final parameters = _extractParameters(payload);
    final items = _extractItems(payload);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.indigo[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '#${index + 1}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    eventName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _formatTimestamp(entry.timestamp),
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  tooltip: '删除此条数据',
                  onPressed: () {
                    store.delete(entry.id);
                    setState(() {});
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 16),
            _buildParametersAndItems(parameters, items),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersAndItems(
    Map<String, dynamic> parameters,
    List<dynamic> items,
  ) {
    if (items.isEmpty) {
      return _buildParametersTable(parameters, true);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _buildParametersTable(parameters, false)),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _buildItemsPanel(items)),
        ],
      ),
    );
  }

  Widget _buildParametersTable(
    Map<String, dynamic> parameters,
    bool fullWidth,
  ) {
    final rows = parameters.entries.toList();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: rows.isEmpty
          ? Center(
              child: Text(
                '无参数',
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : Table(
              columnWidths: const {
                0: IntrinsicColumnWidth(),
                1: FlexColumnWidth(),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: rows.map((entry) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: SelectableText(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 6, bottom: 6, left: 15),
                      child: SelectableText(
                        _stringifyValue(entry.value),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildItemsPanel(List<dynamic> items) {
    String prettyJson;
    try {
      prettyJson = const JsonEncoder.withIndent('  ').convert(items);
    } catch (_) {
      prettyJson = items.toString();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'items (${items.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: SelectableText(
                prettyJson,
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> _collectEventCounts(List<DataEntry> entries, String search) {
    final Map<String, int> counts = {};
    for (var entry in entries) {
      final name = _extractEventName(entry.json);
      if (search.isEmpty || name.contains(search)) {
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    return counts;
  }

  Map<String, dynamic> _parsePayload(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignore parse errors and return empty
    }
    return {};
  }

  String _extractEventName(String json) {
    final payload = _parsePayload(json);
    final value = payload['event_name'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'unknown_event';
  }

  Map<String, dynamic> _extractParameters(Map<String, dynamic> payload) {
    final value = payload['parameters'];
    if (value is Map<String, dynamic>) {
      return value;
    }
    return {};
  }

  List<dynamic> _extractItems(Map<String, dynamic> payload) {
    final value = payload['items'];
    if (value is List<dynamic>) {
      return value;
    }
    return [];
  }

  String _stringifyValue(dynamic value) {
    if (value == null) return 'null';
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}
