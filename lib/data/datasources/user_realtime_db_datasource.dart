import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import '../../domain/entities/user.dart';

class UserRealtimeDBDataSource {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final DatabaseReference _usersRef;

  UserRealtimeDBDataSource() : _usersRef = FirebaseDatabase.instance.ref().child('users');

  Future<void> createUserProfile(String uid, String email, {UserRole role = UserRole.user}) async {
    print('Creating user profile. UID: $uid, Email: $email, Role: $role');
    final roleValue = role == UserRole.admin ? 'admin' : 'user';
    
    try {
      final userData = {
        'name': email.split('@')[0],
        'email': email,
        'role': roleValue,
      };
      
      print('User data to save: $userData');
      await _usersRef.child(uid).set(userData);
      print('User profile created successfully');
      
      // Verify data was written correctly
      final snapshot = await _usersRef.child(uid).get();
      if (snapshot.exists) {
        print('Verification - User data in database: ${snapshot.value}');
      } else {
        print('Verification FAILED - User data was not saved properly');
      }
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<User?> getUserById(String uid) async {
    print('Getting user by ID: $uid');
    
    try {
      final snapshot = await _usersRef.child(uid).get();
      print('Snapshot exists: ${snapshot.exists}, Has value: ${snapshot.value != null}');
      
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('User data from database: $data');
        return User.fromMap(uid, data);
      }
      
      print('User not found in database');
      return null;
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  Stream<List<User>> getAllUsers() {
    print('Setting up stream for getAllUsers');
    
    return _usersRef.onValue.map((event) {
      final snapshot = event.snapshot;
      print('getAllUsers snapshot received - exists: ${snapshot.exists}, hasValue: ${snapshot.value != null}');
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final usersMap = snapshot.value as Map<dynamic, dynamic>;
          print('Users data: $usersMap');
          
          final users = usersMap.entries.map((entry) {
            try {
              print('Processing user: ${entry.key}');
              final userData = Map<String, dynamic>.from(entry.value as Map);
              print('User data: $userData');
              return User.fromMap(entry.key as String, userData);
            } catch (e) {
              print('Lỗi parse user data: $e');
              return null;
            }
          }).whereType<User>().toList();
          
          print('Processed ${users.length} users from database');
          return users;
        } catch (e) {
          print('Lỗi parse dữ liệu users: $e');
          return <User>[];
        }
      }
      
      print('No users found in database');
      return <User>[];
    });
  }

  Stream<List<User>> getUsersByRole(UserRole role) {
    print('Getting users by role: $role');
    
    return getAllUsers().map(
      (users) {
        final filteredUsers = users.where((user) {
          print('Kiểm tra user ${user.id} (${user.email}) - role: ${user.role}, cần role: $role');
          // So sánh enum một cách rõ ràng để tránh lỗi so sánh
          final matches = user.role.toString() == role.toString();
          if (matches) {
            print('✓ User ${user.id} (${user.email}) phù hợp với role $role');
          } else {
            print('✗ User ${user.id} (${user.email}) KHÔNG phù hợp với role $role');
          }
          return matches;
        }).toList();
        
        print('Found ${filteredUsers.length} users with role $role');
        if (filteredUsers.isEmpty) {
          print('WARNING: Không tìm thấy người dùng nào với vai trò $role');
        }
        return filteredUsers;
      },
    );
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    print('Updating role for user $uid to $role');
    
    try {
      final roleValue = role.toString().split('.').last;
      await _usersRef.child(uid).update({
        'role': roleValue,
      });
      print('User role updated successfully');
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(String uid, {String? name, String? email}) async {
    print('Updating profile for user $uid - name: $name, email: $email');
    
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      
      if (updates.isNotEmpty) {
        await _usersRef.child(uid).update(updates);
        print('User profile updated successfully');
      } else {
        print('No updates to apply');
      }
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }
} 