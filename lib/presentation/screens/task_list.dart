import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../domain/entities/task.dart';
import '../screens/task_cubit.dart';

class TaskList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskCubit, List<Task>>(
      builder: (context, tasks) {
        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.task_alt,
                  size: 64,
                  color: Colors.grey[400],
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có task nào',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhấn nút + để thêm task mới',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        // Sắp xếp tasks theo number (tăng dần)
        final sortedTasks = List<Task>.from(tasks)
          ..sort((a, b) => a.number.compareTo(b.number));

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            final task = sortedTasks[index];
            return _buildTaskItem(context, task);
          },
        );
      },
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    return Card(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(context, task),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task number
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    task.number.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              // Task details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            task.task,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${dateFormatter.format(task.date)} ${timeFormatter.format(task.date)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (task.description != null && task.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          task.description!,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              // Action buttons
              Column(
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditDialog(context, task),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    splashRadius: 24,
                  ),
                  SizedBox(height: 8),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(context, task),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    splashRadius: 24,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    // LƯU CUBIT TRƯỚC KHI MỞ DIALOG
    final taskCubit = BlocProvider.of<TaskCubit>(context, listen: false);
    
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          task.task,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'Ngày: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: dateFormatter.format(task.date)),
                ],
              ),
            ),
            SizedBox(height: 4),
            RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text: 'Giờ: ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: timeFormatter.format(task.date)),
                ],
              ),
            ),
            SizedBox(height: 8),
            if (task.description != null && task.description!.isNotEmpty) ...[
              Text(
                'Mô tả:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(task.description!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _showEditDialog(context, task);
            },
            child: Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Task task) {
    // LƯU CUBIT TRƯỚC KHI MỞ DIALOG
    final taskCubit = BlocProvider.of<TaskCubit>(context, listen: false);
    
    final titleController = TextEditingController(text: task.task);
    final descriptionController = TextEditingController(text: task.description ?? '');
    DateTime selectedDate = task.date;
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            return AlertDialog(
              title: Text('Chỉnh sửa Task'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(labelText: 'Tiêu đề'),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: 'Mô tả'),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            child: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                            onPressed: () async {
                              final now = DateTime.now();
                              final lastDate = DateTime(now.year + 5, now.month, now.day);
                              
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: lastDate,
                              );
                              
                              if (date != null) {
                                setState(() {
                                  selectedDate = DateTime(
                                    date.year,
                                    date.month,
                                    date.day,
                                    selectedDate.hour,
                                    selectedDate.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            child: Text(DateFormat('HH:mm').format(selectedDate)),
                            onPressed: () async {
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                              );
                              
                              if (time != null) {
                                setState(() {
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month,
                                    selectedDate.day,
                                    time.hour,
                                    time.minute,
                                  );
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: Text('Hủy'),
                ),
                TextButton(
                  onPressed: () {
                    final newTitle = titleController.text.trim();
                    final newDescription = descriptionController.text.trim();
                    
                    if (newTitle.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Tiêu đề không được để trống')),
                      );
                      return;
                    }
                    
                    try {
                      // DÙNG CUBIT ĐÃ LƯU TRƯỚC ĐÓ
                      taskCubit.updateExistingTask(
                        id: task.id,
                        title: newTitle,
                        date: selectedDate,
                        description: newDescription.isEmpty ? null : newDescription,
                      );
                      
                      Navigator.pop(dialogContext);
                    } catch (e) {
                      print('ERROR updating task: $e');
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('Lỗi: $e')),
                      );
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(dialogContext).colorScheme.primary,
                  ),
                  child: Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    // LƯU CUBIT TRƯỚC KHI MỞ DIALOG
    final taskCubit = BlocProvider.of<TaskCubit>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Xóa Task'),
        content: Text('Bạn có chắc chắn muốn xóa task "${task.task}" không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
            child: Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              try {
                // DÙNG CUBIT ĐÃ LƯU
                taskCubit.deleteExistingTask(task.id);
                Navigator.pop(dialogContext);
              } catch (e) {
                print('ERROR deleting task: $e');
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text('Xóa'),
          ),
        ],
      ),
    );
  }
}