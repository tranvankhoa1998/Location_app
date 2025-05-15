import '../entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> getTasks();
  Future<String> addTask(Task task);
  Future<void> updateTask({
    required String id,
    String? title,
    DateTime? date,
    String? description,
    int? number,
    Map<String, dynamic>? metadata,
  });
  Future<void> deleteTask(String id);
}