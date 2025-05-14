import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserById {
  final UserRepository repository;

  GetUserById(this.repository);

  Future<User?> call(String uid) async {
    try {
      final result = await repository.getUserById(uid);
      return result;
    } catch (e) {
      print('Lỗi khi lấy thông tin user: $e');
      return null;
    }
  }
} 