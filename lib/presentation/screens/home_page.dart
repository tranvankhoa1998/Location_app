import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import '../screens/task_list.dart';
import '../screens/task_cubit.dart';        
import 'calendar_page.dart';
import 'create_new_task_page.dart';
import '../features/location/pages/location_map_page.dart';
import '../features/location/cubit/location_cubit.dart';
import '../../domain/entities/user.dart';
import '../../domain/usecases/update_location.dart';
import '../../domain/usecases/get_location_stream.dart';
import '../../domain/entities/location.dart' as location_entity;

// Lấy GetIt instance
final sl = GetIt.instance;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isUpdatingLocation = false;
  String? _locationError;
  DateTime? _lastLocationUpdate;

  // Phương thức để cập nhật vị trí trực tiếp
  Future<void> _updateLocationDirectly() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      setState(() {
        _locationError = 'Bạn cần đăng nhập để cập nhật vị trí';
      });
      return;
    }

    setState(() {
      _isUpdatingLocation = true;
      _locationError = null;
    });

    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isUpdatingLocation = false;
            _locationError = 'Quyền truy cập vị trí bị từ chối';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _isUpdatingLocation = false;
          _locationError = 'Quyền truy cập vị trí bị từ chối vĩnh viễn. Vui lòng vào Cài đặt để cấp quyền.';
        });
        return;
      }

      // Kiểm tra dịch vụ vị trí
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isUpdatingLocation = false;
          _locationError = 'Dịch vụ vị trí bị tắt';
        });
        return;
      }

      // Lấy vị trí hiện tại
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Tạo dữ liệu vị trí
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
      await FirebaseDatabase.instance
          .ref()
          .child('locations')
          .child(currentUser.uid)
          .set(locationData);

      // Cập nhật lastLocation trong user profile
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .update({
        'lastLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }
      });

      setState(() {
        _isUpdatingLocation = false;
        _lastLocationUpdate = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật vị trí thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdatingLocation = false;
        _locationError = 'Lỗi cập nhật vị trí: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          // Nút bản đồ với tooltip
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Xem vị trí của bạn',
            onPressed: () {
              _navigateToMapPage(context, currentUser);
            },
          ),
          // Nút lịch
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Lịch',
            onPressed: () {
              // LẤY CUBIT HIỆN TẠI
              final taskCubit = BlocProvider.of<TaskCubit>(context);
              
              // TRUYỀN CUBIT VÀO TRANG MỚI
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: taskCubit,
                    child: CalendarPage(),
                  ),
                ),
              );
            },
          ),
          // Nút đăng xuất
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              // Hiển thị hộp thoại xác nhận
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Đăng xuất'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await auth.FirebaseAuth.instance.signOut();
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin người dùng
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  radius: 30,
                  child: const Icon(Icons.person, color: Colors.blue, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Người dùng',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Hiển thị vai trò thay vì ID
                      const Text(
                        'Vai trò: Thành viên',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Location status and quick update
          Container(
            padding: const EdgeInsets.all(16),
            color: _locationError != null ? Colors.red.shade50 : Colors.green.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _locationError != null ? Icons.location_off : Icons.location_on,
                      color: _locationError != null ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationError != null
                            ? 'Lỗi vị trí: $_locationError'
                            : _lastLocationUpdate != null
                                ? 'Vị trí đã cập nhật lúc: ${_formatTime(_lastLocationUpdate!)}'
                                : 'Chưa cập nhật vị trí',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _locationError != null ? Colors.red.shade700 : Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: Text(_isUpdatingLocation ? 'Đang cập nhật...' : 'Cập nhật vị trí ngay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _locationError != null ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isUpdatingLocation ? null : _updateLocationDirectly,
                  ),
                ),
              ],
            ),
          ),
          
          // Banner vị trí
          InkWell(
            onTap: () => _navigateToMapPage(context, currentUser),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.blue.shade50,
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xem vị trí của bạn trên bản đồ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Nhấn để mở bản đồ và xem chi tiết',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, 
                    size: 16, 
                    color: Colors.blue.shade600
                  ),
                ],
              ),
            ),
          ),
          
          // Danh sách task
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.blue.shade600),
                const SizedBox(width: 8),
                Text(
                  'Danh sách công việc',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: TaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // LẤY CUBIT HIỆN TẠI
          final taskCubit = BlocProvider.of<TaskCubit>(context);
          
          // TRUYỀN CUBIT VÀO TRANG MỚI
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: taskCubit,
                child: CreateNewTaskPage(),
              ),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
    );
  }
  
  // Hàm điều hướng đến trang bản đồ
  void _navigateToMapPage(BuildContext context, auth.User? currentUser) {
    try {
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bạn cần đăng nhập để xem vị trí'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Tạo user entity từ Firebase User
      final user = User(
        id: currentUser.uid,
        name: currentUser.email?.split('@').first ?? 'Người dùng',
        email: currentUser.email ?? '',
        role: UserRole.user,
        location: null,
      );
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationMapPage(user: user),
        ),
      );
    } catch (e) {
      print('Error navigating to map page: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi mở trang bản đồ: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  String _formatTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')} ${time.day}/${time.month}';
  }
}