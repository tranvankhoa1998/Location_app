import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../features/location/cubit/task_cubit.dart';
import '../../../domain/entities/task.dart';
import '../../common/widgets/back_button.dart';

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildCalendar(),
            _buildTaskList(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          CustomBackButton(),
          SizedBox(width: 16),
          Text(
            'Lịch',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!), // Đơn giản hóa UI
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_selectedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                          _selectedDate.day,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                          _selectedDate.day,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildWeekDays(),
          SizedBox(height: 8),
          _buildDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildWeekDays() {
    final weekDays = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: weekDays
          .map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildDaysGrid() {
    // Lấy ngày đầu tiên trong tháng
    final firstDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
    
    // Lấy số ngày trong tháng
    final lastDayOfMonth = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Xác định ngày bắt đầu từ trong tuần (0 = chủ nhật, 1 = thứ 2, ...)
    final firstWeekday = firstDayOfMonth.weekday % 7;
    
    // Tạo danh sách ngày
    final days = List.generate(42, (index) {
      // Ngày trước tháng hiện tại
      if (index < firstWeekday) {
        return null;
      }
      // Ngày trong tháng hiện tại
      final dayOfMonth = index - firstWeekday + 1;
      if (dayOfMonth <= daysInMonth) {
        return DateTime(_selectedDate.year, _selectedDate.month, dayOfMonth);
      }
      // Ngày sau tháng hiện tại
      return null;
    });
    
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        if (day == null) {
          return Container();
        }
        
        final isToday = day.year == DateTime.now().year &&
            day.month == DateTime.now().month &&
            day.day == DateTime.now().day;
            
        final isSelected = day.year == _selectedDate.year &&
            day.month == _selectedDate.month &&
            day.day == _selectedDate.day;
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDate = DateTime(
                day.year,
                day.month,
                day.day,
                _selectedDate.hour,
                _selectedDate.minute,
              );
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : isToday
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                      : null,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isSelected 
                  ? Border.all(color: Theme.of(context).colorScheme.primary)
                  : null,
            ),
            child: Center(
              child: Text(
                day.day.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : null,
                  fontWeight: isToday || isSelected ? FontWeight.bold : null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return Expanded(
      child: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!), // Đơn giản hóa UI
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Tasks - ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<TaskCubit, List<Task>>(
                builder: (context, tasks) {
                  // Lọc task theo ngày đã chọn
                  final tasksOnSelectedDate = tasks.where((task) {
                    return task.date.year == _selectedDate.year &&
                        task.date.month == _selectedDate.month &&
                        task.date.day == _selectedDate.day;
                  }).toList();
                  
                  if (tasksOnSelectedDate.isEmpty) {
                    return Center(
                      child: Text('Không có task nào cho ngày này'),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: tasksOnSelectedDate.length,
                    itemBuilder: (context, index) {
                      final task = tasksOnSelectedDate[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text(
                            task.number.toString(),
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        title: Text(
                          task.task,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(DateFormat('HH:mm').format(task.date)),
                            if (task.description != null && task.description!.isNotEmpty)
                              Text(
                                task.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                        onTap: () => _showTaskDetails(context, task),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.task),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ngày: ${DateFormat('dd/MM/yyyy').format(task.date)}'),
            Text('Giờ: ${DateFormat('HH:mm').format(task.date)}'),
            SizedBox(height: 8),
            if (task.description != null && task.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Mô tả:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(task.description!),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Hiển thị dialog chỉnh sửa
              final titleController = TextEditingController(text: task.task);
              final descriptionController = TextEditingController(text: task.description ?? '');
              DateTime selectedDate = task.date;
              
              showDialog(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setState) {
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
                                          context: context,
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
                                          context: context,
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
                            onPressed: () => Navigator.pop(context),
                            child: Text('Hủy'),
                          ),
                          TextButton(
                            onPressed: () {
                              final newTitle = titleController.text.trim();
                              final newDescription = descriptionController.text.trim();
                              
                              if (newTitle.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tiêu đề không được để trống')),
                                );
                                return;
                              }
                              
                              context.read<TaskCubit>().updateExistingTask(
                                id: task.id,
                                title: newTitle,
                                date: selectedDate,
                                description: newDescription.isEmpty ? null : newDescription,
                              );
                              
                              Navigator.pop(context);
                            },
                            child: Text('Lưu'),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
            child: Text('Chỉnh sửa'),
          ),
        ],
      ),
    );
  }
}