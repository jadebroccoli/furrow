import '../entities/plant.dart';

/// Abstract repository for Plant data operations
/// Implemented by local (Drift) and remote (Firestore) data sources
abstract class PlantRepository {
  /// Get all plants, optionally filtered by season
  Future<List<Plant>> getPlants({String? seasonId});

  /// Get a single plant by ID
  Future<Plant?> getPlantById(String id);

  /// Get plants by garden bed
  Future<List<Plant>> getPlantsByBed(String gardenBedId);

  /// Create a new plant
  Future<Plant> createPlant(Plant plant);

  /// Update an existing plant
  Future<Plant> updatePlant(Plant plant);

  /// Delete a plant by ID
  Future<void> deletePlant(String id);

  /// Watch all plants as a stream (for reactive UI)
  Stream<List<Plant>> watchPlants({String? seasonId});

  /// Watch a single plant
  Stream<Plant?> watchPlant(String id);
}
