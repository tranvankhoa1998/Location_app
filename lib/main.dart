// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'injection_container.dart' as di;
import 'presentation/screens/task_cubit.dart';
import 'presentation/screen_2/location_cubit.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Khởi tạo dependency injection
  await di.init();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<TaskCubit>(
          create: (context) => di.sl<TaskCubit>(),
        ),
        BlocProvider<LocationCubit>(
          create: (context) => di.sl<LocationCubit>(),
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasData && snapshot.data != null) {
              // Người dùng đã đăng nhập
              return HomePage();
            } else {
              // Người dùng chưa đăng nhập
              return LoginScreen();
            }
          },
        ),
      ),
    );
  }
}