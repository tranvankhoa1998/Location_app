class Location {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  Location({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      latitude: (map['latitude'] is num) ? (map['latitude'] as num).toDouble() : 0.0,
      longitude: (map['longitude'] is num) ? (map['longitude'] as num).toDouble() : 0.0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        (map['timestamp'] is num) ? (map['timestamp'] as num).toInt() : 0,
      ),
    );
  }
} 