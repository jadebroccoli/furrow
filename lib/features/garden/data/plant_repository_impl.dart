import '../domain/entities/plant.dart';
import '../domain/repositories/plant_repository.dart';

/// Local-first implementation of PlantRepository
/// Uses Drift (SQLite) for local storage
/// TODO: Add Firestore sync layer
class PlantRepositoryImpl implements PlantRepository {
  // TODO: Inject AppDatabase via constructor
  // PlantRepositoryImpl(this._db);
  // final AppDatabase _db;

  @override
  Future<List<Plant>> getPlants({String? seasonId}) async {
    // TODO: Implement with Drift queries
    return [];
  }

  @override
  Future<Plant?> getPlantById(String id) async {
    // TODO: Implement with Drift queries
    return null;
  }

  @override
  Future<List<Plant>> getPlantsByBed(String gardenBedId) async {
    // TODO: Implement with Drift queries
    return [];
  }

  @override
  Future<Plant> createPlant(Plant plant) async {
    // TODO: Insert into Drift, then sync to Firestore
    return plant;
  }

  @override
  Future<Plant> updatePlant(Plant plant) async {
    // TODO: Update in Drift, then sync to Firestore
    return plant;
  }

  @override
  Future<void> deletePlant(String id) async {
    // TODO: Delete from Drift, then sync to Firestore
  }

  @override
  Stream<List<Plant>> watchPlants({String? seasonId}) {
    // TODO: Return Drift watch stream
    return Stream.value([]);
  }

  @override
  Stream<Plant?> watchPlant(String id) {
    // TODO: Return Drift watch stream
    return Stream.value(null);
  }
}
