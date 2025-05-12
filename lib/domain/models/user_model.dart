import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  user,
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final GeoPoint? lastLocation;
  final DateTime? lastLocationUpdate;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.lastLocation,
    this.lastLocationUpdate,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${data['role']}',
        orElse: () => UserRole.user,
      ),
      lastLocation: data['lastLocation'],
      lastLocationUpdate: data['lastLocationUpdate']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'lastLocation': lastLocation,
      'lastLocationUpdate': lastLocationUpdate,
    };
  }
} 