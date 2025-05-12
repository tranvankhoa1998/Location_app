import '../entities/user.dart';
import '../repositories/user_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class CreateAdminUser {
  final UserRepository repository;
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  CreateAdminUser(this.repository);

  Future<void> call({
    required String email,
    required String password,
  }) async {
    try {
      // Tạo tài khoản với Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Tạo profile admin trong Realtime Database
        await repository.createUserProfile(
          userCredential.user!.uid,
          email,
          role: UserRole.admin,
        );
      }
    } catch (e) {
      throw Exception('Không thể tạo tài khoản admin: $e');
    }
  }
} 