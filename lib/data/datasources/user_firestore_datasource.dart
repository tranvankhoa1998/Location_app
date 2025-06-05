import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user.dart';

class UserFirestoreDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final CollectionReference _usersCollection;

  UserFirestoreDataSource() {
    _usersCollection = _firestore.collection('users');
  }

  Future<void> createUserProfile(String uid, String email) async {
    try {
      final userData = {
        'name': email.split('@')[0],
        'email': email,
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      };
      
      await _usersCollection.doc(uid).set(userData);
      
      // Verify data was written correctly
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) {
        throw Exception('User profile was not saved properly');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        return User.fromMap(uid, data);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<List<User>> getAllUsers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return User.fromMap(doc.id, data);
        } catch (e) {
          return null;
        }
      }).whereType<User>().toList();
    });
  }
  Stream<List<User>> getUsersByRole(UserRole role) {
    final roleString = role.toString().split('.').last;
    return _usersCollection
        .where('role', isEqualTo: roleString)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          return User.fromMap(doc.id, data);
        } catch (e) {
          return null;
        }
      }).whereType<User>().toList();
    });
  }

  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      final roleValue = role.toString().split('.').last;
      await _usersCollection.doc(uid).update({
        'role': roleValue,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

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
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updates['name'] = name;
      if (email != null) updates['email'] = email;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profession != null) updates['profession'] = profession;
      if (age != null) updates['age'] = age;
      if (address != null) updates['address'] = address;
      if (bio != null) updates['bio'] = bio;
      if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
      
      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserLocation(String uid, double latitude, double longitude) async {
    try {
      await _usersCollection.doc(uid).update({
        'lastLocation': GeoPoint(latitude, longitude),
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error updating user location: $e');
    }
  }
}
