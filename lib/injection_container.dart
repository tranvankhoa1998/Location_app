// lib/injection_container.dart
import 'package:get_it/get_it.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Repositories and data sources
import 'data/datasources/task_realtime_db_datasource.dart';
import 'data/repositories/task_repository_impl.dart';
import 'domain/repositories/task_repository.dart';
import 'data/datasources/location_data_source.dart';
import 'data/repositories/location_repository_impl.dart';
import 'domain/repositories/location_repository.dart';
import 'data/datasources/user_firestore_datasource.dart';
import 'data/repositories/user_repository_impl.dart';
import 'domain/repositories/user_repository.dart';

// Use cases
import 'domain/usecases/add_task.dart';
import 'domain/usecases/delete_task.dart';
import 'domain/usecases/get_tasks.dart';
import 'domain/usecases/update_task.dart';
import 'domain/usecases/get_current_location.dart';
import 'domain/usecases/get_location_stream.dart';
import 'domain/usecases/save_location.dart';
import 'domain/usecases/toggle_tracking.dart';
import 'domain/usecases/update_location.dart';
import 'domain/usecases/get_user_by_id.dart';

// Cubits
import 'presentation/features/location/cubit/task_cubit.dart';
import 'presentation/features/location/cubit/location_cubit.dart';
import 'presentation/features/location/cubit/tracking_cubit.dart';

final sl = GetIt.instance;

Future<void> init() async {
  try {    // External
    sl.registerLazySingleton<FirebaseDatabase>(() => FirebaseDatabase.instance);
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
    
    // Data sources
    sl.registerLazySingleton<LocationDataSource>(
      () => LocationDataSourceImpl(),
    );
    sl.registerLazySingleton<TaskRealtimeDBDataSource>(
      () => TaskRealtimeDBDataSource(),
    );
    sl.registerLazySingleton<UserFirestoreDataSource>(
      () => UserFirestoreDataSource(),
    );
    
    // Repositories
    sl.registerLazySingleton<LocationRepository>(
      () => LocationRepositoryImpl(sl<LocationDataSource>(), sl<FirebaseDatabase>()),
    );
    sl.registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(sl<TaskRealtimeDBDataSource>()),
    );
    sl.registerLazySingleton<UserRepository>(
      () => UserRepositoryImpl(sl<UserFirestoreDataSource>()),
    );
    
    // Task Use cases
    sl.registerLazySingleton(() => GetTasks(sl<TaskRepository>()));
    sl.registerLazySingleton(() => AddTask(sl<TaskRepository>()));
    sl.registerLazySingleton(() => UpdateTask(sl<TaskRepository>()));
    sl.registerLazySingleton(() => DeleteTask(sl<TaskRepository>()));
    
    // Location Use cases
    sl.registerLazySingleton(() => GetCurrentLocation(sl<LocationRepository>()));
    sl.registerLazySingleton(() => GetLocationStream(sl<LocationRepository>()));
    sl.registerLazySingleton(() => SaveLocation(sl<LocationRepository>()));
    sl.registerLazySingleton(() => ToggleTracking(sl<LocationRepository>()));
    sl.registerLazySingleton(() => UpdateLocation(sl<LocationRepository>()));
      // User Use cases
    sl.registerLazySingleton(() => GetUserById(sl<UserRepository>()));
    
    // Cubits
    sl.registerFactory<LocationCubit>(
      () => LocationCubit(
        updateLocation: sl<UpdateLocation>(),
        getLocationStream: sl<GetLocationStream>(),
      ),
    );
    
    sl.registerFactory<TrackingCubit>(
      () => TrackingCubit(
        toggleTracking: sl<ToggleTracking>(),
      ),
    );
    
    // Task Cubit
    sl.registerFactory<TaskCubit>(
      () => TaskCubit(
        getTasks: sl<GetTasks>(),
        addTask: sl<AddTask>(),
        updateTask: sl<UpdateTask>(),
        deleteTask: sl<DeleteTask>(),
      ),
    );
  } catch (e) {
    rethrow;
  }
}