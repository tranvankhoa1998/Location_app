import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../../../domain/usecases/toggle_tracking.dart';

// States
abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object?> get props => [];
}

class TrackingInitial extends TrackingState {}

class TrackingInProgress extends TrackingState {}

class TrackingEnabled extends TrackingState {
  const TrackingEnabled();
  
  @override
  List<Object?> get props => [];
}

class TrackingDisabled extends TrackingState {
  const TrackingDisabled();
  
  @override
  List<Object?> get props => [];
}

class TrackingError extends TrackingState {
  final String message;

  const TrackingError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class TrackingCubit extends Cubit<TrackingState> {
  final ToggleTracking _toggleTracking;

  TrackingCubit({
    required ToggleTracking toggleTracking,
  }) : _toggleTracking = toggleTracking,
        super(TrackingInitial());

  Future<void> toggleTracking() async {
    try {
      emit(TrackingInProgress());
      
      final isTracking = await _toggleTracking();
      
      if (isTracking) {
        emit(const TrackingEnabled());
      } else {
        emit(const TrackingDisabled());
      }
    } catch (e) {
      emit(TrackingError('Không thể thay đổi trạng thái theo dõi: ${e.toString()}'));
    }
  }
  
  // Kiểm tra trạng thái hiện tại của tracking
  Future<void> checkTrackingStatus() async {
    try {
      emit(TrackingInProgress());
      
      // Sử dụng trạng thái hiện tại từ ToggleTracking usecase
      final isTracking = _toggleTracking.isTracking;
      
      if (isTracking) {
        emit(const TrackingEnabled());
      } else {
        emit(const TrackingDisabled());
      }
    } catch (e) {
      emit(TrackingError('Không thể kiểm tra trạng thái theo dõi: ${e.toString()}'));
    }
  }
} 