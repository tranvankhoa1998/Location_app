import '../repositories/task_repository.dart';

class UpdateTask {
  final TaskRepository repository;
  UpdateTask(this.repository);

  Future<void> call(String id, int number) => repository.updateTask(id, number);
}