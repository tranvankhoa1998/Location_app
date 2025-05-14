import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:get_it/get_it.dart';
import '../screens/home_page.dart';
import 'admin/admin_home_screen.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // true = đăng nhập, false = đăng ký
  
  final _auth = auth.FirebaseAuth.instance;
  final _getUserById = GetIt.instance<GetUserById>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm này cố gắng sửa quyền admin cho người dùng nếu cần
  Future<void> _fixAdminRole(String uid, String email) async {
    try {
      // Danh sách email admin mặc định - CHỈ những email này mới có quyền admin
      final adminEmails = [
        'admin@example.com',
        'khoa123123@gmail.com',
        // Thêm email admin thật của bạn vào đây
      ];
      
      if (adminEmails.contains(email.toLowerCase())) {
        // Cập nhật quyền trong database
        final userRepo = GetIt.instance<UserRepository>();
        await userRepo.updateUserRole(uid, UserRole.admin);
      } else {
        // Đảm bảo user có quyền USER (không phải ADMIN)
        final userRepo = GetIt.instance<UserRepository>();
        final user = await _getUserById(uid);
        
        if (user != null && user.role == UserRole.admin) {
          await userRepo.updateUserRole(uid, UserRole.user);
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra/sửa quyền admin: $e');
    }
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập email và mật khẩu')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isLogin) {
        // Đăng nhập
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (userCredential.user != null) {
          // Thử sửa quyền admin
          await _fixAdminRole(userCredential.user!.uid, email);
          
          // Kiểm tra quyền của người dùng
          final user = await _getUserById(userCredential.user!.uid);
          
          if (!mounted) return; // Kiểm tra trước khi sử dụng context
          
          if (user != null && user.role == UserRole.admin) {
            // Nếu là admin, chuyển đến màn hình admin
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const AdminHomeScreen()),
            );
          } else {
            // Nếu là user thường, chuyển đến màn hình home
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          }
        }
      } else {
        // Đăng ký tài khoản thường
        try {
          print('Creating regular user with email: $email');
          final userCredential = await _auth.createUserWithEmailAndPassword(
            email: email,
            password: password,
          );

          if (userCredential.user != null) {
            print('Firebase Auth user created: ${userCredential.user!.uid}');
            // Tạo profile người dùng
            final userRepo = GetIt.instance<UserRepository>();
            try {
              print('Creating user profile in database...');
              await userRepo.createUserProfile(
                userCredential.user!.uid,
                email,
                role: UserRole.user,
              );
              print('User profile created in database');
              
              // Verify creation
              print('Verifying user creation...');
              final createdUser = await _getUserById(userCredential.user!.uid);
              if (createdUser != null) {
                print('User verification successful: ${createdUser.id}, ${createdUser.email}, role: ${createdUser.role}');
              } else {
                print('WARNING: User verification failed! User not found in database after creation.');
              }
              
              if (!mounted) return; // Kiểm tra trước khi sử dụng context
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đăng ký thành công!'),
                  backgroundColor: Colors.green,
                ),
              );
              setState(() {
                _isLogin = true;
              });
            } catch (e) {
              print('Error creating user profile in database: $e');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi tạo hồ sơ người dùng: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } catch (e) {
          print('Error creating Firebase Auth user: $e');
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return; // Kiểm tra trước khi sử dụng context
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) { // Kiểm tra trước khi gọi setState
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập email')),
      );
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi email đặt lại mật khẩu'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Task Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _authenticate,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _isLogin ? 'Đăng nhập' : 'Đăng ký',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Chưa có tài khoản? Đăng ký'
                      : 'Đã có tài khoản? Đăng nhập',
                ),
              ),
              if (_isLogin)
                TextButton(
                  onPressed: _resetPassword,
                  child: const Text('Quên mật khẩu?'),
                ),
            ],
          ),
        ),
      ),
    );
  }
} 