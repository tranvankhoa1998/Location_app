import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_realtime_db_datasource.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRealtimeDBDataSource dataSource;

  UserRepositoryImpl(this.dataSource);

  @override
  Future<User?> getUserById(String uid) async {
    return await dataSource.getUserById(uid);
  }

  @override
  Stream<List<User>> getAllUsers() {
    return dataSource.getAllUsers();
  }

  @override
  Stream<List<User>> getUsersByRole(UserRole role) {
    return dataSource.getUsersByRole(role);
  }

  @override
  Future<void> createUserProfile(String uid, String email, {UserRole role = UserRole.user}) async {
    await dataSource.createUserProfile(uid, email, role: role);
  }

  @override
  Future<void> updateUserRole(String uid, UserRole role) async {
    await dataSource.updateUserRole(uid, role);
  }

  @override
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
  }) async {
    await dataSource.updateUserProfile(
      uid,
      name: name,
      email: email,
      phoneNumber: phoneNumber,
      profession: profession,
      age: age,
      address: address,
      bio: bio,
      avatarUrl: avatarUrl,
    );
  }
} 