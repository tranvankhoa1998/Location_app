import '../entities/location.dart';
import '../repositories/location_repository.dart';

class SaveLocation {
  final LocationRepository repository;

  SaveLocation(this.repository);

  Future<void> call(Location location) async {
    await repository.saveLocation(location);
  }
}