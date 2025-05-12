import 'dart:async';
import 'dart:math' show asin, cos, sqrt, sin, pi;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_users_by_role.dart';
import '../../../domain/entities/location.dart';

// Thêm vị trí và khoảng cách của admin
class AdminLocationInfo {
  double? latitude;
  double? longitude;
  DateTime? timestamp;
  bool hasLocation = false;

  void updateLocation(double lat, double lng) {
    latitude = lat;
    longitude = lng;
    timestamp = DateTime.now();
    hasLocation = true;
  }

  // Tính khoảng cách giữa vị trí admin và một vị trí khác (km)
  double distanceTo(double lat, double lng) {
    if (!hasLocation) return 0;
    
    // Công thức Haversine tính khoảng cách giữa 2 điểm trên Trái đất
    const double earthRadius = 6371; // km
    final double latDiff = _toRadians(lat - latitude!);
    final double lngDiff = _toRadians(lng - longitude!);
    
    final double a = sin(latDiff / 2) * sin(latDiff / 2) +
        cos(_toRadians(latitude!)) * cos(_toRadians(lat)) *
        sin(lngDiff / 2) * sin(lngDiff / 2);
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }
  
  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}

class OverallMapScreen extends StatefulWidget {
  const OverallMapScreen({Key? key}) : super(key: key);

  @override
  _OverallMapScreenState createState() => _OverallMapScreenState();
}

class _OverallMapScreenState extends State<OverallMapScreen> {
  final _getUsersByRole = GetIt.instance<GetUsersByRole>();
  GoogleMapController? _mapController;
  Map<String, Marker> _markers = {};
  Timer? _refreshTimer;
  final Set<String> _monitoredUserIds = {};
  // Map lưu thông tin user được theo dõi
  final Map<String, UserTrackingInfo> _monitoredUsers = {};
  
  // Thêm biến quản lý vị trí admin
  final AdminLocationInfo _adminLocation = AdminLocationInfo();
  
  // Vị trí mặc định là Đà Nẵng
  final _defaultPosition = const LatLng(16.0544, 108.2022);
  
  // Các biến trạng thái UI
  bool _isUserListExpanded = true;
  String _searchQuery = '';
  String? _selectedUserId;
  bool _isLoadingAdminLocation = false;
  
  @override
  void initState() {
    super.initState();
    _loadAdminLocation();
    _loadUsersAndStartTracking();
  }
  
  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }
  
  // Hàm lấy vị trí của admin
  Future<void> _loadAdminLocation() async {
    setState(() {
      _isLoadingAdminLocation = true;
    });
    
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        print('Không có quyền truy cập vị trí');
        return;
      }
      
      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Cập nhật vị trí admin
      _adminLocation.updateLocation(position.latitude, position.longitude);
      
      // Lưu vị trí admin vào database (chỉ lưu trong backend, không hiển thị)
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
            
        print('Đã cập nhật vị trí admin: ${position.latitude}, ${position.longitude}');
      }
    } catch (e) {
      print('Lỗi khi lấy vị trí admin: $e');
    } finally {
      setState(() {
        _isLoadingAdminLocation = false;
      });
    }
  }
  
  // Format khoảng cách
  String _formatDistance(double distanceKm) {
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
  
  Future<void> _loadUsersAndStartTracking() async {
    // Lấy danh sách người dùng thường (không bao gồm admin)
    final usersStream = _getUsersByRole(UserRole.user);
    
    usersStream.listen((users) {
      print('Nhận được ${users.length} người dùng thường để theo dõi vị trí');
      setState(() {
        // Thêm vào danh sách theo dõi
        for (var user in users) {
          _monitoredUserIds.add(user.id);
          // Thêm thông tin user vào map
          _monitoredUsers[user.id] = UserTrackingInfo(
            userId: user.id,
            name: user.name,
            email: user.email,
            isVisible: true, // Mặc định hiển thị tất cả
          );
          print('Thêm người dùng ${user.name} (${user.email}) vào danh sách theo dõi');
        }
      });
      
      // Bắt đầu theo dõi vị trí
      _startLocationTracking();
    });
  }
  
  void _startLocationTracking() {
    // Đảm bảo chỉ có một timer đang chạy
    _refreshTimer?.cancel();
    
    // Cập nhật vị trí ngay lập tức
    _refreshUserLocations();
    
    // Thiết lập timer để cập nhật vị trí mỗi 1 phút
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshUserLocations();
    });
  }
  
  Future<void> _refreshUserLocations() async {
    if (_monitoredUserIds.isEmpty) return;
    
    // Cập nhật vị trí admin nếu chưa có
    if (!_adminLocation.hasLocation) {
      await _loadAdminLocation();
    }
    
    for (final userId in _monitoredUserIds) {
      try {
        // Lấy dữ liệu vị trí từ Firebase Realtime Database
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('locations')
            .child(userId)
            .get();
        
        if (snapshot.exists && snapshot.value != null) {
          final locationData = Map<String, dynamic>.from(snapshot.value as Map);
          
          // Kiểm tra nếu đây là admin thì bỏ qua hiển thị marker
          if (locationData['isAdmin'] == true) {
            continue;
          }
          
          // Lấy thông tin người dùng
          final userSnapshot = await FirebaseDatabase.instance
              .ref()
              .child('users')
              .child(userId)
              .get();
          
          String userName = 'Người dùng';
          if (userSnapshot.exists && userSnapshot.value != null) {
            final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
            userName = userData['name'] ?? 'Người dùng';
            
            // Cập nhật tên người dùng trong danh sách theo dõi
            if (_monitoredUsers.containsKey(userId)) {
              _monitoredUsers[userId]!.name = userName;
            }
          }
          
          // Tạo vị trí từ dữ liệu
          final location = Location(
            latitude: (locationData['latitude'] as num).toDouble(),
            longitude: (locationData['longitude'] as num).toDouble(),
            timestamp: DateTime.fromMillisecondsSinceEpoch(locationData['timestamp'] as int),
          );
          
          // Tính khoảng cách từ admin đến user này
          double distance = 0;
          if (_adminLocation.hasLocation) {
            distance = _adminLocation.distanceTo(
              location.latitude, 
              location.longitude
            );
            
            // Lưu khoảng cách vào user tracking info
            if (_monitoredUsers.containsKey(userId)) {
              _monitoredUsers[userId]!.distanceFromAdmin = distance;
            }
          }
          
          // Lấy thông tin về tốc độ và độ chính xác
          final speed = locationData['speed'] != null ? (locationData['speed'] as num).toDouble() : 0.0;
          final accuracy = locationData['accuracy'] != null ? (locationData['accuracy'] as num).toDouble() : 0.0;
          
          // Cập nhật marker nếu người dùng được đặt là hiển thị
          if (mounted && _monitoredUsers[userId]?.isVisible == true) {
            setState(() {
              _markers[userId] = Marker(
                markerId: MarkerId(userId),
                position: LatLng(location.latitude, location.longitude),
                infoWindow: InfoWindow(
                  title: userName,
                  snippet: 'Khoảng cách: ${_formatDistance(distance)} | '
                      'Cập nhật: ${_formatDateTime(location.timestamp)}',
                ),
              );
              
              // Cập nhật thông tin vị trí trong danh sách theo dõi
              if (_monitoredUsers.containsKey(userId)) {
                _monitoredUsers[userId]!.lastLocation = location;
                _monitoredUsers[userId]!.hasLocation = true;
              }
            });
          } else if (!_monitoredUsers[userId]!.isVisible && _markers.containsKey(userId)) {
            // Nếu không hiển thị, xoá marker khỏi bản đồ
            setState(() {
              _markers.remove(userId);
            });
          }
        }
      } catch (e) {
        print('Lỗi khi lấy vị trí cho người dùng $userId: $e');
      }
    }
  }
  
  void _toggleUserVisibility(String userId) {
    setState(() {
      final user = _monitoredUsers[userId];
      if (user != null) {
        user.isVisible = !user.isVisible;
        
        // Nếu ẩn, xoá marker
        if (!user.isVisible && _markers.containsKey(userId)) {
          _markers.remove(userId);
        } 
        // Nếu hiện, cập nhật lại vị trí
        else if (user.isVisible && user.hasLocation) {
          _refreshUserLocations();
        }
      }
    });
  }
  
  // Di chuyển camera đến vị trí của user và hiển thị thông tin
  void _focusOnUser(String userId) {
    final user = _monitoredUsers[userId];
    if (user != null && user.hasLocation && user.lastLocation != null && _mapController != null) {
      // Đặt user được chọn
      setState(() {
        _selectedUserId = userId;
      });
      
      // Di chuyển camera đến vị trí của user với animation
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              user.lastLocation!.latitude, 
              user.lastLocation!.longitude
            ),
            zoom: 16.0,
            bearing: 0,
            tilt: 0,
          ),
        ),
      ).then((_) {
        // Sau khi camera đã di chuyển, thêm hiệu ứng bounce nhỏ
        if (mounted) {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(
                  user.lastLocation!.latitude, 
                  user.lastLocation!.longitude
                ),
                zoom: 16.5,
                bearing: 0,
                tilt: 30, // Nghiêng camera để tạo hiệu ứng 3D
              ),
            ),
          );
        }
      });
      
      // Hiển thị thông báo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 12,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : "?",
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đang hiển thị vị trí của ${user.name}'),
                    Text(
                      'Cập nhật: ${_formatDateTime(user.lastLocation!.timestamp)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.blue,
          action: SnackBarAction(
            label: 'ĐÓNG',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } else {
      // Thông báo nếu user chưa cập nhật vị trí
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white,
                radius: 12,
                child: Icon(Icons.location_off, size: 14, color: Colors.orange),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  user != null 
                      ? '${user.name} chưa cập nhật vị trí' 
                      : 'Không tìm thấy thông tin người dùng'
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} '
        '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách user theo tìm kiếm
    final filteredUsers = _searchQuery.isEmpty
        ? _monitoredUsers
        : Map.fromEntries(
            _monitoredUsers.entries.where((entry) =>
                entry.value.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                entry.value.email.toLowerCase().contains(_searchQuery.toLowerCase())),
          );
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ theo dõi vị trí'),
        actions: [
          // Nút ẩn/hiện danh sách user
          IconButton(
            icon: Icon(_isUserListExpanded ? Icons.list : Icons.map),
            tooltip: _isUserListExpanded ? 'Ẩn danh sách' : 'Hiện danh sách',
            onPressed: () {
              setState(() {
                _isUserListExpanded = !_isUserListExpanded;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Cập nhật vị trí',
            onPressed: _refreshUserLocations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Thanh tìm kiếm và danh sách user - ẩn/hiện được
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _isUserListExpanded ? null : 0,
            child: Container(
              color: Colors.grey.shade100,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header với tiêu đề và nút điều khiển
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'đang theo dõi (${_monitoredUsers.length})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        // Nút hiển thị tất cả
                        InkWell(
                          onTap: () {
                            setState(() {
                              for (var user in _monitoredUsers.values) {
                                user.isVisible = true;
                              }
                              _refreshUserLocations();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Hiển thị tất cả người dùng'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility, size: 14, color: Colors.blue.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Hiện tất cả',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Nút ẩn tất cả
                        InkWell(
                          onTap: () {
                            setState(() {
                              for (var user in _monitoredUsers.values) {
                                user.isVisible = false;
                              }
                              _markers.clear();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Đã ẩn tất cả người dùng'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.visibility_off, size: 14, color: Colors.grey.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Ẩn tất cả',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Thanh tìm kiếm
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm người dùng...',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 18),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  
                  // Hướng dẫn sử dụng
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          'Nhấn để xem vị trí, giữ lâu để ẩn/hiện',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Danh sách người dùng dạng chips
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    constraints: const BoxConstraints(maxHeight: 60),
                    child: filteredUsers.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _searchQuery.isEmpty
                                ? 'Chưa có người dùng nào để theo dõi'
                                : 'Không tìm thấy người dùng nào',
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final userId = filteredUsers.keys.elementAt(index);
                            final user = filteredUsers[userId]!;
                            final isSelected = _selectedUserId == userId;
                            
                            return Padding(
                              padding: const EdgeInsets.only(right: 8, bottom: 4),
                              child: InkWell(
                                onLongPress: () {
                                  _toggleUserVisibility(userId);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      )
                                    ] : null,
                                  ),
                                  child: ActionChip(
                                    backgroundColor: isSelected 
                                      ? Colors.blue.shade200
                                      : (user.isVisible ? Colors.blue.shade100 : Colors.grey.shade200),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: BorderSide(
                                        color: isSelected 
                                          ? Colors.blue
                                          : (user.isVisible ? Colors.blue.shade200 : Colors.transparent),
                                        width: isSelected ? 1.5 : 0.5,
                                      ),
                                    ),
                                    elevation: isSelected ? 2 : 0,
                                    label: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          user.name,
                                          style: TextStyle(
                                            color: user.isVisible ? Colors.blue.shade800 : Colors.grey.shade700,
                                            fontWeight: isSelected || user.isVisible ? FontWeight.bold : FontWeight.normal,
                                            fontSize: 13,
                                          ),
                                        ),
                                        if (user.hasLocation)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    avatar: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: user.isVisible
                                            ? (user.hasLocation ? Colors.blue.shade50 : Colors.orange.shade50)
                                            : Colors.grey.shade200,
                                          radius: 12,
                                          child: Icon(
                                            user.isVisible 
                                              ? (user.hasLocation ? Icons.person_pin_circle : Icons.person_outline)
                                              : Icons.person_off_outlined,
                                            size: 14,
                                            color: user.isVisible
                                              ? (user.hasLocation ? Colors.blue.shade800 : Colors.orange)
                                              : Colors.grey.shade600,
                                          ),
                                        ),
                                        if (!user.isVisible)
                                          Positioned(
                                            right: 0,
                                            bottom: 0,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade100,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1),
                                              ),
                                              child: Icon(
                                                Icons.visibility_off,
                                                size: 6,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _selectedUserId = userId;
                                      });
                                      
                                      // Nếu không hiển thị, bật hiển thị trước
                                      if (!user.isVisible) {
                                        _toggleUserVisibility(userId);
                                      }
                                      // Di chuyển đến vị trí
                                      _focusOnUser(userId);
                                    },
                                    tooltip: "Nhấn để xem vị trí, giữ lâu để ẩn/hiện",
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                  
                  // Đường phân cách
                  Divider(height: 1, color: Colors.grey.shade300),
                ],
              ),
            ),
          ),
          
          // Nút hiện/ẩn panel khi đã ẩn
          if (!_isUserListExpanded)
            InkWell(
              onTap: () {
                setState(() {
                  _isUserListExpanded = true;
                });
              },
              child: Container(
                width: double.infinity,
                color: Colors.blue.shade50,
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.blue.shade800),
                    const SizedBox(width: 4),
                    Text(
                      'Hiển thị danh sách người dùng',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Bản đồ
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _defaultPosition,
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  markers: _markers.values.toSet(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  compassEnabled: true,
                  mapToolbarEnabled: true,
                ),
                
                // Nút thu gọn bản đồ (chỉ hiện khi danh sách user đang ẩn)
                if (!_isUserListExpanded)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.white,
                      elevation: 2,
                      onPressed: () {
                        setState(() {
                          _isUserListExpanded = true;
                        });
                      },
                      child: Icon(Icons.people, color: Colors.blue.shade800),
                    ),
                  ),
              ],
            ),
          ),
          
          // Panel thông tin phía dưới
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thông tin hiển thị
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, size: 14, color: Colors.blue.shade700),
                          const SizedBox(width: 4),
                          Text(
                            'Hiển thị: ${_markers.length}/${_monitoredUsers.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Thông tin thời gian cập nhật
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.update, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Cập nhật: 1 phút/lần',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                // Thông tin người dùng được chọn (nếu có)
                if (_selectedUserId != null && _monitoredUsers.containsKey(_selectedUserId))
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            radius: 16,
                            child: Text(
                              _monitoredUsers[_selectedUserId]!.name.isNotEmpty
                                ? _monitoredUsers[_selectedUserId]!.name[0].toUpperCase()
                                : "?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _monitoredUsers[_selectedUserId]!.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                ),
                                if (_monitoredUsers[_selectedUserId]!.hasLocation)
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 12, color: Colors.blue.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Cập nhật: ${_formatDateTime(_monitoredUsers[_selectedUserId]!.lastLocation!.timestamp)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _monitoredUsers[_selectedUserId]!.isVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                              color: _monitoredUsers[_selectedUserId]!.isVisible
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                              size: 20,
                            ),
                            onPressed: () => _toggleUserVisibility(_selectedUserId!),
                            tooltip: _monitoredUsers[_selectedUserId]!.isVisible
                                ? 'Ẩn người dùng này'
                                : 'Hiện người dùng này',
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Nút cập nhật
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Cập nhật ngay'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _refreshUserLocations();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Đang cập nhật vị trí...'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
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

// Lớp lưu trữ thông tin người dùng đang theo dõi
class UserTrackingInfo {
  final String userId;
  String name;
  final String email;
  bool isVisible;
  bool hasLocation;
  Location? lastLocation;
  double? distanceFromAdmin;
  
  UserTrackingInfo({
    required this.userId,
    required this.name,
    required this.email,
    this.isVisible = true,
    this.hasLocation = false,
    this.lastLocation,
    this.distanceFromAdmin,
  });
} 