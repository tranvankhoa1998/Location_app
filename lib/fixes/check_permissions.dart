import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'admin_role_fix.dart'; // Import để sử dụng danh sách adminEmails

// Gọi hàm này để kiểm tra quyền của người dùng hiện tại
Future<void> checkCurrentUserPermissions() async {
  try {
    final auth = FirebaseAuth.instance;
    final database = FirebaseDatabase.instance;
    
    // 1. Kiểm tra Firebase Auth
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('ERROR: Không có người dùng nào đang đăng nhập!');
      return;
    }
    
    print('=========== KIỂM TRA QUYỀN ===========');
    print('User đang đăng nhập:');
    print('- UID: ${currentUser.uid}');
    print('- Email: ${currentUser.email}');
    
    // Kiểm tra nếu email nằm trong danh sách admin
    final isInAdminList = adminEmails.contains(currentUser.email?.toLowerCase());
    print('- Email có trong danh sách admin? ${isInAdminList ? "CÓ" : "KHÔNG"}');
    
    // 2. Kiểm tra dữ liệu trong Realtime Database
    print('\nĐang kiểm tra trong Realtime Database...');
    
    // Kiểm tra node users/$uid
    final userRef = database.ref().child('users').child(currentUser.uid);
    final userSnapshot = await userRef.get();
    
    if (!userSnapshot.exists) {
      print('ERROR: Không tìm thấy dữ liệu người dùng trong database!');
      return;
    }
    
    // In ra dữ liệu người dùng
    final userData = Map<String, dynamic>.from(userSnapshot.value as Map);
    print('Dữ liệu người dùng:');
    userData.forEach((key, value) {
      print('- $key: $value');
    });
    
    // Kiểm tra quyền
    final role = userData['role']?.toString().toLowerCase();
    print('\nQuyền của người dùng: $role');
    
    if (role == 'admin') {
      print('✅ Người dùng có quyền ADMIN');
    } else {
      print('❌ Người dùng KHÔNG có quyền admin');
      
      if (isInAdminList) {
        print('⚠️ LỖI: Email nằm trong danh sách admin nhưng quyền không phải admin!');
        print('   Hãy sử dụng nút "ĐẶT LÀM ADMIN" để khắc phục.');
      }
    }
    
    // 3. Kiểm tra quy tắc bảo mật
    print('\nKiểm tra quyền truy cập:');
    try {
      // Thử truy cập danh sách users (chỉ admin mới có quyền đọc toàn bộ)
      final usersRef = database.ref().child('users');
      final usersSnapshot = await usersRef.get();
      if (usersSnapshot.exists) {
        print('✅ Có thể đọc danh sách tất cả người dùng - Có quyền ADMIN');
      } else {
        print('❓ Không có dữ liệu người dùng nào');
      }
    } catch (e) {
      print('❌ KHÔNG thể đọc danh sách tất cả người dùng - Không có quyền admin');
      print('   Lỗi: $e');
    }
    
    print('====================================');
    
  } catch (e) {
    print('Lỗi khi kiểm tra quyền: $e');
  }
}

// Thêm hàm này để sửa trường role của tài khoản hiện tại thành admin
Future<void> forceSetCurrentUserAsAdmin() async {
  try {
    final auth = FirebaseAuth.instance;
    final database = FirebaseDatabase.instance;
    
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print('ERROR: Không có người dùng nào đang đăng nhập!');
      return;
    }
    
    print('Đang thiết lập quyền ADMIN cho người dùng:');
    print('- UID: ${currentUser.uid}');
    print('- Email: ${currentUser.email}');
    
    // Cập nhật quyền trong database
    final userRef = database.ref().child('users').child(currentUser.uid);
    await userRef.update({
      'role': 'admin'
    });
    
    print('✅ Đã cập nhật quyền ADMIN thành công!');
    
    // Kiểm tra lại
    final updatedSnapshot = await userRef.get();
    if (updatedSnapshot.exists) {
      final updatedData = Map<String, dynamic>.from(updatedSnapshot.value as Map);
      print('Dữ liệu người dùng sau khi cập nhật:');
      print(updatedData);
      
      // Thêm email vào danh sách admin nếu chưa có
      final email = currentUser.email?.toLowerCase();
      if (email != null && !adminEmails.contains(email)) {
        print('\n⚠️ LƯU Ý: Email này chưa được thêm vào danh sách adminEmails trong mã nguồn!');
        print('Hãy thêm email này vào danh sách trong các file:');
        print('- lib/fixes/admin_role_fix.dart');
        print('- lib/presentation/screens/login_screen.dart');
      }
    }
    
  } catch (e) {
    print('❌ Lỗi khi thiết lập quyền admin: $e');
  }
} 