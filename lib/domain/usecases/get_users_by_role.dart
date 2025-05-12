import '../entities/user.dart';
import '../repositories/user_repository.dart';

class GetUsersByRole {
  final UserRepository repository;

  GetUsersByRole(this.repository);

  Stream<List<User>> call(UserRole role) {
    return repository.getUsersByRole(role);
  }
} 