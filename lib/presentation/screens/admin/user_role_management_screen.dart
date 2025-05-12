import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_users_by_role.dart';
import '../../../domain/usecases/update_user_role.dart';

class UserRoleManagementScreen extends StatefulWidget {
  const UserRoleManagementScreen({Key? key}) : super(key: key);

  @override
  _UserRoleManagementScreenState createState() => _UserRoleManagementScreenState();
}

class _UserRoleManagementScreenState extends State<UserRoleManagementScreen> {
  final GetUsersByRole _getUsersByRole = GetIt.instance<GetUsersByRole>();
  final UpdateUserRole _updateUserRole = GetIt.instance<UpdateUserRole>();
  bool _isLoading = false;
  String? _processingUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý phân quyền'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: () {
              setState(() {}); // Force rebuild
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đang làm mới dữ liệu...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Trợ giúp',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Trợ giúp phân quyền'),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cách sử dụng:'),
                      SizedBox(height: 8),
                      Text('• Công tắc BẬT = Quyền admin'),
                      Text('• Công tắc TẮT = Quyền người dùng thường'),
                      SizedBox(height: 12),
                      Text('Lưu ý: Admin có thể xem và quản lý tất cả người dùng'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đã hiểu'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.orange.shade50,
            child: Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.orange.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quản lý quyền người dùng',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bật công tắc để cấp quyền admin cho người dùng',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: Colors.red, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Admin',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'User thường',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<User>>(
              future: Future.wait([
                _getUsersByRole(UserRole.user).first,
                _getUsersByRole(UserRole.admin).first,
              ]).then((results) {
                final users = results[0];  // Kết quả từ UserRole.user
                final admins = results[1]; // Kết quả từ UserRole.admin
                
                print('Tìm thấy ${users.length} người dùng thường và ${admins.length} admin');
                
                // Kết hợp và sắp xếp
                final allUsers = [...admins, ...users];
                allUsers.sort((a, b) {
                  // Sắp xếp: admin trước, user sau, trong mỗi nhóm sắp xếp theo tên
                  if (a.role == b.role) {
                    return a.name.compareTo(b.name);
                  }
                  return a.role == UserRole.admin ? -1 : 1;
                });
                
                return allUsers;
              }),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Đang tải danh sách người dùng...'),
                      ],
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Lỗi: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }
                
                final allUsers = snapshot.data ?? [];
                
                if (allUsers.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('Không có người dùng nào'),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: allUsers.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemBuilder: (context, index) {
                    final user = allUsers[index];
                    final isAdmin = user.role == UserRole.admin;
                    final isProcessing = _processingUserId == user.id;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isAdmin
                                  ? Colors.red.shade100
                                  : Colors.blue.shade100,
                              child: Icon(
                                isAdmin
                                    ? Icons.admin_panel_settings
                                    : Icons.person,
                                color: isAdmin
                                    ? Colors.red
                                    : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.name,
                                    style: TextStyle(
                                      fontWeight: isAdmin
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.email,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isAdmin
                                          ? Colors.red.shade50
                                          : Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isAdmin ? 'Admin' : 'User',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isAdmin
                                            ? Colors.red.shade700
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            isProcessing
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Switch(
                                    value: isAdmin,
                                    activeColor: Colors.red,
                                    activeTrackColor: Colors.red.shade100,
                                    inactiveThumbColor: Colors.blue,
                                    inactiveTrackColor: Colors.blue.shade100,
                                    onChanged: (value) => _changeUserRole(
                                      user,
                                      value ? UserRole.admin : UserRole.user,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeUserRole(User user, UserRole newRole) async {
    // Hiển thị dialog xác nhận
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi quyền người dùng'),
        content: Text(
          'Bạn có chắc chắn muốn đổi quyền của "${user.name}" từ '
          '${user.role == UserRole.admin ? "admin" : "user"} sang '
          '${newRole == UserRole.admin ? "admin" : "user"}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newRole == UserRole.admin ? Colors.red : Colors.blue,
            ),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
        _processingUserId = user.id;
      });

      try {
        await _updateUserRole(user.id, newRole);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã cập nhật quyền của "${user.name}" thành ${newRole == UserRole.admin ? "admin" : "user thường"}'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _processingUserId = null;
          });
        }
      }
    }
  }
} 