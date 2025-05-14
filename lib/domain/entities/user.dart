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
    try {
      // Xác định quyền từ chuỗi
      UserRole userRole = UserRole.user; // Mặc định là user
      
      // Lấy giá trị role từ dữ liệu, chuyển sang chữ thường và trim
      String roleStr = '';
      if (data['role'] != null) {
        roleStr = data['role'].toString().toLowerCase().trim();
      }
      
      // Chỉ đặt là admin nếu role chính xác là "admin"
      if (roleStr == 'admin') {
        userRole = UserRole.admin;
      }
      
      // Handle optional location data
      Location? userLocation;
      if (data['lastLocation'] != null) {
        try {
          userLocation = Location.fromMap(Map<String, dynamic>.from(data['lastLocation'] as Map));
        } catch (e) {
          // Continue without location data
        }
      }
      
      return User(
        id: id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: userRole,
        location: userLocation,
      );
    } catch (e) {
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