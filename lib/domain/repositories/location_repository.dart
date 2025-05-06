// lib/domain/repositories/location_repository.dart
import '../entities/location.dart';

abstract class LocationRepository {
  Future<Location> getCurrentLocation();
  Stream<Location> getLocationStream();
  Future<void> saveLocation(Location location);
  Future<void> startTracking();
  Future<void> stopTracking();
}