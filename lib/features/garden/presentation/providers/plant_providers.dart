import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/database/app_database.dart';

const _uuid = Uuid();

/// Stream provider: watches all plants from the database (reactive)
final plantsStreamProvider = StreamProvider<List<Plant>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllPlants();
});

/// Stream provider: watch a single plant by ID
final plantByIdProvider =
    StreamProvider.family<Plant?, String>((ref, plantId) {
  final db = ref.watch(databaseProvider);
  return db.watchPlant(plantId);
});

/// Stream provider: latest journal photo path for each plant (single query)
final latestPlantPhotosProvider = StreamProvider<Map<String, String>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchLatestPlantPhotos();
});

/// Notifier that handles plant write operations (add, update, delete)
final plantActionsProvider = Provider<PlantActions>((ref) {
  final db = ref.watch(databaseProvider);
  return PlantActions(db);
});

class PlantActions {
  PlantActions(this._db);
  final AppDatabase _db;

  /// Add a new plant to the database. Returns the generated plant ID.
  Future<String> addPlant({
    required String name,
    String? variety,
    required String category,
    required DateTime plantedDate,
    DateTime? expectedHarvestDate,
    String? status,
    String? gardenBedId,
    String? seasonId,
    String? notes,
    String? photoUrl,
  }) async {
    final plantId = _uuid.v4();
    final now = DateTime.now();
    final companion = PlantsCompanion(
      id: Value(plantId),
      name: Value(name),
      variety: Value(variety),
      category: Value(category),
      plantedDate: Value(plantedDate),
      expectedHarvestDate: Value(expectedHarvestDate),
      status: Value(status ?? 'seedling'),
      gardenBedId: Value(gardenBedId),
      seasonId: Value(seasonId),
      notes: Value(notes),
      photoUrl: Value(photoUrl),
      createdAt: Value(now),
      updatedAt: Value(now),
    );
    await _db.insertPlant(companion);
    return plantId;
  }

  /// Update an existing plant
  /// Update an existing plant.
  ///
  /// For [seasonId]: pass a value to assign to that season, or use
  /// [clearSeasonId] = true to remove from any season.
  /// Omitting both leaves the season unchanged.
  Future<bool> updatePlant({
    required String id,
    String? name,
    String? variety,
    String? category,
    DateTime? plantedDate,
    DateTime? expectedHarvestDate,
    String? status,
    String? notes,
    String? photoUrl,
    String? seasonId,
    bool clearSeasonId = false,
  }) async {
    final now = DateTime.now();
    final companion = PlantsCompanion(
      id: Value(id),
      name: name != null ? Value(name) : const Value.absent(),
      variety: variety != null ? Value(variety) : const Value.absent(),
      category: category != null ? Value(category) : const Value.absent(),
      plantedDate:
          plantedDate != null ? Value(plantedDate) : const Value.absent(),
      expectedHarvestDate: expectedHarvestDate != null
          ? Value(expectedHarvestDate)
          : const Value.absent(),
      status: status != null ? Value(status) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      photoUrl: photoUrl != null ? Value(photoUrl) : const Value.absent(),
      seasonId: clearSeasonId
          ? const Value(null)
          : (seasonId != null ? Value(seasonId) : const Value.absent()),
      updatedAt: Value(now),
    );
    return _db.updatePlant(companion);
  }

  /// Delete a plant
  Future<int> deletePlant(String id) {
    return _db.deletePlantById(id);
  }
}
