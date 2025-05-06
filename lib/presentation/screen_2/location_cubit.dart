// lib/presentation/cubit/location_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/location.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_location_stream.dart';
import '../../domain/usecases/save_location.dart';
import '../../domain/usecases/toggle_tracking.dart';
import '../../data/models/location_model.dart';

// States
abstract class LocationState {}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final Location location;
  final Set<Marker> markers;
  final bool isTracking;

  LocationLoaded({
    required this.location,
    required this.markers,
    required this.isTracking,
  });
}

class LocationError extends LocationState {
  final String message;

  LocationError(this.message);
}

// Cubit
class LocationCubit extends Cubit<LocationState> {
  final GetCurrentLocation getCurrentLocation;
  final GetLocationStream getLocationStream;
  final ToggleTracking toggleTracking;
  final SaveLocation saveLocation; // Thêm SaveLocation usecase
  
  StreamSubscription? _locationSubscription;
  bool _isTracking = false;

  LocationCubit({
    required this.getCurrentLocation,
    required this.getLocationStream,
    required this.toggleTracking,
    required this.saveLocation, // Thêm vào constructor
  }) : super(LocationInitial());

  Future<void> loadCurrentLocation() async {
    emit(LocationLoading());
    
    try {
      final location = await getCurrentLocation();
      final markers = _createMarkers(location);
      
      emit(LocationLoaded(
        location: location,
        markers: markers,
        isTracking: _isTracking,
      ));
      
      // Lắng nghe stream vị trí nếu đang tracking
      if (_isTracking) {
        _listenToLocationUpdates();
      }
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  // Thêm phương thức lưu vị trí
  Future<void> saveCustomLocation(LocationModel locationModel) async {
    try {
      // Gọi usecase để lưu vị trí
      await saveLocation(locationModel);
      
      // Cập nhật state với vị trí mới
      final markers = _createMarkers(locationModel);
      emit(LocationLoaded(
        location: locationModel,
        markers: markers,
        isTracking: _isTracking,
      ));
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  Future<void> toggleLocationTracking() async {
    try {
      _isTracking = await toggleTracking();
      
      if (_isTracking) {
        _listenToLocationUpdates();
      } else {
        _locationSubscription?.cancel();
        _locationSubscription = null;
      }
      
      // Cập nhật state với trạng thái tracking mới
      if (state is LocationLoaded) {
        final currentState = state as LocationLoaded;
        emit(LocationLoaded(
          location: currentState.location,
          markers: currentState.markers,
          isTracking: _isTracking,
        ));
      }
    } catch (e) {
      emit(LocationError(e.toString()));
    }
  }

  void _listenToLocationUpdates() {
    _locationSubscription?.cancel();
    _locationSubscription = getLocationStream().listen(
      (location) {
        if (state is LocationLoaded) {
          final markers = _createMarkers(location);
          emit(LocationLoaded(
            location: location,
            markers: markers,
            isTracking: _isTracking,
          ));
        }
      },
      onError: (error) {
        emit(LocationError(error.toString()));
      },
    );
  }

  Set<Marker> _createMarkers(Location location) {
    return {
      Marker(
        markerId: MarkerId('current_location'),
        position: LatLng(location.latitude, location.longitude),
        infoWindow: InfoWindow(
          title: 'Vị trí hiện tại',
          snippet: '${location.latitude}, ${location.longitude}',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    };
  }

  @override
  Future<void> close() {
    _locationSubscription?.cancel();
    return super.close();
  }
}