// lib/data/models/location_model.dart
import '../../domain/entities/location.dart';

class LocationModel extends Location {
  LocationModel({
    required super.latitude,
    required super.longitude,
    required double accuracy,
    required double altitude,
    required double speed,
    required super.timestamp,
  });

  factory LocationModel.fromPosition(dynamic position) {
    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      timestamp: DateTime.now(),
    );
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : 0.0,
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : 0.0,
      accuracy: (json['accuracy'] is num) ? (json['accuracy'] as num).toDouble() : 0.0,
      altitude: (json['altitude'] is num) ? (json['altitude'] as num).toDouble() : 0.0,
      speed: (json['speed'] is num) ? (json['speed'] as num).toDouble() : 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (json['timestamp'] is num) ? (json['timestamp'] as num).toInt() : 0)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}