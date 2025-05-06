import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class TaskRealtimeDBDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _userTasksRef;

  TaskRealtimeDBDataSource() {
    final userId = _auth.currentUser?.uid;
    print('DEBUG: User ID: $userId');
    print('DEBUG: Database URL: ${FirebaseDatabase.instance.databaseURL}');
    
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    // Sửa lại đường dẫn để khớp với cấu trúc JSON
    _userTasksRef = _database.ref().child('tasks').child(userId);
    print('DEBUG: Đường dẫn database: ${_userTasksRef.path}');
    print('DEBUG: User ID: ${_auth.currentUser?.uid}');
    
    // Thử ghi test
    _userTasksRef.child('task_id_3').set({
      'task': 'Cập nhật website',
      'description': 'Cập nhật các tính năng mới cho website',
      'date': 1715802000000,
      'number': 3
   }).timeout(Duration(seconds: 10))
.then((_) {
  print('Test write thành công!');
}).catchError((error) {
  print('Test write ERROR: $error');
});
  }
  

  Stream<List<TaskModel>> getTasks() {
    print('DEBUG: Bắt đầu lắng nghe từ: ${_userTasksRef.path}');
    print('DEBUG: User ID: ${_auth.currentUser?.uid}');
    
    return _userTasksRef.onValue.map((event) {
      final snapshot = event.snapshot;
      print('DEBUG: Nhận event từ Firebase, snapshot exists: ${snapshot.exists}');
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final tasksMap = snapshot.value as Map<dynamic, dynamic>;
          print('DEBUG: Số task nhận được: ${tasksMap.length}');
          
          final tasks = tasksMap.entries.map((entry) {
            // Bỏ qua test entry
            if (entry.key == 'test') return null;
            
            try {
              final taskData = Map<String, dynamic>.from(entry.value as Map);
              print('DEBUG: Task ID: ${entry.key}, Task: ${taskData['task']}');
              
              // Chuyển timestamp thành DateTime
              DateTime taskDate;
              if (taskData['date'] is int) {
                taskDate = DateTime.fromMillisecondsSinceEpoch(taskData['date'] as int);
              } else {
                taskDate = DateTime.now();
              }
              
              return TaskModel(
                id: entry.key as String,
                task: taskData['task'] ?? '',
                number: taskData['number'] ?? 0,
                date: taskDate,
                description: taskData['description'],
              );
            } catch (e) {
              print('Lỗi parse task data: $e');
              return null;
            }
          }).whereType<TaskModel>().toList(); // Lọc các giá trị null
          
          // Sắp xếp task theo số (tăng dần)
          tasks.sort((a, b) => a.number.compareTo(b.number));
          return tasks;
        } catch (e) {
          print('Lỗi parse dữ liệu: $e');
          return <TaskModel>[];
        }
      }
      
      print('DEBUG: Snapshot không tồn tại hoặc null');
      return <TaskModel>[];
    }).handleError((error) {
      print('ERROR trong stream getTasks: $error');
      return <TaskModel>[];
    });
  }

  Future<String> addTask({
    required String title,
    required DateTime date,
    String? description,
    int number = 0,
  }) async {
    try {
      // Lấy số task hiện tại để tính toán số thứ tự mới
      final snapshot = await _userTasksRef.get();
      int currentNumber = 1; // Mặc định là 1 nếu không có task nào
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final tasksMap = snapshot.value as Map<dynamic, dynamic>;
          // Đếm chỉ những task thực sự (bỏ qua test)
          currentNumber = tasksMap.entries
              .where((e) => e.key != 'test')
              .length + 1;
        } catch (e) {
          print('Lỗi lấy số task: $e');
        }
      }
      
      final newTaskRef = _userTasksRef.push();
      final taskId = newTaskRef.key!;
      
      print('Đang thêm task với ID: $taskId, path: ${newTaskRef.path}');
      
      await newTaskRef.set({
        'task': title,
        'date': date.millisecondsSinceEpoch,
        'description': description,
        'number': currentNumber,
      });
      
      print('Task thêm thành công!');
      return taskId;
    } catch (e) {
      print('LỖI KHI THÊM TASK: $e');
      rethrow;
    }
  }

  Future<void> updateTask({
    required String id,
    String? title,
    DateTime? date,
    String? description,
    int? number,
  }) async {
    try {
      final updates = <String, dynamic>{};
      
      if (title != null) updates['task'] = title;
      if (description != null) updates['description'] = description;
      if (number != null) updates['number'] = number;
      
      if (date != null) {
        updates['date'] = date.millisecondsSinceEpoch;
      }
      
      print('Đang cập nhật task $id với: $updates');
      await _userTasksRef.child(id).update(updates);
      print('Task cập nhật thành công');
    } catch (e) {
      print('Lỗi cập nhật task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      print('Đang xóa task: $id');
      await _userTasksRef.child(id).remove();
      print('Task xóa thành công');
    } catch (e) {
      print('Lỗi xóa task: $e');
      rethrow;
    }
  }
}