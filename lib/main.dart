// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'presentation/screens/task_cubit.dart';
import 'presentation/features/location/cubit/location_cubit.dart';
import 'presentation/screens/home_page.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/admin/admin_home_screen.dart';
import 'domain/usecases/get_user_by_id.dart';
import 'domain/entities/user.dart' as app_user;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase với DefaultFirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // Người dùng đã đăng nhập - trả về FutureBuilder để kiểm tra vai trò
          return FutureBuilder<app_user.User?>(
            future: di.sl<GetUserById>()(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              // Kiểm tra role và chuyển hướng đến màn hình phù hợp
              if (userSnapshot.hasData && 
                  userSnapshot.data != null && 
                  userSnapshot.data!.role == app_user.UserRole.admin) {
                return const AdminHomeScreen();
              } else {
                return HomePage();
              }
            },
          );
        } else {
          // Người dùng chưa đăng nhập
          return const LoginScreen();
        }
      },
    );
  }
}