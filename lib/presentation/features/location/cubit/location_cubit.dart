import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
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

  // Biến để theo dõi stream subscription
  StreamSubscription? _locationStreamSubscription;
  String? _currentUserId;

  LocationCubit({
    required UpdateLocation updateLocation,
    required GetLocationStream getLocationStream,
  })  : _updateLocation = updateLocation,
        _getLocationStream = getLocationStream,
        super(LocationInitial());
  
  @override
  Future<void> close() {
    // Hủy đăng ký stream khi cubit bị đóng
    _locationStreamSubscription?.cancel();
    return super.close();
  }

  Future<void> updateLocation(String userId) async {
    if (isClosed) {
      print('Warning: Attempted to use a closed cubit');
      return;
    }
    
    emit(LocationLoading());
    try {
      await _updateLocation(userId);
      
      // Thêm độ trễ để đảm bảo DB có thời gian cập nhật
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Không emit loaded state ở đây vì stream sẽ tự động emit khi có dữ liệu mới
    } catch (e) {
      print('Error in updateLocation: $e');
      if (!isClosed) {
        emit(LocationError('Không thể cập nhật vị trí: ${e.toString()}'));
      }
    }
  }

  void getLocationStream(String userId) {
    if (isClosed) {
      print('Warning: Attempted to use a closed cubit');
      return;
    }
    
    // Hủy subscription cũ nếu có
    _locationStreamSubscription?.cancel();
    
    // Nếu đang theo dõi cùng một user, đảm bảo dọn dẹp tài nguyên trước
    if (_currentUserId != null && _currentUserId == userId) {
      print('Warning: Already listening to updates for user $userId');
    }
    
    _currentUserId = userId;
    emit(LocationLoading());
    
    try {
      // Lưu subscription để có thể hủy sau này
      _locationStreamSubscription = _getLocationStream(userId).listen(
        (event) {
          if (isClosed) return; // Kiểm tra nếu cubit đã đóng
          
          try {
            if (event.snapshot.value != null) {
              final data = event.snapshot.value as Map<dynamic, dynamic>;
              final Map<String, dynamic> locationData = {};
              
              // Convert Map<dynamic, dynamic> to Map<String, dynamic>
              data.forEach((key, value) {
                locationData[key.toString()] = value;
              });
              
              // Kiểm tra thêm xem dữ liệu location có hợp lệ không
              if (locationData.containsKey('latitude') && 
                  locationData.containsKey('longitude') &&
                  locationData.containsKey('timestamp')) {
                
                final location = Location.fromMap(locationData);
                
                // So sánh timestamp để đảm bảo chúng ta đang xử lý dữ liệu mới nhất
                if (_shouldUpdateLocation(location)) {
                  if (!isClosed) {
                    emit(LocationLoaded(location));
                  }
                } else {
                  print('Ignoring outdated location update');
                }
              } else {
                print('Received invalid location data: $locationData');
                if (!isClosed) {
                  emit(LocationError('Dữ liệu vị trí không hợp lệ'));
                }
              }
            } else {
              // Nếu không có dữ liệu, vẫn trả về Loading để người dùng biết cần cập nhật
              if (!isClosed) {
                emit(LocationInitial());
              }
            }
          } catch (e) {
            print('Error processing location data: $e');
            if (!isClosed) {
              emit(LocationError('Lỗi xử lý dữ liệu vị trí: ${e.toString()}'));
            }
          }
        },
        onError: (error) {
          print('Error in location stream: $error');
          if (!isClosed) {
            emit(LocationError('Lỗi nhận dữ liệu vị trí: ${error.toString()}'));
          }
        },
        onDone: () {
          print('Location stream completed for user $userId');
          _currentUserId = null;
        },
      );
    } catch (e) {
      print('Error setting up location stream: $e');
      if (!isClosed) {
        emit(LocationError('Không thể thiết lập luồng vị trí: ${e.toString()}'));
      }
    }
  }
  
  // Hàm để kiểm tra xem location có nên được cập nhật hay không
  // giúp tránh trường hợp nhiều thiết bị cập nhật cùng lúc
  bool _shouldUpdateLocation(Location newLocation) {
    // So sánh với trạng thái hiện tại
    if (state is LocationLoaded) {
      final currentLocation = (state as LocationLoaded).location;
      
      // Nếu timestamp của location mới lớn hơn hoặc = current, thì update
      return newLocation.timestamp.millisecondsSinceEpoch >= 
             currentLocation.timestamp.millisecondsSinceEpoch;
    }
    
    // Nếu không có dữ liệu hiện tại, luôn cập nhật
    return true;
  }
} 