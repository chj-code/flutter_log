class DataEntry {
  final String id;
  final String device;
  final DateTime timestamp;
  final String json;

  DataEntry(
      {required this.id,
      required this.device,
      required this.timestamp,
      required this.json});

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
}
