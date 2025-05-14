import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/entities/location.dart';

abstract class LocationDataSource {
  Future<Location> getCurrentLocation();
  Future<void> saveLocation(Location location);
  Future<void> startTracking();
  Future<void> stopTracking();
}

class LocationDataSourceImpl implements LocationDataSource {
  // Flag để biết nếu dịch vụ đang tracking
  bool _isTracking = false;
  
  // Firebase
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  
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
    
    // Lấy vị trí hiện tại
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
  Future<void> saveLocation(Location location) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Người dùng chưa đăng nhập');
      }
      
      final locationRef = _database.ref()
          .child('locations')
          .child(currentUser.uid);
      
      await locationRef.set({
        'latitude': location.latitude,
        'longitude': location.longitude,
        'timestamp': location.timestamp.millisecondsSinceEpoch,
      });
      
      // Cập nhật vị trí trong hồ sơ người dùng
      await _database.ref().child('users').child(currentUser.uid).update({
        'lastLocation': {
          'latitude': location.latitude,
          'longitude': location.longitude,
          'timestamp': location.timestamp.millisecondsSinceEpoch,
        }
      });
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
      
      // TODO: Implement actual background tracking
      // Đây là một implementation đơn giản, trong thực tế bạn sẽ sử dụng
      // một plugin background service hoặc workmanager
      
      _isTracking = true;
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
      // TODO: Implement actual background tracking stop
      
      _isTracking = false;
    } catch (e) {
      throw Exception('Không thể dừng theo dõi vị trí: $e');
    }
  }
} 