// lib/data/models/location_model.dart
import '../../domain/entities/location.dart';

class LocationModel extends Location {
  LocationModel({
    required double latitude,
    required double longitude,
    required double accuracy,
    required double altitude,
    required double speed,
    required DateTime timestamp,
  }) : super(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          altitude: altitude,
          speed: speed,
          timestamp: timestamp,
        );

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
      latitude: json['latitude'],
      longitude: json['longitude'],
      accuracy: json['accuracy'] ?? 0.0,
      altitude: json['altitude'] ?? 0.0,
      speed: json['speed'] ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}