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
  Stream<Position> getPositionStream();
}

class LocationDataSourceImpl implements LocationDataSource {
  // Flag để biết nếu dịch vụ đang tracking
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStreamSubscription;
  
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final _locationController = StreamController<Location>.broadcast();

  LocationDataSourceImpl() {
    // Khởi tạo sẽ được xử lý riêng khi các phương thức được gọi
    // thay vì ném lỗi trong constructor
  }

  @override
  Future<Location> getCurrentLocation() async {
    // Kiểm tra quyền truy cập vị trí
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Quyền truy cập vị trí bị từ chối');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.'
      );
    }
    
    // Kiểm tra dịch vụ vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí bị tắt');
    }
    
    // Lấy vị trí hiện tại sử dụng cách khuyến nghị thay vì desiredAccuracy
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
    
    // Chuyển đổi thành đối tượng Location
    return Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );
  }
  @override
  Stream<Location> getLocationStream() async* {
    // Kiểm tra quyền truy cập vị trí
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
    
    // Kiểm tra dịch vụ vị trí
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Dịch vụ vị trí bị tắt');
    }
    
    // Tạo stream vị trí với độ chính xác cao
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Cập nhật khi di chuyển ít nhất 5m
    );
    
    // Lấy vị trí liên tục từ GPS/WiFi/di động
    await for (Position position in Geolocator.getPositionStream(locationSettings: locationSettings)) {
      final location = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      
      // Tự động lưu vị trí vào Firebase
      try {
        await saveLocation(location);
        print('Đã lưu vị trí mới: ${location.latitude}, ${location.longitude}');
      } catch (e) {
        print('Lỗi lưu vị trí: $e');
      }
      
      yield location;
    }
  }
  @override
  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Cập nhật khi di chuyển ít nhất 10m
    );
    
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @override
  Future<void> saveLocation(Location location) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }
      
      final locationRef = _database.ref()
          .child('locations')
          .child(currentUser.uid);
      
      // Lưu với thông tin chi tiết hơn
      await locationRef.set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp.millisecondsSinceEpoch,
      });
      
      print('Đã lưu vị trí: ${location.latitude}, ${location.longitude}');
    } catch (e) {
      throw Exception('Không thể lưu vị trí: $e');
    }
  }
  @override
  Future<void> startTracking() async {
    if (_isTracking) {
      return; // Đã tracking rồi, không cần bắt đầu lại
    }
    
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Quyền truy cập vị trí bị từ chối');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.'
        );
      }
      
      // Bắt đầu theo dõi vị trí thực sự
      _positionStreamSubscription = getPositionStream().listen(
        (Position position) async {
          final location = Location(
            latitude: position.latitude,
            longitude: position.longitude,
            timestamp: DateTime.now(),
          );
          
          // Lưu vị trí và emit đến stream
          await saveLocation(location);
          _locationController.add(location);
        },
        onError: (error) {
          print('Lỗi tracking vị trí: $error');
        },
      );
      
      _isTracking = true;
      print('Đã bắt đầu tracking vị trí');
    } catch (e) {
      throw Exception('Không thể bắt đầu theo dõi vị trí: $e');
    }
  }
  @override
  Future<void> stopTracking() async {
    if (!_isTracking) {
      return; // Không tracking, không cần dừng
    }
    
    try {
      // Hủy subscription position stream
      await _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      
      _isTracking = false;
      print('Đã dừng tracking vị trí');
    } catch (e) {
      throw Exception('Không thể dừng theo dõi vị trí: $e');
    }
  }
}