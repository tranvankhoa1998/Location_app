// lib/domain/usecases/get_current_location.dart
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetCurrentLocation {
  final LocationRepository repository;

  GetCurrentLocation(this.repository);

  Future<Location> call() async {
    return await repository.getCurrentLocation();
  }
}

