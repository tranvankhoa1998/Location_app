import 'package:firebase_database/firebase_database.dart';
import '../repositories/location_repository.dart';

class GetLocationStream {
  final LocationRepository repository;

  GetLocationStream(this.repository);

  Stream<DatabaseEvent> call(String userId) {
    return repository.getUserLocationStream(userId);
  }
}
