import '../entities/user.dart';

abstract class UserRepository {
  Future<User?> getUserById(String uid);
  Stream<List<User>> getAllUsers();
  Stream<List<User>> getUsersByRole(UserRole role);
  Future<void> createUserProfile(String uid, String email);
  Future<void> updateUserProfile(
    String uid, {
    String? name,
    String? email,
    String? phoneNumber,
    String? profession,
    int? age,
    String? address,
    String? bio,
    String? avatarUrl,
  });
}