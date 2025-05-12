import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

// Gọi hàm này sau khi đăng nhập để cập nhật thông tin admin
Future<void> fixAdminRoleForUser(String uid) async {
  try {
    final userRef = FirebaseDatabase.instance.ref().child('users').child(uid);
    
    // Đọc thông tin người dùng hiện tại
    final snapshot = await userRef.get();
    if (snapshot.exists) {
      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      
      print('Thông tin người dùng trong database:');
      print(userData);
      
      // Kiểm tra nếu role đã là admin
      final currentRole = userData['role']?.toString().toLowerCase();
      if (currentRole == 'admin') {
        print('Đã xác định người dùng là ADMIN. Không cần sửa.');
        return;
      }
    }
    
    print('Không tìm thấy thông tin người dùng hoặc không phải admin. Tiến hành kiểm tra email...');
    
    // Kiểm tra nếu email là một trong các email admin đã biết
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final email = user.email?.toLowerCase();
      
      // Thêm các email admin vào đây
      final adminEmails = [
        'admin@example.com', 
        // Thêm email của bạn vào đây
      ];
      
      if (adminEmails.contains(email)) {
        print('Email $email được xác định là admin. Cập nhật quyền...');
        
        // Cập nhật quyền trong database
        await userRef.update({
          'role': 'admin'
        });
        
        print('Đã cập nhật thành công. Người dùng giờ có quyền ADMIN.');
      }
    }
  } catch (e) {
    print('Lỗi khi sửa quyền admin: $e');
  }
} 