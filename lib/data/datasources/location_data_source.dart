// lib/data/datasources/location_data_source.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/location_model.dart';

abstract class LocationDataSource {
  Future<LocationModel> getCurrentLocation();
  Stream<LocationModel> getLocationStream();
  Future<void> saveLocation(LocationModel location);
  Future<void> startTracking();
  Future<void> stopTracking();
}

class LocationDataSourceImpl implements LocationDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _locationRef;
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<LocationModel>.broadcast();

  LocationDataSourceImpl() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    _locationRef = _database.ref().child('locations').child(userId);
  }

  @override
  Future<LocationModel> getCurrentLocation() async {
    // Kiểm tra quyền truy cập vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí bị tắt');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Quyền truy cập vị trí bị từ chối vĩnh viễn');
    }

    // Lấy vị trí hiện tại
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high
    );
    
    return LocationModel.fromPosition(position);
  }

  @override
  Stream<LocationModel> getLocationStream() {
    return _locationController.stream;
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    try {
      await _locationRef.set(location.toJson());
      print('Location saved to Firebase');
    } catch (e) {
      print('Error saving location to Firebase: $e');
      throw Exception('Không thể lưu vị trí: $e');
    }
  }

  @override
  Future<void> startTracking() async {
    // Cấu hình tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật khi di chuyển 10m
    );
    
    // Lắng nghe thay đổi vị trí
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen((Position position) {
      final locationModel = LocationModel.fromPosition(position);
      
      // Phát ra vị trí mới
      _locationController.add(locationModel);
      
      // Lưu vị trí vào Firebase
      saveLocation(locationModel);
    });
  }

  @override
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}