// lib/data/datasources/location_data_source.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/location.dart';

abstract class LocationDataSource {
  Future<Location> getCurrentLocation();
  Stream<Location> getLocationStream();
  Future<void> saveLocation(Location location);
  Future<void> startTracking();
  Future<void> stopTracking();
}

class LocationDataSourceImpl implements LocationDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late DatabaseReference _locationRef;
  StreamSubscription<Position>? _positionStreamSubscription;
  final _locationController = StreamController<Location>.broadcast();

  LocationDataSourceImpl() {
    // Khởi tạo sẽ được xử lý riêng khi các phương thức được gọi
    // thay vì ném lỗi trong constructor
  }

  // Hàm helper để lấy reference tới node vị trí của người dùng
  DatabaseReference _getLocationRef(String userId) {
    return _database.ref().child('locations').child(userId);
  }

  @override
  Future<Location> getCurrentLocation() async {
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
    
    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }

  @override
  Stream<Location> getLocationStream() {
    return _locationController.stream;
  }

  @override
  Future<void> saveLocation(Location location) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    _locationRef = _getLocationRef(userId);
    
    try {
      await _locationRef.set(location.toMap());
    } catch (e) {
      throw Exception('Không thể lưu vị trí: $e');
    }
  }

  @override
  Future<void> startTracking() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    _locationRef = _getLocationRef(userId);
    
    // Cấu hình tracking
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật khi di chuyển 10m
    );
    
    // Lắng nghe thay đổi vị trí
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings
    ).listen((Position position) {
      final location = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      
      // Phát ra vị trí mới
      _locationController.add(location);
      
      // Lưu vị trí vào Firebase
      saveLocation(location);
    });
  }

  @override
  Future<void> stopTracking() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }
}