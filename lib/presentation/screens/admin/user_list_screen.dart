import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/user.dart';
import '../../../domain/usecases/get_users_by_role.dart';
import 'user_location_screen.dart';

class UserListScreen extends StatefulWidget {
  final GetUsersByRole getUsersByRole;

  const UserListScreen({
    Key? key,
    required this.getUsersByRole,
  }) : super(key: key);

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _isRefreshing = false;
  
  void _refreshData() {
    if (mounted) {
      setState(() {
        _isRefreshing = true;
      });
    
      // Force rebuild of the StreamBuilder by changing state
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đang làm mới dữ liệu...'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách người dùng'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới',
            onPressed: _refreshData,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông tin người dùng',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isRefreshing
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : StreamBuilder<List<User>>(
                    // Key based on timestamp to force rebuild when refreshing
                    key: ValueKey(DateTime.now().toString()),
                    stream: widget.getUsersByRole(UserRole.user),
                    builder: (context, snapshot) {
                      // Print debug info
                      print('StreamBuilder state: ${snapshot.connectionState}');
                      print('Has error: ${snapshot.hasError}');
                      if (snapshot.hasError) {
                        print('Error: ${snapshot.error}');
                      }
                      print('Has data: ${snapshot.hasData}');
                      if (snapshot.hasData) {
                        print('Data length: ${snapshot.data?.length}');
                        if (snapshot.data != null) {
                          for (var user in snapshot.data!) {
                            print('User in list: ${user.id} (${user.name}, ${user.email})');
                          }
                        }
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                              const SizedBox(height: 16),
                              Text('Có lỗi xảy ra: ${snapshot.error}'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshData,
                                child: const Text('Thử lại'),
                              ),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Đang tải dữ liệu...'),
                            ],
                          ),
                        );
                      }

                      final users = snapshot.data ?? [];
                      
                      if (users.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('Không có người dùng thường nào'),
                              const SizedBox(height: 8),
                              const Text(
                                'Admin không được hiển thị trong danh sách này',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshData,
                                child: const Text('Làm mới danh sách'),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        itemCount: users.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final user = users[index];
                          final hasLocation = user.location != null;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserLocationScreen(user: user),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: hasLocation ? Colors.green.shade100 : Colors.grey.shade200,
                                      radius: 28,
                                      child: Icon(
                                        hasLocation ? Icons.location_on : Icons.location_off,
                                        color: hasLocation ? Colors.green : Colors.grey,
                                        size: 28,
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
                                          const SizedBox(height: 4),
                                          Text(
                                            hasLocation ? "Đã cập nhật vị trí" : "Chưa cập nhật vị trí",
                                            style: TextStyle(
                                              color: hasLocation ? Colors.green.shade700 : Colors.grey.shade700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time,
                                                size: 14,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                hasLocation
                                                    ? 'Cập nhật: ${_formatDateTime(user.location!.timestamp)}'
                                                    : 'Chưa cập nhật vị trí',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.person_outline,
                                                size: 12,
                                                color: Colors.blue.shade400,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Người dùng thường',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.blue.shade400,
                                                ),
                                              ),
                                              const Spacer(),
                                              Text(
                                                'ID: ${user.id.substring(0, 6)}...',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey.shade400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.info_outline),
                                      tooltip: 'Xem chi tiết',
                                      onPressed: () {
                                        _showUserDetailsDialog(context, user);
                                      },
                                    ),
                                  ],
                                ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Go to map overview
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Chuyển đến bản đồ tổng quan để theo dõi tất cả người dùng'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        tooltip: 'Xem bản đồ tổng quan',
        child: const Icon(Icons.map),
      ),
    );
  }

  // Hiển thị dialog thông tin chi tiết người dùng
  void _showUserDetailsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông tin chi tiết'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Tên', user.name),
            const Divider(),
            // Hiển thị phần đầu email và ẩn đi phần còn lại
            _buildDetailRow('Email', '${user.email.split('@').first}***@***'),
            const Divider(),
            _buildDetailRow('Vai trò', 'Người dùng'),
            const Divider(),
            _buildDetailRow(
              'Trạng thái vị trí', 
              user.location != null 
                  ? 'Đã cập nhật lúc: ${_formatDateTime(user.location!.timestamp)}' 
                  : 'Chưa cập nhật'
            ),
            if (user.location != null) ...[
              const Divider(),
              _buildDetailRow(
                'Tọa độ', 
                '${user.location!.latitude.toStringAsFixed(6)}, ${user.location!.longitude.toStringAsFixed(6)}'
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserLocationScreen(user: user),
                ),
              );
            },
            child: const Text('Xem vị trí trên bản đồ'),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị một hàng thông tin
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime time) {
    return '${time.hour}:${time.minute.toString().padLeft(2, '0')}, ${time.day}/${time.month}/${time.year}';
  }
} 