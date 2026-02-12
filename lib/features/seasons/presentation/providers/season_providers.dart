import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/database/app_database.dart';

const _uuid = Uuid();

/// Watch all seasons
final seasonsStreamProvider = StreamProvider<List<Season>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSeasons();
});

/// Watch the active season
final activeSeasonProvider = StreamProvider<Season?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchActiveSeason();
});

/// Watch harvests for a specific season
final harvestsBySeasonProvider =
    StreamProvider.family<List<Harvest>, String>((ref, seasonId) {
  final db = ref.watch(databaseProvider);
  return db.watchHarvestsBySeason(seasonId);
});

/// Watch harvests for a specific plant
final harvestsByPlantProvider =
    StreamProvider.family<List<Harvest>, String>((ref, plantId) {
  final db = ref.watch(databaseProvider);
  return db.watchHarvestsByPlant(plantId);
});

/// Watch plants assigned to a specific season
final plantsBySeasonProvider =
    StreamProvider.family<List<Plant>, String>((ref, seasonId) {
  final db = ref.watch(databaseProvider);
  return db.watchPlantsBySeason(seasonId);
});

/// Watch all harvests
final allHarvestsProvider = StreamProvider<List<Harvest>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllHarvests();
});

/// Season + Harvest write actions
final seasonActionsProvider = Provider<SeasonActions>((ref) {
  final db = ref.watch(databaseProvider);
  return SeasonActions(db);
});

class SeasonActions {
  SeasonActions(this._db);
  final AppDatabase _db;

  /// Create a new season
  Future<void> createSeason({
    required String name,
    required int year,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    bool isActive = true,
  }) async {
    // If marking as active, deactivate all other seasons first
    if (isActive) {
      final allSeasons = await _db.select(_db.seasons).get();
      for (final s in allSeasons) {
        if (s.isActive) {
          await (_db.update(_db.seasons)
                ..where((t) => t.id.equals(s.id)))
              .write(const SeasonsCompanion(isActive: Value(false)));
        }
      }
    }

    final companion = SeasonsCompanion(
      id: Value(_uuid.v4()),
      name: Value(name),
      year: Value(year),
      startDate: Value(startDate),
      endDate: Value(endDate),
      notes: Value(notes),
      isActive: Value(isActive),
      createdAt: Value(DateTime.now()),
    );
    await _db.insertSeason(companion);
  }

  /// End a season (set end date, deactivate)
  Future<void> endSeason(String seasonId) async {
    final companion = SeasonsCompanion(
      id: Value(seasonId),
      endDate: Value(DateTime.now()),
      isActive: const Value(false),
    );
    await _db.updateSeason(companion);
  }

  /// Delete a season
  Future<void> deleteSeason(String seasonId) async {
    await _db.deleteSeasonById(seasonId);
  }

  /// Log a harvest
  Future<void> logHarvest({
    required String plantId,
    required String plantName,
    required String seasonId,
    required DateTime date,
    required double quantity,
    required String unit,
    int quality = 3,
    String? notes,
  }) async {
    final companion = HarvestsCompanion(
      id: Value(_uuid.v4()),
      plantId: Value(plantId),
      plantName: Value(plantName),
      seasonId: Value(seasonId),
      date: Value(date),
      quantity: Value(quantity),
      unit: Value(unit),
      quality: Value(quality),
      notes: Value(notes),
      createdAt: Value(DateTime.now()),
    );
    await _db.insertHarvest(companion);
  }

  /// Delete a harvest
  Future<void> deleteHarvest(String harvestId) async {
    await _db.deleteHarvestById(harvestId);
  }
}
