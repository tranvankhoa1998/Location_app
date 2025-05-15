import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_realtime_db_datasource.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRealtimeDBDataSource dataSource;

  TaskRepositoryImpl(this.dataSource);

  @override
  Stream<List<Task>> getTasks() {
    return dataSource.getTasks().map(
          (taskModels) => taskModels.map((model) => model.toEntity()).toList(),
        );
  }

  @override
  Future<String> addTask(Task task) async {
    return await dataSource.addTask(
      title: task.task,
      date: task.date,
      description: task.description,
      number: task.number,
      metadata: task.metadata,
    );
  }

  @override
  Future<void> updateTask({
    required String id,
    String? title,
    DateTime? date,
    String? description,
    int? number,
    Map<String, dynamic>? metadata,
  }) async {
    await dataSource.updateTask(
      id: id,
      title: title,
      date: date,
      description: description,
      number: number,
      metadata: metadata,
    );
  }

  @override
  Future<void> deleteTask(String id) async {
    await dataSource.deleteTask(id);
  }
}