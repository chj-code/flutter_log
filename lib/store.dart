import 'data_entry.dart';

/// 内存数据存储，不持久化到本地
class DataStore {
  final List<DataEntry> _entries = [];

  /// 初始化存储（内存模式无需实际初始化）
  Future<void> init() async {
    _entries.clear();
  }

  /// 获取指定设备的所有数据条目
  List<DataEntry> entriesForDevice(String device) {
    return _entries.where((e) => e.device == device).toList();
  }

  /// 获取所有设备列表
  List<String> devices() {
    return _entries.map((e) => e.device).toSet().toList();
  }

  /// 添加新的数据条目
  Future<void> add(DataEntry e) async {
    _entries.insert(0, e);
  }

  /// 删除指定ID的数据条目
  Future<void> delete(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  /// 删除指定设备的所有数据
  Future<void> deleteDevice(String device) async {
    _entries.removeWhere((e) => e.device == device);
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    _entries.clear();
  }

  /// 获取所有数据条目数量
  int get totalCount => _entries.length;
}
