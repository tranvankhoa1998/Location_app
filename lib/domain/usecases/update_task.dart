import '../repositories/task_repository.dart';

class UpdateTask {
  final TaskRepository repository;

  UpdateTask(this.repository);

  Future<void> call({
    required String id,
    String? title,
    DateTime? date,
    String? description,
    int? number,
  }) async {
    await repository.updateTask(
      id: id,
      title: title,
      date: date,
      description: description,
      number: number,
    );
  }
}