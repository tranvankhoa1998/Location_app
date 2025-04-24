import '../../domain/entities/task.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_firestore_data_source.dart';
import '../models/task_model.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskFirestoreDataSource dataSource;
  TaskRepositoryImpl(this.dataSource);

  @override
  Stream<List<Task>> getTasks() {
    return dataSource.getTasks().map((models) =>
      models.map((model) => model.toEntity()).toList()
    );
  }

  @override
  Future<void> addTask(String task) => dataSource.addTask(task);

  @override
  Future<void> updateTask(String id, int number) => dataSource.updateTask(id, number);

  @override
  Future<void> deleteTask(String id) => dataSource.deleteTask(id);
}