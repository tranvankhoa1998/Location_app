import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUserById {
  final UserRepository repository;

  GetUserById(this.repository);

  Future<User?> call(String uid) async {
    return await repository.getUserById(uid);
  }
} 