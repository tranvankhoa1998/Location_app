import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/task_model.dart';

class TaskRealtimeDBDataSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _userTasksRef;

  TaskRealtimeDBDataSource() {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }
    
    // Sửa lại đường dẫn để khớp với cấu trúc JSON
    _userTasksRef = _database.ref().child('tasks').child(userId);
    
    // Thử ghi test
    _userTasksRef.child('task_id_3').set({
      'task': 'Cập nhật website',
      'description': 'Cập nhật các tính năng mới cho website',
      'date': 1715802000000,
      'number': 3
   }).timeout(Duration(seconds: 10));
  }
  

  Stream<List<TaskModel>> getTasks() {
    return _userTasksRef.onValue.map((event) {
      final snapshot = event.snapshot;
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final tasksMap = snapshot.value as Map<dynamic, dynamic>;
          
          final tasks = tasksMap.entries.map((entry) {
            // Bỏ qua test entry
            if (entry.key == 'test') return null;
            
            try {
              final taskData = Map<String, dynamic>.from(entry.value as Map);
              
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
              return null;
            }
          }).whereType<TaskModel>().toList(); // Lọc các giá trị null
          
          // Sắp xếp task theo số (tăng dần)
          tasks.sort((a, b) => a.number.compareTo(b.number));
          return tasks;
        } catch (e) {
          return <TaskModel>[];
        }
      }
      
      return <TaskModel>[];
    }).handleError((error) {
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
          // Xử lý lỗi mà không cần print
        }
      }
      
      final newTaskRef = _userTasksRef.push();
      final taskId = newTaskRef.key!;
      
      await newTaskRef.set({
        'task': title,
        'date': date.millisecondsSinceEpoch,
        'description': description,
        'number': currentNumber,
      });
      
      return taskId;
    } catch (e) {
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
      
      await _userTasksRef.child(id).update(updates);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _userTasksRef.child(id).remove();
    } catch (e) {
      rethrow;
    }
  }
}