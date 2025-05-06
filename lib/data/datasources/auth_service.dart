import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Lấy User ID hiện tại
  String? get currentUserId => _auth.currentUser?.uid;

  // Đăng ký với email và password
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Lỗi đăng ký: $e');
      rethrow;
    }
  }

  // Đăng nhập với email và password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Lỗi đăng nhập: $e');
      rethrow;
    }
  }

  // Đăng nhập ẩn danh (nếu bạn không muốn yêu cầu người dùng đăng ký)
  Future<UserCredential> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      print('Lỗi đăng nhập ẩn danh: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }
}