import '../repositories/location_repository.dart';

class ToggleTracking {
  final LocationRepository repository;
  bool isTracking = false;

  ToggleTracking(this.repository);

  Future<bool> call() async {
    isTracking = !isTracking;
    
    if (isTracking) {
      await repository.startTracking();
    } else {
      await repository.stopTracking();
    }
    
    return isTracking;
  }
}