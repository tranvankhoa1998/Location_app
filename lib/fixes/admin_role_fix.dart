import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Danh sách email admin - PHẢI ĐỒng bộ với danh sách trong login_screen.dart
final adminEmails = [
  'admin@example.com',
  'khoa123123@gmail.com',
  // Thêm email admin thật của bạn vào đây
];

// Gọi hàm này sau khi đăng nhập để cập nhật thông tin admin
Future<void> fixAdminRoleForUser(String uid) async {
  try {
    final userRef = FirebaseDatabase.instance.ref().child('users').child(uid);
    
    // Đọc thông tin người dùng hiện tại
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      
      // Kiểm tra nếu role đã là admin
      final currentRole = userData['role']?.toString().toLowerCase();
      if (currentRole == 'admin') {
        return; // Đã là admin, không cần sửa
      }
    }
    
    // Kiểm tra nếu email là một trong các email admin đã biết
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email?.toLowerCase();
      
      if (adminEmails.contains(email)) {
        // Cập nhật quyền trong database
        await userRef.update({
          'role': 'admin'
        });
      }
    }
  } catch (e) {
    print('Lỗi khi sửa quyền admin: $e');
  }
} 