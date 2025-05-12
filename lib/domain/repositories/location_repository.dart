// lib/domain/repositories/location_repository.dart
import 'package:firebase_database/firebase_database.dart';
import '../entities/location.dart';

abstract class LocationRepository {
  Future<Location> getCurrentLocation();
  Future<void> saveLocation(Location location);
  Future<void> startTracking();
  Future<void> stopTracking();
  Future<void> updateLocation(String userId, Location location);
  Stream<DatabaseEvent> getUserLocationStream(String userId);
}