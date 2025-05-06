// lib/data/repositories/location_repository_impl.dart
import '../../domain/entities/location.dart';
import '../../domain/repositories/location_repository.dart';
import '../datasources/location_data_source.dart';
import '../models/location_model.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource dataSource;

  LocationRepositoryImpl(this.dataSource);

  @override
  Future<Location> getCurrentLocation() async {
    return await dataSource.getCurrentLocation();
  }

  @override
  Stream<Location> getLocationStream() {
    return dataSource.getLocationStream();
  }

  @override
  Future<void> saveLocation(Location location) async {
    final locationModel = LocationModel(
      latitude: location.latitude,
      longitude: location.longitude,
      accuracy: location.accuracy,
      altitude: location.altitude,
      speed: location.speed,
      timestamp: location.timestamp,
    );
    
    await dataSource.saveLocation(locationModel);
  }

  @override
  Future<void> startTracking() async {
    await dataSource.startTracking();
  }

  @override
  Future<void> stopTracking() async {
    await dataSource.stopTracking();
  }
}