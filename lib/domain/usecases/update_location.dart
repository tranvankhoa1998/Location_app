import 'package:geolocator/geolocator.dart';
import '../entities/location.dart';
import '../repositories/location_repository.dart';

class UpdateLocation {
  final LocationRepository repository;

  UpdateLocation(this.repository);

  Future<void> call(String userId) async {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    final location = Location(
      latitude: position.latitude,
      longitude: position.longitude,
      timestamp: DateTime.now(),
    );

    await repository.updateLocation(userId, location);
  }
} 