import 'package:flutter/material.dart';
import '../../fixes/check_permissions.dart';
import 'dart:async';

class RoleCheckScreen extends StatefulWidget {
  const RoleCheckScreen({Key? key}) : super(key: key);

  @override
  _RoleCheckScreenState createState() => _RoleCheckScreenState();
}

class _RoleCheckScreenState extends State<RoleCheckScreen> {
  bool _isLoading = false;
  String _resultText = '';
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kiểm tra quyền'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Công cụ này giúp kiểm tra và sửa quyền cho tài khoản hiện tại. '
                  'Dùng nếu bạn gặp vấn đề với quyền admin.',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _checkPermissions,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('KIỂM TRA QUYỀN HIỆN TẠI'),
            ),
            
            const SizedBox(height: 12),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _forceSetAdmin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('ĐẶT LÀM ADMIN (CHỈ DÙNG KHI CẦN)'),
            ),
            
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
              
            if (_resultText.isNotEmpty)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kết quả kiểm tra:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(_resultText),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
      _resultText = 'Đang kiểm tra quyền...';
    });
    
    try {
      StringBuffer log = StringBuffer();
      
      // Bắt đầu ra bằng cách sử dụng runZoned
      await runZoned(() async {
        await checkCurrentUserPermissions();
      }, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          log.writeln(line);
          parent.print(zone, line);
        }
      ));
      
      setState(() {
        _resultText = log.toString();
      });
    } catch (e) {
      setState(() {
        _resultText = 'Lỗi khi kiểm tra quyền: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _forceSetAdmin() async {
    // Hiển thị hộp thoại xác nhận
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text(
          'Bạn có chắc chắn muốn đặt tài khoản hiện tại là ADMIN?\n\n'
          'CHỈ sử dụng khi bạn chắc chắn tài khoản này phải có quyền admin.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('XÁC NHẬN'),
          ),
        ],
      ),
    ) ?? false;
    
    if (!confirm) return;
    
    setState(() {
      _isLoading = true;
      _resultText = 'Đang thiết lập quyền admin...';
    });
    
    try {
      StringBuffer log = StringBuffer();
      
      // Bắt đầu ra bằng cách sử dụng runZoned
      await runZoned(() async {
        await forceSetCurrentUserAsAdmin();
      }, zoneSpecification: ZoneSpecification(
        print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
          log.writeln(line);
          parent.print(zone, line);
        }
      ));
      
      setState(() {
        _resultText = log.toString();
      });
    } catch (e) {
      setState(() {
        _resultText = 'Lỗi khi thiết lập quyền admin: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
} 