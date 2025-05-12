import 'package:firebase_database/firebase_database.dart';
import 'location.dart';

enum UserRole {
  admin,
  user,
}

class User {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final Location? location;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.location,
  });

  factory User.fromMap(String id, Map<String, dynamic> data) {
    print('User.fromMap raw data for $id: $data'); // Debug log
    
    try {
      // Xác định quyền từ chuỗi
      UserRole userRole = UserRole.user; // Mặc định là user
      
      // Lấy giá trị role từ dữ liệu, chuyển sang chữ thường và trim
      String roleStr = '';
      if (data['role'] != null) {
        roleStr = data['role'].toString().toLowerCase().trim();
        print('Role string from database: "$roleStr"');
      } else {
        print('WARNING: Role không tồn tại trong dữ liệu user $id, sử dụng mặc định "user"');
      }
      
      // Chỉ đặt là admin nếu role chính xác là "admin"
      if (roleStr == 'admin') {
        userRole = UserRole.admin;
        print('User $id được xác định là ADMIN');
      } else {
        print('User $id được xác định là USER thường');
      }
      
      // Handle optional location data
      Location? userLocation;
      if (data['lastLocation'] != null) {
        try {
          userLocation = Location.fromMap(Map<String, dynamic>.from(data['lastLocation'] as Map));
          print('Location data parsed successfully');
        } catch (e) {
          print('Error parsing location data: $e');
          // Continue without location data
        }
      }
      
      final user = User(
        id: id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: userRole,
        location: userLocation,
      );
      
      print('User parsed successfully: ${user.id} (${user.name}, ${user.email}, role: ${user.role})');
      return user;
    } catch (e) {
      print('Error parsing user data: $e');
      // Return a minimal valid user to avoid null issues
      return User(
        id: id,
        name: data['name'] ?? 'Unknown',
        email: data['email'] ?? 'unknown@example.com',
        role: UserRole.user,
        location: null,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      if (location != null) 'lastLocation': location!.toMap(),
    };
  }
} 