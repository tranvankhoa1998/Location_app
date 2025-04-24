import '../entities/task.dart';

abstract class TaskRepository {
  Stream<List<Task>> getTasks();
  Future<void> addTask(String task);
  Future<void> updateTask(String id, int number);
  Future<void> deleteTask(String id);
}