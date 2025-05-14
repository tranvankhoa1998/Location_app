// lib/data/repositories/location_repository_impl.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;
  final FirebaseDatabase _database;

  LocationRepositoryImpl(this.dataSource, this._database);

  @override
  Future<Location> getCurrentLocation() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      throw Exception('Cần quyền truy cập vị trí để sử dụng tính năng này');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<DatabaseEvent> getUserLocationStream(String userId) {
    return _database.ref().child('locations').child(userId).onValue;
  }

  @override
  Future<void> saveLocation(Location location) async {
    await dataSource.saveLocation(location);
  }

  @override
  Future<void> startTracking() async {
    await dataSource.startTracking();
  }

  @override
  Future<void> stopTracking() async {
    await dataSource.stopTracking();
  }

  @override
  Future<void> updateLocation(String userId, Location location) async {
    try {
      // Kiểm tra quyền truy cập vị trí
      final status = await Permission.location.request();
      if (status.isDenied) {
        throw Exception('Cần quyền truy cập vị trí để sử dụng tính năng này');
      }

      // Lấy vị trí hiện tại (thay vì sử dụng vị trí được truyền vào)
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      // Tạo dữ liệu vị trí cụ thể hơn
      final locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'altitude': position.altitude,
        'speed': position.speed,
        'heading': position.heading,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      // Lưu vị trí vào Realtime Database
      await _database.ref().child('locations').child(userId).set(locationData);
      
      // Cập nhật lastLocation trong user profile
      await _database.ref().child('users').child(userId).update({
        'lastLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      });
    } catch (e) {
      throw Exception('Không thể cập nhật vị trí: $e');
    }
  }
}