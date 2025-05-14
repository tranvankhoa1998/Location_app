import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/user.dart';

class UserRealtimeDBDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _usersRef;

  UserRealtimeDBDataSource() {
    _usersRef = _database.ref().child('users');
  }

  Future<void> createUserProfile(String uid, String email, {UserRole role = UserRole.user}) async {
    final roleValue = role == UserRole.admin ? 'admin' : 'user';
    
    try {
      final userData = {
        'name': email.split('@')[0],
        'email': email,
        'role': roleValue,
      };
      
      await _usersRef.child(uid).set(userData);
      
      // Verify data was written correctly
      final snapshot = await _usersRef.child(uid).get();
      if (!snapshot.exists) {
        throw Exception('User profile was not saved properly');
      }
    } catch (e) {
      throw Exception('Error creating user profile: $e');
    }
  }

  Future<User?> getUserById(String uid) async {
    try {
      final snapshot = await _usersRef.child(uid).get();
      
      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        return User.fromMap(uid, data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<User>> getAllUsers() {
    return _usersRef.onValue.map((event) {
      final snapshot = event.snapshot;
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final usersMap = snapshot.value as Map<dynamic, dynamic>;
          
          final users = usersMap.entries.map((entry) {
            try {
              final userData = Map<String, dynamic>.from(entry.value as Map);
              return User.fromMap(entry.key as String, userData);
            } catch (e) {
              return null;
            }
          }).whereType<User>().toList();
          
          return users;
        } catch (e) {
          return <User>[];
        }
      }
      
      return <User>[];
    });
  }

  Stream<List<User>> getUsersByRole(UserRole role) {
    return getAllUsers().map(
      (users) {
        final filteredUsers = users.where((user) {
          // So sánh enum một cách rõ ràng để tránh lỗi so sánh
          final matches = user.role.toString() == role.toString();
          return matches;
        }).toList();
        
        return filteredUsers;
      },
    );
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      final roleValue = role.toString().split('.').last;
      await _usersRef.child(uid).update({
        'role': roleValue,
      });
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  Future<void> updateUserProfile(String uid, {String? name, String? email}) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      
      if (updates.isNotEmpty) {
        await _usersRef.child(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Error updating user profile: $e');
    }
  }
} 