// add_task.dart
import '../repositories/task_repository.dart';

class AddTask {
  final TaskRepository repository;
  AddTask(this.repository);

  Future<void> call(String task) => repository.addTask(task);
}