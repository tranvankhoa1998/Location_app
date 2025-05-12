import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../../../domain/entities/location.dart';
import '../../../../domain/usecases/update_location.dart';
import '../../../../domain/usecases/get_location_stream.dart';

// Events
abstract class LocationEvent extends Equatable {
  const LocationEvent();

  @override
  List<Object?> get props => [];
}

class UpdateLocationEvent extends LocationEvent {
  final String userId;

  const UpdateLocationEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class GetLocationStreamEvent extends LocationEvent {
  final String userId;

  const GetLocationStreamEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

// States
abstract class LocationState extends Equatable {
  const LocationState();

  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final Location location;

  const LocationLoaded(this.location);

  @override
  List<Object?> get props => [location];
}

class LocationError extends LocationState {
  final String message;

  const LocationError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class LocationCubit extends Cubit<LocationState> {
  final UpdateLocation _updateLocation;
  final GetLocationStream _getLocationStream;

  LocationCubit({
    required UpdateLocation updateLocation,
    required GetLocationStream getLocationStream,
  })  : _updateLocation = updateLocation,
        _getLocationStream = getLocationStream,
        super(LocationInitial());

  Future<void> updateLocation(String userId) async {
    emit(LocationLoading());
    try {
      await _updateLocation(userId);
      // Không cần emit loaded state ở đây vì stream sẽ tự động emit khi có dữ liệu mới
    } catch (e) {
      print('Error updating location: $e');
      emit(LocationError('Không thể cập nhật vị trí: ${e.toString()}'));
    }
  }

  void getLocationStream(String userId) {
    emit(LocationLoading());
    try {
      _getLocationStream(userId).listen(
        (event) {
          try {
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              final Map<String, dynamic> locationData = {};
              
              // Convert Map<dynamic, dynamic> to Map<String, dynamic>
              data.forEach((key, value) {
                locationData[key.toString()] = value;
              });
              
              final location = Location.fromMap(locationData);
              emit(LocationLoaded(location));
            } else {
              // Nếu không có dữ liệu, vẫn trả về Loading để người dùng biết cần cập nhật
              emit(LocationInitial());
            }
          } catch (e) {
            print('Error parsing location data: $e');
            print('Data received: ${event.snapshot.value}');
            emit(LocationError('Lỗi xử lý dữ liệu vị trí: ${e.toString()}'));
          }
        },
        onError: (error) {
          print('Location stream error: $error');
          emit(LocationError('Lỗi nhận dữ liệu vị trí: ${error.toString()}'));
        },
      );
    } catch (e) {
      print('Error setting up location stream: $e');
      emit(LocationError('Không thể thiết lập luồng vị trí: ${e.toString()}'));
    }
  }
} 