import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'task_list.dart';
import '../../features/location/cubit/task_cubit.dart';        
import 'calendar_page.dart';
import 'create_new_task_page.dart';
import '../../features/location/pages/location_map_page.dart';
import '../../../domain/entities/user.dart' as app_user;
import 'user_profile_edit_screen.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../features/location/cubit/tracking_cubit.dart';
import '../../common/widgets/gradient_card.dart';
import '../../common/widgets/animated_avatar.dart';

// Lấy GetIt instance
final sl = GetIt.instance;

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Biến để kiểm soát chuyển trang
  bool _isNavigating = false;
  DateTime? _lastLocationUpdate;

  @override
  void initState() {
    super.initState();
    // Khởi tạo dữ liệu ban đầu nếu cần
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Đảm bảo thực hiện sau khi frame đầu tiên đã được render
      _checkLastLocationUpdate();
    });
  }

  // Kiểm tra thời gian cập nhật vị trí cuối nếu có
  Future<void> _checkLastLocationUpdate() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser != null && mounted) {
        final ref = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('lastLocation');
        
        final snapshot = await ref.get();
        if (snapshot.exists && snapshot.value != null) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final timestamp = data['timestamp'] as int?;
          
          if (timestamp != null && mounted) {
            setState(() {
              _lastLocationUpdate = DateTime.fromMillisecondsSinceEpoch(timestamp);
            });
          }
        }
      }
    } catch (e) {
      // Error silently ignored in production
    }
  }

  @override
  void dispose() {
    // Giải phóng tài nguyên nếu có
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        elevation: 0, // Bỏ shadow
        backgroundColor: Colors.blue,
        actions: [
          // Nút bản đồ với tooltip
          IconButton(
            icon: const Icon(Icons.location_on),
            tooltip: 'Xem vị trí của bạn',
            onPressed: () {
              // Ngăn chặn user nhấn nút nhiều lần
              if (_isNavigating) return;
              _navigateToMapPage(context, currentUser);
            },
          ),
          // Nút lịch
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Lịch',
            onPressed: () {
              // Ngăn chặn user nhấn nút nhiều lần
              if (_isNavigating) return;
              
              try {
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
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi khi mở trang lịch: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(currentUser?.displayName ?? 'Người dùng'),
              accountEmail: Text(currentUser?.email ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  (currentUser?.email?.isNotEmpty == true) 
                      ? currentUser!.email![0].toUpperCase() 
                      : 'U',
                  style: TextStyle(fontSize: 24.0, color: Colors.blue),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: Icon(Icons.task),
              title: Text('Danh sách nhiệm vụ'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
              },
            ),
            ListTile(
              leading: Icon(Icons.location_on),
              title: Text('Bản đồ vị trí'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                _navigateToMapPage(context, currentUser);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Lịch'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                final taskCubit = BlocProvider.of<TaskCubit>(context);
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
            Divider(),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Chỉnh sửa hồ sơ'),
              subtitle: Text('Cập nhật thông tin cá nhân'),
              onTap: () {
                Navigator.pop(context); // Đóng drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileEditScreen(userId: currentUser?.uid ?? ''),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Đăng xuất'),
              onTap: () async {
                Navigator.pop(context); // Đóng drawer
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
                  // Navigator.of(context) sẽ được xử lý bởi AuthWrapper
                }
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade50, Colors.white],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thông tin người dùng
            FutureBuilder<app_user.User?>(
              future: _getUserData(currentUser?.uid ?? ''),
              builder: (context, snapshot) {
                final String displayName = snapshot.hasData && snapshot.data?.name.isNotEmpty == true
                    ? snapshot.data!.name
                    : currentUser?.displayName ?? 'Người dùng';
                
                final bool isAdmin = snapshot.hasData && 
                    snapshot.data?.role == app_user.UserRole.admin;
                
                return GradientCard(
                  gradientColors: isAdmin 
                      ? [Colors.amber.shade300, Colors.orange.shade700]
                      : [Colors.blue.shade300, Colors.indigo.shade700],
                  elevation: 4,
                  margin: const EdgeInsets.all(16.0),
                  borderRadius: 16,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      AnimatedAvatar(
                        text: displayName,
                        radius: 35,
                        backgroundColor: isAdmin ? Colors.amber : Colors.blue,
                        textColor: Colors.white,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileEditScreen(userId: currentUser?.uid ?? ''),
                            ),
                          ).then((_) {
                            // Làm mới dữ liệu khi quay lại
                            setState(() {});
                          });
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Hiển thị vai trò
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isAdmin ? 'Quản trị viên' : 'Thành viên',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (snapshot.hasData && snapshot.data?.profession != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  '${snapshot.data?.profession}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileEditScreen(userId: currentUser?.uid ?? ''),
                            ),
                          ).then((_) {
                            // Làm mới dữ liệu khi quay lại
                            setState(() {});
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            
            // Banner vị trí - trực tiếp dẫn đến trang bản đồ
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _navigateToMapPage(context, currentUser),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.map, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Xem và cập nhật vị trí của bạn',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Nhấn để mở bản đồ và cập nhật vị trí của bạn',
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
              ),
            ),
            
            // Thêm nút bật/tắt theo dõi vị trí
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: BlocProvider(
                create: (context) => sl<TrackingCubit>()..checkTrackingStatus(),
                child: BlocBuilder<TrackingCubit, TrackingState>(
                  builder: (context, state) {
                    final bool isEnabled = state is TrackingEnabled;
                    
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isEnabled ? Colors.green.shade200 : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isEnabled ? Colors.green.shade100 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.location_searching,
                                color: isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Theo dõi vị trí',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isEnabled ? Colors.green.shade800 : Colors.grey.shade800,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    state is TrackingEnabled
                                        ? 'Đang theo dõi vị trí của bạn'
                                        : state is TrackingDisabled
                                            ? 'Đã tắt theo dõi vị trí'
                                            : state is TrackingInProgress
                                                ? 'Đang thay đổi trạng thái...'
                                                : 'Nhấn để bật theo dõi vị trí của bạn',
                                    style: TextStyle(
                                      color: isEnabled ? Colors.green.shade600 : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: isEnabled,
                              activeColor: Colors.green,
                              onChanged: (bool value) {
                                BlocProvider.of<TrackingCubit>(context).toggleTracking();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Danh sách task
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Danh sách công việc',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
  Future<void> _navigateToMapPage(BuildContext context, auth.User? currentUser) async {
    // Ngăn người dùng nhấn nút nhiều lần
    if (_isNavigating) return;
    
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
      
      // Đặt _isNavigating = true để ngăn truy cập đa luồng
      setState(() {
        _isNavigating = true;
      });
      
      // Tạo user entity từ Firebase User
      final user = app_user.User(
        id: currentUser.uid,
        name: currentUser.email?.split('@').first ?? 'Người dùng',
        email: currentUser.email ?? '',
        role: app_user.UserRole.user,
        location: null,
      );
      
      // Sử dụng await và đồng thời xử lý khi quay lại
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LocationMapPage(user: user),
        ),
      );
      
      // Kiểm tra lại thời gian cập nhật khi quay về và reset trạng thái
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        _checkLastLocationUpdate();
      }
    } catch (e) {
      // Xử lý lỗi chi tiết hơn
      String errorMessage;
      
      if (e is StateError) {
        errorMessage = 'Lỗi trạng thái: ${e.message}';
        print('StateError navigating to map page: $e');
      } else if (e is ArgumentError) {
        errorMessage = 'Lỗi tham số: ${e.message}';
        print('ArgumentError navigating to map page: $e');
      } else {
        errorMessage = 'Lỗi khi mở trang bản đồ: ${e.toString()}';
        print('Unknown error navigating to map page: $e');
      }
      
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<app_user.User?> _getUserData(String userId) async {
    if (userId.isEmpty) return null;
    
    try {
      final userRepository = sl<UserRepository>();
      return await userRepository.getUserById(userId);
    } catch (e) {
      // Error silently ignored in production
      return null;
    }
  }
}