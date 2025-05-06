import '../entities/task.dart';
import '../repositories/task_repository.dart';

class GetTasks {
  final TaskRepository repository;

  GetTasks(this.repository);

  Stream<List<Task>> call() {
    return repository.getTasks();
  }
}