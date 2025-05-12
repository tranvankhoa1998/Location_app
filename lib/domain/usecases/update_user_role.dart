import '../entities/user.dart';
import '../repositories/user_repository.dart';

class UpdateUserRole {
  final UserRepository repository;

  UpdateUserRole(this.repository);

  Future<void> call(String uid, UserRole role) async {
    try {
      await repository.updateUserRole(uid, role);
    } catch (e) {
      throw Exception('Không thể cập nhật quyền người dùng: $e');
    }
  }
} 