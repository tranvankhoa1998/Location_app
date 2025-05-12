import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_list_screen.dart';
import 'user_role_management_screen.dart';
import 'overall_map_screen.dart';
import '../../../domain/usecases/get_users_by_role.dart';
import '../login_screen.dart';
import 'user_distance_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_profile_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý hệ thống'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Thông tin cá nhân',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AdminProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Đăng xuất'),
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
              ) ?? false;

              if (confirm && context.mounted) {
                await FirebaseAuth.instance.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminProfileScreen(),
                      ),
                    );
                  },
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance
                            .ref()
                            .child('users')
                            .child(currentUser?.uid ?? '')
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                            final userData = Map<String, dynamic>.from(
                              snapshot.data!.snapshot.value as Map);
                            
                            // Lấy avatar từ dữ liệu
                            final String? avatarUrl = userData['avatarUrl'];
                            final String name = userData['name'] ?? 'Quản trị viên';
                            
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue.shade100,
                                border: Border.all(
                                  color: Colors.blue.shade200,
                                  width: 2,
                                ),
                                image: avatarUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(avatarUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: avatarUrl == null
                                  ? Icon(
                                      Icons.admin_panel_settings,
                                      size: 30,
                                      color: Colors.blue,
                                    )
                                  : null,
                            );
                          } else {
                            return Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.blue,
                              ),
                              child: const Icon(
                                Icons.admin_panel_settings,
                                color: Colors.white,
                                size: 30,
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue.shade50, width: 2),
                        ),
                        child: Icon(Icons.edit, color: Colors.blue, size: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instance
                            .ref()
                            .child('users')
                            .child(currentUser?.uid ?? '')
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                            final userData = Map<String, dynamic>.from(
                              snapshot.data!.snapshot.value as Map);
                            
                            final String name = userData['name'] ?? 'Quản trị viên';
                            final String department = userData['department'] ?? '';
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                if (department.isNotEmpty)
                                  Text(
                                    department,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                const Text(
                                  'admin',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quản trị viên',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'admin',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  tooltip: 'Cập nhật thông tin',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.all(16),
              childAspectRatio: 1.1,
              children: [
                _buildFeatureCard(
                  context,
                  Icons.people,
                  'Quản lý người dùng',
                  'Xem vị trí và thông tin người dùng',
                  Colors.blue,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserListScreen(
                          getUsersByRole: GetIt.instance<GetUsersByRole>(),
                        ),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  Icons.admin_panel_settings,
                  'Phân quyền',
                  'Cấp quyền admin cho người dùng',
                  Colors.orange,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserRoleManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  Icons.map,
                  'Bản đồ tổng quan',
                  'Theo dõi vị trí người dùng',
                  Colors.green,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OverallMapScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  Icons.calculate,
                  'Tính khoảng cách',
                  'Xem khoảng cách tới người dùng',
                  Colors.red,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const UserDistanceScreen(),
                      ),
                    );
                  },
                ),
                _buildFeatureCard(
                  context,
                  Icons.settings,
                  'Cài đặt hệ thống',
                  'Cấu hình và tùy chỉnh',
                  Colors.purple,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              radius: 30,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
} 