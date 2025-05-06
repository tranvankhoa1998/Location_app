import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/login_page.dart';
import 'data/datasources/task_realtime_db_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/usecases/add_task.dart';
import 'domain/usecases/delete_task.dart';
import 'domain/usecases/get_tasks.dart';
import 'domain/usecases/update_task.dart';
import 'presentation/screens/task_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp();
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
  }
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.light(
          primary: Color(0xFF0099e5),
        ),
      ),
      home: AuthenticationWrapper(),
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData) {
          try {
            print('User logged in: ${snapshot.data?.uid}');
            
            // Khởi tạo datasource và TaskCubit
            final dataSource = TaskRealtimeDBDataSource();
            final repository = TaskRepositoryImpl(dataSource);
            final getTasks = GetTasks(repository);
            final addTask = AddTask(repository);
            final updateTask = UpdateTask(repository);
            final deleteTask = DeleteTask(repository);
            
            final taskCubit = TaskCubit(
              getTasks: getTasks,
              addTask: addTask,
              updateTask: updateTask,
              deleteTask: deleteTask,
            );
            
            // QUAN TRỌNG: Bọc HomePage trong BlocProvider
            return BlocProvider<TaskCubit>.value(
              value: taskCubit,
              child: HomePage(),
            );
          } catch (e) {
            print('ERROR initializing TaskCubit: $e');
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Lỗi khởi tạo: $e',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Đăng xuất'),
                      onPressed: () => FirebaseAuth.instance.signOut(),
                    ),
                  ],
                ),
              ),
            );
          }
        }
        
        // User is not logged in
        return LoginScreen();
      },
    );
  }
}