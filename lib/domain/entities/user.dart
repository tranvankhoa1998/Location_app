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
  final String? phoneNumber;
  final String? profession;
  final int? age;
  final String? address;
  final String? bio;
  final String? avatarUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.location,
    this.phoneNumber,
    this.profession,
    this.age,
    this.address,
    this.bio,
    this.avatarUrl,
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
        phoneNumber: data['phoneNumber'],
        profession: data['profession'],
        age: data['age'] is int ? data['age'] : (data['age'] != null ? int.tryParse(data['age'].toString()) : null),
        address: data['address'],
        bio: data['bio'],
        avatarUrl: data['avatarUrl'],
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
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (profession != null) 'profession': profession,
      if (age != null) 'age': age,
      if (address != null) 'address': address,
      if (bio != null) 'bio': bio,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
} 