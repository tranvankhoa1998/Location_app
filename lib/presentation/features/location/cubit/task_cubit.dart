import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/entities/task.dart';
import '../../../../domain/usecases/add_task.dart';
import '../../../../domain/usecases/delete_task.dart';
import '../../../../domain/usecases/get_tasks.dart';
import '../../../../domain/usecases/update_task.dart';

class TaskCubit extends Cubit<List<Task>> {
  final GetTasks _getTasks;
  final AddTask _addTask;
  final UpdateTask _updateTask;
  final DeleteTask _deleteTask;
  
  late StreamSubscription _tasksSubscription;

  TaskCubit({
    required GetTasks getTasks,
    required AddTask addTask,
    required UpdateTask updateTask,
    required DeleteTask deleteTask,
  })  : _getTasks = getTasks,
        _addTask = addTask,
        _updateTask = updateTask,
        _deleteTask = deleteTask,
        super([]) {
    _listenToTasks();
  }

  void _listenToTasks() {
    _tasksSubscription = _getTasks().listen(
      (tasks) {
        emit(tasks);
      },
      onError: (error) {
        print('Lỗi lắng nghe tasks: $error');
        emit([]);
      }
    );
  }

  @override
  Future<void> close() {
    _tasksSubscription.cancel();
    return super.close();
  }

  Future<void> addNewTaskFull({
    required String title,
    required DateTime date,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final newTask = Task(
        id: '',  // ID sẽ được tạo bởi Firebase
        task: title,
        date: date,
        description: description,
        number: state.length + 1,  // Số task tiếp theo
        metadata: metadata,
      );
      
      await _addTask(newTask);
    } catch (e) {
      print('Lỗi thêm task: $e');
    }
  }

  Future<void> updateExistingTask({
    required String id,
    String? title,
    DateTime? date,
    String? description,
    int? number,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _updateTask(
        id: id,
        title: title,
        date: date,
        description: description,
        number: number,
        metadata: metadata,
      );
    } catch (e) {
      print('Lỗi cập nhật task: $e');
    }
  }

  Future<void> deleteExistingTask(String id) async {
    try {
      await _deleteTask(id);
    } catch (e) {
      print('Lỗi xóa task: $e');
    }
  }
}