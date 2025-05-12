import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/entities/user.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({Key? key}) : super(key: key);

  @override
  _AdminProfileScreenState createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final _userRepository = GetIt.instance<UserRepository>();
  final _formKey = GlobalKey<FormState>();
  
  // Các controller cho phần form
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  final _departmentController = TextEditingController();

  // Biến lưu trữ ảnh đại diện
  String? _avatarUrl;
  File? _imageFile;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  // Tải thông tin profile admin từ Firebase
  Future<void> _loadAdminProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Lấy dữ liệu từ Firebase Database
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .get();

      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _departmentController.text = userData['department'] ?? '';
          _avatarUrl = userData['avatarUrl'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    try {
      // Chỉ chọn từ thư viện để đơn giản hóa
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      String errorMessage = 'Không thể lấy ảnh';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Lỗi plugin Image Picker. Vui lòng khởi động lại ứng dụng.';
      }
      _showErrorSnackBar(errorMessage);
    }
  }
  
  // Lấy ảnh từ nguồn đã chọn
  Future<void> _getImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      String errorMessage = 'Không thể lấy ảnh';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage = 'Lỗi plugin Image Picker. Vui lòng khởi động lại ứng dụng.';
      }
      _showErrorSnackBar(errorMessage);
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  // Tải ảnh lên Firebase Storage
  Future<String?> _uploadImage() async {
    if (_imageFile == null) return _avatarUrl;

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return null;

      // Hiển thị dialog loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Đang tải ảnh lên..."),
                ],
              ),
            ),
          );
        },
      );

      // Tạo đường dẫn lưu trữ ảnh
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('${currentUser.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Tải ảnh lên
      await storageRef.putFile(_imageFile!);
      final downloadUrl = await storageRef.getDownloadURL();
      
      // Đóng dialog loading
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return downloadUrl;
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      _showErrorSnackBar('Lỗi khi tải ảnh lên: $e');
      return null;
    }
  }

  // Lưu thông tin profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Không tìm thấy thông tin người dùng');
      }

      // Tải ảnh lên nếu có
      final avatarUrl = await _uploadImage();

      // Chuẩn bị dữ liệu để cập nhật
      final userData = {
        'name': _nameController.text.trim(),
        'email': currentUser.email,
        'role': 'admin', // Đảm bảo quyền admin được giữ nguyên
        'phone': _phoneController.text.trim(),
        'age': _ageController.text.isNotEmpty 
            ? int.tryParse(_ageController.text.trim()) 
            : null,
        'department': _departmentController.text.trim(),
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };

      // Cập nhật trên Firebase Database
      await FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .update(userData);

      // Cập nhật profile thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật thông tin thành công')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật thông tin: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Lưu thông tin',
            onPressed: _isSaving ? null : _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Ảnh đại diện
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_avatarUrl != null && _avatarUrl!.isNotEmpty)
                                    ? NetworkImage(_avatarUrl!)
                                    : null,
                            child: (_avatarUrl == null || _avatarUrl!.isEmpty) && _imageFile == null
                                ? const Icon(Icons.person, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    builder: (context) => SafeArea(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ListTile(
                                            leading: const Icon(Icons.photo_library),
                                            title: const Text('Chọn từ thư viện'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _getImage(ImageSource.gallery);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(Icons.camera_alt),
                                            title: const Text('Chụp ảnh mới'),
                                            onTap: () {
                                              Navigator.of(context).pop();
                                              _getImage(ImageSource.camera);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.verified_user, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Admin',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Form thông tin
                    const Text(
                      'Thông tin cá nhân',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Họ và tên
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Họ và tên',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập họ tên';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Số điện thoại
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    
                    // Tuổi
                    TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Tuổi',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    
                    // Phòng ban
                    TextFormField(
                      controller: _departmentController,
                      decoration: const InputDecoration(
                        labelText: 'Phòng ban',
                        prefixIcon: Icon(Icons.business),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Nút lưu thông tin
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text(
                          'Lưu thông tin',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 