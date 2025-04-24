import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task.dart';
import '../../domain/usecases/get_tasks.dart';
import '../../domain/usecases/add_task.dart';
import '../../domain/usecases/update_task.dart';
import '../../domain/usecases/delete_task.dart';

class TaskCubit extends Cubit<List<Task>> {
  final GetTasks getTasks;
  final AddTask addTask;
  final UpdateTask updateTask;
  final DeleteTask deleteTask;

  StreamSubscription? _taskSubscription;

  TaskCubit({
    required this.getTasks,
    required this.addTask,
    required this.updateTask,
    required this.deleteTask,
  }) : super([]) {
    loadTasks();
  }

  void loadTasks() {
  _taskSubscription?.cancel();
  _taskSubscription = getTasks().listen((tasks) {
    print('Tasks from Firestore: $tasks');
    emit(tasks);
  });
}  

  Future<void> addNewTask(String title) async {
    await addTask(title);
    // Không cần loadTasks() vì stream sẽ tự cập nhật
  }

  Future<void> updateExistingTask(String id, int number) async {
    await updateTask(id, number);
  }

  Future<void> deleteExistingTask(String id) async {
    await deleteTask(id);
  }

  @override
  Future<void> close() {
    _taskSubscription?.cancel();
    return super.close();
  }
}