import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../task_cubit.dart';
import '../../domain/entities/task.dart';
import '../widgets/task_column.dart';
import 'create_new_task_page.dart';
import '../theme/colors/light_colors.dart'; // Import để dùng màu

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Task Planner',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<TaskCubit, List<Task>>(
                builder: (context, tasks) {
                  if (tasks.isEmpty) {
                    return const Center(
                      child: Text('Không có task nào!'),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: TaskColumn(
                          icon: Icons.check_circle_outline,
                          iconBackgroundColor: LightColors.kBlue,
                          title: task.task,
                          subtitle: 'Task #${task.number} - ${task.date.day}/${task.date.month}/${task.date.year}',
                          task: task,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: LightColors.kBlue,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateNewTaskPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}