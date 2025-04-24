import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'task_cubit.dart';
import '../../domain/entities/task.dart';

class TaskList extends StatelessWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, List<Task>>(
      builder: (context, tasks) {
        if (tasks.isEmpty) {
          return const Center(child: Text('Không có task nào!'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text('${task.number}'),
                ),
                title: Text(
                  task.task,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Ngày tạo: ${task.date.day}/${task.date.month}/${task.date.year}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () {
                    context.read<TaskCubit>().deleteExistingTask(task.id);
                  },
                ),
                onTap: () {
                  context.read<TaskCubit>().updateExistingTask(task.id, 20);
                },
              ),
            );
          },
        );
      },
    );
  }
}