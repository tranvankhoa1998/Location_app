// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_options.dart';
import 'injection_container.dart' as di;
import 'presentation/features/location/cubit/task_cubit.dart';
import 'presentation/features/location/cubit/location_cubit.dart';
import 'presentation/screens/user/home_page.dart';
import 'presentation/screens/user/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Cấu hình cho Google Maps
  if (Platform.isAndroid) {
    // Cấu hình đúng cách cho AndroidGoogleMapsFlutter
    AndroidGoogleMapsFlutter.useAndroidViewSurface = true;
  }
  
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
          // Người dùng đã đăng nhập - chuyển đến trang home
          return HomePage();
        } else {
          // Người dùng chưa đăng nhập
          return const LoginScreen();
        }
      },
    );
  }
}