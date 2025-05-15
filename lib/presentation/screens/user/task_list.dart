import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/task.dart';
import '../../features/location/cubit/task_cubit.dart';
import '../../common/widgets/animated_task_card.dart';

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
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.blue.shade300,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Chưa có task nào',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Nhấn nút + để thêm task mới',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: sortedTasks.length,
          itemBuilder: (context, index) {
            final task = sortedTasks[index];
            return _buildAnimatedTaskItem(context, task);
          },
        );
      },
    );
  }

  Widget _buildAnimatedTaskItem(BuildContext context, Task task) {
    // Determine priority based on metadata if available, otherwise use task number
    TaskPriority priority;
    
    if (task.metadata != null && task.metadata!.containsKey('priority')) {
      final priorityStr = task.metadata!['priority'] as String;
      if (priorityStr == "high") {
        priority = TaskPriority.high;
      } else if (priorityStr == "medium") {
        priority = TaskPriority.medium;
      } else if (priorityStr == "low") {
        priority = TaskPriority.low;
      } else {
        // Fallback to number-based priority
        if (task.number % 3 == 0) {
          priority = TaskPriority.high;
        } else if (task.number % 2 == 0) {
          priority = TaskPriority.medium;
        } else {
          priority = TaskPriority.low;
        }
      }
    } else {
      // Fallback to number-based priority
      if (task.number % 3 == 0) {
        priority = TaskPriority.high;
      } else if (task.number % 2 == 0) {
        priority = TaskPriority.medium;
      } else {
        priority = TaskPriority.low;
      }
    }

    return AnimatedTaskCard(
      title: task.task,
      description: task.description,
      dueDate: task.date,
      priority: priority,
      onTap: () => _showTaskDetails(context, task),
      onDelete: () => _showDeleteConfirmation(context, task),
      onComplete: () => _showEditDialog(context, task),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    // LƯU CUBIT TRƯỚC KHI MỞ DIALOG
    final taskCubit = BlocProvider.of<TaskCubit>(context, listen: false);
    
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final timeFormatter = DateFormat('HH:mm');

    // Determine priority based on metadata if available, otherwise use task number
    TaskPriority priority;
    
    if (task.metadata != null && task.metadata!.containsKey('priority')) {
      final priorityStr = task.metadata!['priority'] as String;
      if (priorityStr == "high") {
        priority = TaskPriority.high;
      } else if (priorityStr == "medium") {
        priority = TaskPriority.medium;
      } else if (priorityStr == "low") {
        priority = TaskPriority.low;
      } else {
        // Fallback to number-based priority
        if (task.number % 3 == 0) {
          priority = TaskPriority.high;
        } else if (task.number % 2 == 0) {
          priority = TaskPriority.medium;
        } else {
          priority = TaskPriority.low;
        }
      }
    } else {
      // Fallback to number-based priority
      if (task.number % 3 == 0) {
        priority = TaskPriority.high;
      } else if (task.number % 2 == 0) {
        priority = TaskPriority.medium;
      } else {
        priority = TaskPriority.low;
      }
    }

    // Get priority color
    Color priorityColor;
    String priorityText;
    switch (priority) {
      case TaskPriority.low:
        priorityColor = Colors.green;
        priorityText = 'Thấp';
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange;
        priorityText = 'Trung bình';
        break;
      case TaskPriority.high:
        priorityColor = Colors.red;
        priorityText = 'Cao';
        break;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with task title and priority
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: priorityColor, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.flag, size: 14, color: priorityColor),
                              SizedBox(width: 4),
                              Text(
                                priorityText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: priorityColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300, width: 1),
                          ),
                          child: Text(
                            '#${task.number}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      task.task,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Task details
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date and time
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 20, color: Colors.blue.shade700),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dateFormatter.format(task.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                timeFormatter.format(task.date),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    // Description
                    if (task.description != null && task.description!.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Text(
                        'Mô tả:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          task.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    
                    // Created date
                    SizedBox(height: 16),
                    Text(
                      'Tạo lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(task.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.close),
            label: Text('Đóng'),
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          TextButton.icon(
            icon: Icon(Icons.edit),
            label: Text('Chỉnh sửa'),
            onPressed: () {
              Navigator.pop(dialogContext);
              _showEditDialog(context, task);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
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

    // Determine priority based on metadata if available, otherwise use task number
    TaskPriority selectedPriority;
    
    if (task.metadata != null && task.metadata!.containsKey('priority')) {
      final priorityStr = task.metadata!['priority'] as String;
      if (priorityStr == "high") {
        selectedPriority = TaskPriority.high;
      } else if (priorityStr == "medium") {
        selectedPriority = TaskPriority.medium;
      } else if (priorityStr == "low") {
        selectedPriority = TaskPriority.low;
      } else {
        // Fallback to number-based priority
        if (task.number % 3 == 0) {
          selectedPriority = TaskPriority.high;
        } else if (task.number % 2 == 0) {
          selectedPriority = TaskPriority.medium;
        } else {
          selectedPriority = TaskPriority.low;
        }
      }
    } else {
      // Fallback to number-based priority
      if (task.number % 3 == 0) {
        selectedPriority = TaskPriority.high;
      } else if (task.number % 2 == 0) {
        selectedPriority = TaskPriority.medium;
      } else {
        selectedPriority = TaskPriority.low;
      }
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (builderContext, setState) {
            // Get priority color based on selected priority
            Color getPriorityColor(TaskPriority priority) {
              switch (priority) {
                case TaskPriority.low:
                  return Colors.green;
                case TaskPriority.medium:
                  return Colors.orange;
                case TaskPriority.high:
                  return Colors.red;
              }
            }
            
            // Get priority text based on selected priority
            String getPriorityText(TaskPriority priority) {
              switch (priority) {
                case TaskPriority.low:
                  return 'Thấp';
                case TaskPriority.medium:
                  return 'Trung bình';
                case TaskPriority.high:
                  return 'Cao';
              }
            }
            
            Color priorityColor = getPriorityColor(selectedPriority);
            
            return AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.edit, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Chỉnh sửa Task',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ],
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Task number badge
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade300, width: 1),
                          ),
                          child: Text(
                            '#${task.number}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // Priority selection box
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Độ ưu tiên',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildPriorityOption(
                                  context: builderContext,
                                  priority: TaskPriority.low,
                                  selectedPriority: selectedPriority,
                                  onTap: () {
                                    setState(() {
                                      selectedPriority = TaskPriority.low;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildPriorityOption(
                                  context: builderContext,
                                  priority: TaskPriority.medium,
                                  selectedPriority: selectedPriority,
                                  onTap: () {
                                    setState(() {
                                      selectedPriority = TaskPriority.medium;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: _buildPriorityOption(
                                  context: builderContext,
                                  priority: TaskPriority.high,
                                  selectedPriority: selectedPriority,
                                  onTap: () {
                                    setState(() {
                                      selectedPriority = TaskPriority.high;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Title field
                    Text(
                      'Tiêu đề',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: 'Nhập tiêu đề task',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Description field
                    Text(
                      'Mô tả',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        hintText: 'Nhập mô tả chi tiết (không bắt buộc)',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 16),
                    
                    // Date and time
                    Text(
                      'Thời gian',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final now = DateTime.now();
                              final lastDate = DateTime(now.year + 5, now.month, now.day);
                              
                              final date = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedDate,
                                firstDate: DateTime(2020),
                                lastDate: lastDate,
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.blue,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    DateFormat('dd/MM/yyyy').format(selectedDate),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: dialogContext,
                                initialTime: TimeOfDay.fromDateTime(selectedDate),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Colors.blue,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
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
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.access_time, size: 16, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    DateFormat('HH:mm').format(selectedDate),
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  icon: Icon(Icons.close),
                  label: Text('Hủy'),
                  onPressed: () => Navigator.pop(dialogContext),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                ),
                ElevatedButton.icon(
                  icon: Icon(Icons.save),
                  label: Text('Lưu'),
                  onPressed: () {
                    final newTitle = titleController.text.trim();
                    final newDescription = descriptionController.text.trim();
                    
                    if (newTitle.isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Tiêu đề không được để trống'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }
                    
                    try {
                      // DÙNG CUBIT ĐÃ LƯU TRƯỚC ĐÓ
                      
                      // Lưu priority dưới dạng giá trị đơn giản: "low", "medium", "high" 
                      String priorityValue;
                      switch (selectedPriority) {
                        case TaskPriority.low:
                          priorityValue = "low";
                          break;
                        case TaskPriority.medium:
                          priorityValue = "medium";
                          break;
                        case TaskPriority.high:
                          priorityValue = "high";
                          break;
                      }
                      
                      taskCubit.updateExistingTask(
                        id: task.id,
                        title: newTitle,
                        date: selectedDate,
                        description: newDescription.isEmpty ? null : newDescription,
                        // Lưu thông tin về độ ưu tiên vào task metadata với giá trị đơn giản
                        metadata: {'priority': priorityValue},
                      );
                      
                      Navigator.pop(dialogContext);
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã cập nhật task thành công'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      print('ERROR updating task: $e');
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text('Lỗi: $e'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPriorityOption({
    required BuildContext context,
    required TaskPriority priority,
    required TaskPriority selectedPriority,
    required VoidCallback onTap,
  }) {
    // Define color and text based on priority
    Color color;
    String text;
    IconData icon;
    
    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        text = 'Thấp';
        icon = Icons.arrow_downward;
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        text = 'TB';
        icon = Icons.remove;
        break;
      case TaskPriority.high:
        color = Colors.red;
        text = 'Cao';
        icon = Icons.arrow_upward;
        break;
    }
    
    final isSelected = priority == selectedPriority;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Task task) {
    // LƯU CUBIT TRƯỚC KHI MỞ DIALOG
    final taskCubit = BlocProvider.of<TaskCubit>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'Xóa Task',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn có chắc chắn muốn xóa task sau không?',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '#${task.number}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.task,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (task.description != null && task.description!.isNotEmpty) ...[
                    SizedBox(height: 8),
                    Text(
                      task.description!,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  SizedBox(height: 8),
                  Text(
                    'Ngày tạo: ${DateFormat('dd/MM/yyyy').format(task.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Hành động này không thể hoàn tác!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: Icon(Icons.close),
            label: Text('Hủy'),
            onPressed: () => Navigator.pop(dialogContext),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[700],
            ),
          ),
          ElevatedButton.icon(
            icon: Icon(Icons.delete),
            label: Text('Xóa'),
            onPressed: () {
              try {
                // DÙNG CUBIT ĐÃ LƯU
                taskCubit.deleteExistingTask(task.id);
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã xóa task thành công'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                print('ERROR deleting task: $e');
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi: $e'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}