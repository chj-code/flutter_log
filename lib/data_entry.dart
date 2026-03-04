import 'package:intl/intl.dart';

class DataEntry {
  final String id;
  final String device;
  final DateTime timestamp;
  final String json;

  DataEntry({
    required this.id,
    required this.device,
    required this.timestamp,
    required this.json,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'device': device,
      'timestamp': timestamp.toIso8601String(),
      'json': json,
    };
  }

  factory DataEntry.fromJson(Map<String, dynamic> m) {
    return DataEntry(
      id: m['id'] as String,
      device: m['device'] as String,
      timestamp: DateTime.parse(m['timestamp'] as String),
      json: m['json'] as String,
    );
  }
  String get displayTime {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);
  }
}

/// 设置中可以用来选择屏蔽的事件列表 ()
final List<SetEventModel> setEventNames = [
  SetEventModel(name:"hot_event", isChecked: false),
  SetEventModel(name:"before_page_leave", isChecked: false),
];

// 用来设置事件屏蔽
class SetEventModel {
  String name;
  bool isChecked;
  SetEventModel({
    required this.name,
    this.isChecked = false,
  });
}
