import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../screens/task_list.dart';
import '../screens/task_cubit.dart';
import 'calendar_page.dart';
import 'create_new_task_page.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý Task'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () {
              // LẤY CUBIT HIỆN TẠI
              final taskCubit = BlocProvider.of<TaskCubit>(context);
              
              // TRUYỀN CUBIT VÀO TRANG MỚI
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: taskCubit,
                    child: CalendarPage(),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.person, color: Colors.blue),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentUser?.email ?? 'Người dùng',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'ID: ${currentUser?.uid ?? "Unknown"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TaskList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // LẤY CUBIT HIỆN TẠI
          final taskCubit = BlocProvider.of<TaskCubit>(context);
          
          // TRUYỀN CUBIT VÀO TRANG MỚI
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: taskCubit,
                child: CreateNewTaskPage(),
              ),
            ),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}