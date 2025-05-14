import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../domain/entities/task.dart';

class TaskRealtimeDBDataSource {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  late final DatabaseReference _userTasksRef;

  TaskRealtimeDBDataSource() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    
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

  // Lấy danh sách task của người dùng hiện tại
  Stream<List<Task>> getTasks(String userId) {
    final ref = _database.ref().child('tasks').child(userId);
    
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      
      if (snapshot.exists && snapshot.value != null) {
        try {
          final Map<dynamic, dynamic> tasksMap = snapshot.value as Map<dynamic, dynamic>;
          
          // Chuyển đổi từ Map<dynamic, dynamic> sang List<Task>
          final tasks = tasksMap.entries.map((entry) {
            try {
              // Chuyển đổi từ Map<dynamic, dynamic> sang Map<String, dynamic>
              final Map<String, dynamic> taskData = {};
              (entry.value as Map<dynamic, dynamic>).forEach((key, value) {
                taskData[key.toString()] = value;
              });
              
              return Task.fromMap(entry.key.toString(), taskData);
            } catch (e) {
              // Bỏ qua nếu có lỗi parse
              return null;
            }
          }).whereType<Task>().toList();
          
          // Sắp xếp theo thời gian tạo (mới nhất lên đầu)
          tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return tasks;
        } catch (e) {
          return <Task>[];
        }
      }
      return <Task>[];
    });
  }

  // Thêm task mới
  Future<String> addTask(Task task, String userId) async {
    final ref = _database.ref().child('tasks').child(userId);
    
    try {
      final newTaskRef = ref.push();
      final String taskId = newTaskRef.key!;
      
      await newTaskRef.set(task.toMap());
      
      return taskId;
    } catch (e) {
      throw Exception('Không thể thêm task: $e');
    }
  }

  // Cập nhật task
  Future<void> updateTask(String id, Task task, String userId) async {
    final ref = _database.ref().child('tasks').child(userId).child(id);
    
    try {
      await ref.update(task.toMap());
    } catch (e) {
      throw Exception('Không thể cập nhật task: $e');
    }
  }

  // Xóa task
  Future<void> deleteTask(String id, String userId) async {
    final ref = _database.ref().child('tasks').child(userId).child(id);
    
    try {
      await ref.remove();
    } catch (e) {
      throw Exception('Không thể xóa task: $e');
    }
  }

  // Lấy task theo ID
  Future<Task?> getTaskById(String id, String userId) async {
    final ref = _database.ref().child('tasks').child(userId).child(id);
    
    try {
      final snapshot = await ref.get();
      
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> taskData = snapshot.value as Map<dynamic, dynamic>;
        
        // Chuyển đổi từ Map<dynamic, dynamic> sang Map<String, dynamic>
        final Map<String, dynamic> convertedData = {};
        taskData.forEach((key, value) {
          convertedData[key.toString()] = value;
        });
        
        return Task.fromMap(id, convertedData);
      }
      
      return null;
    } catch (e) {
      throw Exception('Không thể lấy task: $e');
    }
  }
} 