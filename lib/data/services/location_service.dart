import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateUserLocation(String userId) async {
    // Kiểm tra quyền truy cập vị trí
    final status = await Permission.location.request();
    if (status.isDenied) {
      throw Exception('Cần quyền truy cập vị trí để sử dụng tính năng này');
    }

    // Lấy vị trí hiện tại
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    // Cập nhật vị trí vào Firestore
    await _firestore.collection('users').doc(userId).update({
      'lastLocation': GeoPoint(position.latitude, position.longitude),
      'lastLocationUpdate': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getUserLocationStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }
} 