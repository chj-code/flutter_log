import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'store.dart';
import 'data_entry.dart';
import 'server.dart';
import 'package:flutter_highlight/flutter_highlight.dart';

bool get isDesktop => Platform.isIOS || Platform.isAndroid ? false : true;

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
  String eventSearch = '';
  bool isShowSearch = false;
  bool isShowTabBar = true;

  Set<String> selectedEventNames = {};
  Set<String> selectedModuleNames = {};

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

  void updateData() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.search_outlined, size: 28),
          tooltip: '搜索',
          onPressed: _onShowSearchTap,
        ),
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: isRunning
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Center(
                  child: Chip(
                    avatar: isDesktop
                        ? const Icon(Icons.wifi, size: 16, color: Colors.green)
                        : null,
                    labelPadding: isDesktop
                        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 3)
                        : const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 3),
                    label: FittedBox(
                      child: Text(
                        '${lanAddress ?? 'unknown'}:${port ?? '?'}',
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    backgroundColor: Colors.green[50],
                  ),
                ),
              )
            : const Text('Firebase埋点'),
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(
              isRunning
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
              color: Colors.black87,
            ),
            iconSize: 28,
            tooltip: isRunning ? '停止服务' : '启动服务',
            onPressed: isRunning ? _stopServer : _startServer,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_outlined,
              color: Colors.black87,
            ),
            iconSize: 28,
            tooltip: '清空当前设备数据',
            onPressed: store.totalCount > 0 ? _deleteCurrentDevice : null,
          ),
          IconButton(
            icon: const Icon(Icons.padding_outlined, color: Colors.black87),
            tooltip: isShowTabBar ? '隐藏tabbar' : '显示tabbar',
            onPressed: _onShowTabbarTap,
            iconSize: 28,
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.black87),
            tooltip: '复制全部',
            onPressed: _copyAllData,
            iconSize: 28,
          ),
          // IconButton(
          //   icon: const Icon(Icons.settings_sharp, size: 28),
          //   tooltip: "设置",
          //   onPressed: _onSettingsTap,
          // ),
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
                    '如何发送数据：(目前仅支持event事件)',
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
  "module_name": "your_module",
  "parameters": {
    "param1": "value1",
    "param2": 123
  },
  "items": [
    {"id": "1", "name": "One", ...},
    {"id": "2", "name": "Two", ...}
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
      selectedEventNames.clear();
      selectedModuleNames.clear();
    }

    final deviceEntries = store.entriesForDevice(selectedDevice!);
    final eventCounts = _collectEventCounts(deviceEntries, eventSearch);
    final moduleCounts = _collectModuleCounts(deviceEntries, eventSearch);
    final eventNames = eventCounts.keys.toList()..sort();
    final moduleNames = moduleCounts.keys.toList()..sort();

    selectedEventNames = selectedEventNames.intersection(eventNames.toSet());
    selectedModuleNames = selectedModuleNames.intersection(moduleNames.toSet());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildEventSearchBar(),
        if (isShowTabBar) ...[
          if (isDesktop) const SizedBox(height: 10),
          _buildModuleTabs(moduleNames, moduleCounts),
          if (isDesktop) const SizedBox(height: 10),
          _buildEventTabs(eventNames, eventCounts),
          if (isDesktop) const SizedBox(height: 10),
          _buildDeviceSelector(devices),
        ],
        Expanded(
          child: _buildDataList(
            selectedDevice!,
            selectedEventNames,
            selectedModuleNames,
            eventSearch,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceSelector(List<String> devices) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
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
                            selectedEventNames.clear();
                            selectedModuleNames.clear();
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

  Widget _buildEventSearchBar() {
    if (isShowSearch == false) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      child: TextField(
        controller: _eventSearchController,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: '搜索 event_name',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          isDense: true,
          hintStyle: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
        onChanged: (value) {
          setState(() {
            eventSearch = value.trim();
          });
        },
      ),
    );
  }

  Widget _buildModuleTabs(
    List<String> moduleNames,
    Map<String, int> moduleCounts,
  ) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: moduleNames.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text('暂无匹配的 module_name'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: moduleNames.map((moduleName) {
                  final isSelected = selectedModuleNames.contains(moduleName);
                  final count = moduleCounts[moduleName] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$moduleName ($count)'),
                      showCheckmark: false,
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedModuleNames.add(moduleName);
                          } else {
                            selectedModuleNames.remove(moduleName);
                          }
                        });
                      },
                      selectedColor: Colors.blue[100],
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.blue[900] : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }

  Widget _buildEventTabs(
    List<String> eventNames,
    Map<String, int> eventCounts,
  ) {
    return Container(
      color: Colors.white,
      width: double.infinity,
      child: eventNames.isEmpty
          ? const Align(
              alignment: Alignment.centerLeft,
              child: Text('暂无匹配的 event_name'),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: eventNames.map((eventName) {
                  final isSelected = selectedEventNames.contains(eventName);
                  final count = eventCounts[eventName] ?? 0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$eventName ($count)'),
                      showCheckmark: false,
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            selectedEventNames.add(eventName);
                          } else {
                            selectedEventNames.remove(eventName);
                          }
                        });
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
    );
  }

  Widget _buildDataList(
    String device,
    Set<String> eventNames,
    Set<String> moduleNames,
    String search,
  ) {
    final entries = store.entriesForDevice(device);

    final filteredEntries = entries.where((entry) {
      final eventName = _extractEventName(entry.json);
      final moduleName = _extractModuleName(entry.json);

      final matchesEventName =
          eventNames.isEmpty || eventNames.contains(eventName);
      final matchesModuleName =
          moduleNames.isEmpty || moduleNames.contains(moduleName);
      final matchesSearch = search.isEmpty || eventName.contains(search);

      return matchesEventName && matchesModuleName && matchesSearch;
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
    final moduleName = _extractModuleName(entry.json);
    final codeLine = _extractCodeLine(entry.json);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.displayTime} (${_formatTimestamp(entry.timestamp)})',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
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
                          if (moduleName != "null")
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                moduleName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          if (codeLine.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: Text(
                                codeLine,
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.black87),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    final jsonStr =
                        const JsonEncoder.withIndent('  ').convert(payload);
                    Clipboard.setData(ClipboardData(text: jsonStr));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制事件数据')),
                      );
                    }
                  },
                  child: const Text('复制', style: TextStyle(fontSize: 15)),
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

    if (isDesktop) {
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
    return Column(
      children: [
        _buildParametersTable(parameters, true),
        _buildItemsPanel(items),
      ],
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
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 3, horizontal: 5),
                      child: SelectableText(
                        entry.key,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(top: 3, bottom: 3, left: 15),
                      child: SelectableText(
                        _stringifyValue(entry.value),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.w500,
                        ),
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
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!),
      ),
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 25,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'items (${items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.purpleAccent,
                    fontSize: 12,
                  ),
                ),
                // 复制
                TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: prettyJson));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('已复制 items 数据')),
                      );
                    }
                  },
                  child: const Text('复制Items', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(
                child: SizedBox(
                  width: double.infinity,
                  child: HighlightView(
                    prettyJson,
                    language: 'json',
                    padding: const EdgeInsets.all(6.0),
                    theme: const {
                      'root': TextStyle(color: Colors.black87),
                      'string': TextStyle(color: Colors.green),
                      'number': TextStyle(color: Colors.blue),
                      'key': TextStyle(color: Colors.redAccent),
                      'value': TextStyle(color: Colors.orange),
                    },
                    textStyle:
                        const TextStyle(fontFamily: 'Courier', fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension Controller on _HomePageState {
  Future<void> _initStoreAndServer() async {
    store = DataStore();
    await store.init();
    server = ServerManager(store);
    server.onDataReceived = (entry) {
      // 如果是新设备，自动选中
      selectedDevice ??= entry.device;
      updateData();
    };
  }

  Future<void> _startServer() async {
    try {
      await server.start(port: 8090);
      final ip = await server.getLocalIp();
      isRunning = true;
      lanAddress = ip;
      port = server.port;
      updateData();
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
    isRunning = false;
    port = null;
    lanAddress = null;
    updateData();
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
              if (remainingDevices.isEmpty) {
                selectedDevice = null;
              } else if (selectedDevice == deviceToDelete) {
                selectedDevice = remainingDevices.first;
              }
              updateData();
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
              selectedDevice = null;
              updateData();
              Navigator.pop(context);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _onShowSearchTap() {
    isShowSearch = !isShowSearch;
    updateData();
  }

  void _onShowTabbarTap() {
    isShowTabBar = !isShowTabBar;
    updateData();
  }

  void _copyAllData() {
    if (selectedDevice == null) return;
    final allData = store.entriesForDevice(selectedDevice!);

    final filteredEntries = allData.where((entry) {
      final eventName = _extractEventName(entry.json);
      final moduleName = _extractModuleName(entry.json);
      final matchesEventName =
          selectedEventNames.isEmpty || selectedEventNames.contains(eventName);
      final matchesModuleName = selectedModuleNames.isEmpty ||
          selectedModuleNames.contains(moduleName);
      final matchesSearch =
          eventSearch.isEmpty || eventName.contains(eventSearch);

      return matchesEventName && matchesModuleName && matchesSearch;
    }).toList();
    String prettyJson;
    try {
      final copyData = filteredEntries
          .map((e) => {
                'timestamp': e.timestamp.toIso8601String(),
                'event': _parsePayload(e.json),
              })
          .toList();
      prettyJson = const JsonEncoder.withIndent('  ').convert(copyData);
    } catch (_) {
      prettyJson = allData.toString();
    }
    Clipboard.setData(ClipboardData(text: prettyJson));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('复制成功')),
      );
    }
  }

  void _onSettingsTap() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无设置项，敬请期待')),
      );
    }
  }
}

extension Data on _HomePageState {
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

  Map<String, int> _collectModuleCounts(
      List<DataEntry> entries, String search) {
    final Map<String, int> counts = {};
    for (var entry in entries) {
      final moduleName = _extractModuleName(entry.json);
      final eventName = _extractEventName(entry.json);
      if (search.isEmpty || eventName.contains(search)) {
        counts[moduleName] = (counts[moduleName] ?? 0) + 1;
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
    } catch (_) {}
    return {};
  }

  String _extractEventName(String json) {
    final payload = _parsePayload(json);
    final value = payload['event_name'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'null';
  }

  String _extractModuleName(String json) {
    final payload = _parsePayload(json);
    final value = payload['module_name'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'null';
  }

  String _extractCodeLine(String json) {
    final payload = _parsePayload(json);
    final value = payload['code_line'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return '';
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
}
