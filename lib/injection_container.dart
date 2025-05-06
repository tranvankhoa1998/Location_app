// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'data/datasources/task_realtime_db_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';
import 'domain/usecases/add_task.dart';
import 'domain/usecases/delete_task.dart';
import 'domain/usecases/get_tasks.dart';
import 'domain/usecases/update_task.dart';
import 'presentation/screens/task_cubit.dart';

// Imports mới cho location
import 'data/datasources/location_data_source.dart';
import 'data/datasources/auth_service.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'domain/usecases/get_current_location.dart';
import 'domain/usecases/get_location_stream.dart';
import 'domain/usecases/save_location.dart';
import 'domain/usecases/toggle_tracking.dart';
import 'presentation/screen_2/location_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Cubit
  sl.registerFactory(
    () => TaskCubit(
      getTasks: sl(),
      addTask: sl(),
      updateTask: sl(),
      deleteTask: sl(),
    ),
  );
  
  // Location Cubit
  sl.registerFactory(
    () => LocationCubit(
      getCurrentLocation: sl(),
      getLocationStream: sl(),
      toggleTracking: sl(),
      saveLocation: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => GetTasks(sl()));
  sl.registerLazySingleton(() => AddTask(sl()));
  sl.registerLazySingleton(() => UpdateTask(sl()));
  sl.registerLazySingleton(() => DeleteTask(sl()));
  
  // Location Use cases
  sl.registerLazySingleton(() => GetCurrentLocation(sl()));
  sl.registerLazySingleton(() => GetLocationStream(sl()));
  sl.registerLazySingleton(() => SaveLocation(sl()));
  sl.registerLazySingleton(() => ToggleTracking(sl()));

  // Repository
  sl.registerLazySingleton<TaskRepository>(
    () => TaskRepositoryImpl(sl()),
  );
  
  // Location Repository
  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(sl()),
  );

  // Data sources
  sl.registerLazySingleton<TaskRealtimeDBDataSource>(
    () => TaskRealtimeDBDataSource(),
  );
  
  // Location Data source
  sl.registerLazySingleton<LocationDataSource>(
    () => LocationDataSourceImpl(),
  );
  
  // Auth Service
  sl.registerLazySingleton(() => AuthService());
}