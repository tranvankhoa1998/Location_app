import '../entities/location.dart';
import '../repositories/location_repository.dart';

class GetLocationStream {
  final LocationRepository repository;

  GetLocationStream(this.repository);

  Stream<Location> call() {
    return repository.getLocationStream();
  }
}
