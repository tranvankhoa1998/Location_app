import 'dart:async';
import 'dart:math' show asin, cos, sqrt, sin, pi;
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:get_it/get_it.dart';
import 'package:geolocator/geolocator.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_users_by_role.dart';

class UserDistanceScreen extends StatefulWidget {
  const UserDistanceScreen({Key? key}) : super(key: key);

  @override
  _UserDistanceScreenState createState() => _UserDistanceScreenState();
}

class _UserDistanceScreenState extends State<UserDistanceScreen> {
  final _getUsersByRole = GetIt.instance<GetUsersByRole>();
  Timer? _refreshTimer;
  List<UserDistanceInfo> _usersWithDistance = [];
  Position? _adminPosition;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAdminLocation();
    _loadUsersAndStartTracking();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  // Hàm tính khoảng cách giữa hai điểm (công thức Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double latDiff = _toRadians(lat2 - lat1);
    final double lngDiff = _toRadians(lon2 - lon1);
    
    final double a = sin(latDiff / 2) * sin(latDiff / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(lngDiff / 2) * sin(lngDiff / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Lấy vị trí của admin
  Future<void> _loadAdminLocation() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không có quyền truy cập vị trí'))
        );
        return;
      }
      
      // Lấy vị trí hiện tại của admin
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      setState(() {
        _adminPosition = position;
      });
      
      // Lưu vị trí admin vào database
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final locationData = {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'isAdmin': true,
        };
        
        await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(currentUser.uid)
            .set(locationData);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy vị trí: $e'))
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Tải danh sách người dùng và bắt đầu theo dõi vị trí
  Future<void> _loadUsersAndStartTracking() async {
    // Lấy danh sách người dùng thường
    final usersStream = _getUsersByRole(UserRole.user);
    
    usersStream.listen((users) {
      for (var user in users) {
        // Thêm user vào danh sách theo dõi nhưng chưa có vị trí
        if (!_usersWithDistance.any((u) => u.userId == user.id)) {
          _usersWithDistance.add(UserDistanceInfo(
            userId: user.id,
            name: user.name,
            email: user.email,
          ));
        }
      }
      
      // Bắt đầu theo dõi vị trí
      _startLocationTracking();
    });
  }

  void _startLocationTracking() {
    // Đảm bảo chỉ có một timer đang chạy
    _refreshTimer?.cancel();
    
    // Cập nhật vị trí ngay lập tức
    _refreshUserLocations();
    
    // Thiết lập timer để cập nhật vị trí mỗi 30 giây
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshUserLocations();
    });
  }

  Future<void> _refreshUserLocations() async {
    // Cập nhật vị trí admin trước
    await _loadAdminLocation();
    
    if (_adminPosition == null || _usersWithDistance.isEmpty) return;
    
    for (var userInfo in _usersWithDistance) {
      try {
        // Lấy dữ liệu vị trí từ Firebase Realtime Database
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(userInfo.userId)
            .get();
        
        if (snapshot.exists && snapshot.value != null) {
          final locationData = Map<String, dynamic>.from(snapshot.value as Map);
          
          // Bỏ qua nếu đây là admin
          if (locationData['isAdmin'] == true) continue;
          
          final lat = (locationData['latitude'] as num).toDouble();
          final lng = (locationData['longitude'] as num).toDouble();
          final timestamp = DateTime.fromMillisecondsSinceEpoch(locationData['timestamp'] as int);
          
          // Tính khoảng cách
          final distance = _calculateDistance(
            _adminPosition!.latitude, 
            _adminPosition!.longitude,
            lat, 
            lng
          );
          
          // Cập nhật thông tin
          setState(() {
            userInfo.latitude = lat;
            userInfo.longitude = lng;
            userInfo.lastUpdated = timestamp;
            userInfo.distance = distance;
            userInfo.hasLocation = true;
          });
        }
      } catch (e) {
        print('Lỗi khi lấy vị trí cho người dùng ${userInfo.userId}: $e');
      }
    }
    
    // Sắp xếp theo khoảng cách
    setState(() {
      _usersWithDistance.sort((a, b) {
        if (!a.hasLocation && !b.hasLocation) return 0;
        if (!a.hasLocation) return 1;
        if (!b.hasLocation) return -1;
        return a.distance!.compareTo(b.distance!);
      });
    });
  }

  // Format khoảng cách
  String _formatDistance(double? distanceKm) {
    if (distanceKm == null) return 'Chưa có';
    if (distanceKm < 1) {
      // Nếu dưới 1km, hiển thị theo mét
      return '${(distanceKm * 1000).toInt()} m';
    } else if (distanceKm < 10) {
      // Nếu dưới 10km, làm tròn 1 chữ số
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      // Nếu trên 10km, làm tròn số nguyên
      return '${distanceKm.toInt()} km';
    }
  }
  
  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa cập nhật';
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Lọc theo tìm kiếm
    final filteredUsers = _searchQuery.isEmpty
        ? _usersWithDistance
        : _usersWithDistance.where((user) =>
            user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            user.email.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Khoảng cách tới người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật vị trí',
            onPressed: _refreshUserLocations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thông tin vị trí admin
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.my_location, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Vị trí của bạn',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          if (_adminPosition != null)
                            Text(
                              'Vĩ độ: ${_adminPosition!.latitude.toStringAsFixed(6)}, '
                              'Kinh độ: ${_adminPosition!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontSize: 12),
                            )
                          else
                            const Text(
                              'Chưa có vị trí',
                              style: TextStyle(fontSize: 12, color: Colors.red),
                            ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cập nhật'),
                      onPressed: _loadAdminLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Thanh tìm kiếm
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
            ),
          ),
          
          // Danh sách người dùng với khoảng cách
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Chưa có người dùng nào'
                                  : 'Không tìm thấy người dùng',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          final hasLocation = user.hasLocation;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: hasLocation ? Colors.green.shade100 : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: hasLocation
                                          ? Text(
                                              _formatDistance(user.distance).split(' ')[0],
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.green.shade800,
                                              ),
                                            )
                                          : Icon(
                                              Icons.location_off,
                                              color: Colors.grey.shade500,
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: hasLocation ? Colors.green.shade50 : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.directions_walk,
                                                    size: 14,
                                                    color: hasLocation ? Colors.green.shade800 : Colors.grey.shade600,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Khoảng cách: ${_formatDistance(user.distance)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: hasLocation ? Colors.green.shade800 : Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.access_time,
                                                    size: 14,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDateTime(user.lastUpdated).split(' ')[0],
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.blue.shade800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          
          // Nút cập nhật và thông tin
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Cập nhật tự động: mỗi 30 giây',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Cập nhật ngay'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      _refreshUserLocations();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Đang cập nhật vị trí...')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Lớp lưu trữ thông tin khoảng cách đến người dùng
class UserDistanceInfo {
  final String userId;
  final String name;
  final String email;
  double? latitude;
  double? longitude;
  DateTime? lastUpdated;
  double? distance;
  bool hasLocation;
  
  UserDistanceInfo({
    required this.userId,
    required this.name,
    required this.email,
    this.latitude,
    this.longitude,
    this.lastUpdated,
    this.distance,
    this.hasLocation = false,
  });
} 