import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../shared/constants/app_constants.dart';
import 'tables/plants_table.dart';
import 'tables/garden_beds_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/seasons_table.dart';
import 'tables/harvests_table.dart';

part 'app_database.g.dart';

/// Main Drift database aggregating all tables
/// Handles local SQLite storage for offline-first operation
@DriftDatabase(tables: [
  Plants,
  GardenBeds,
  JournalEntries,
  Seasons,
  Harvests,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// For testing
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => AppConstants.databaseVersion;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // v2: Add plantName column to harvests for deletion resilience
          await m.addColumn(harvests, harvests.plantName);
          // Backfill existing records with plant names from the plants table
          await customStatement(
            'UPDATE harvests SET plant_name = ('
            '  SELECT name FROM plants WHERE plants.id = harvests.plant_id'
            ')',
          );
        }
      },
    );
  }

  // ─── Plant CRUD ───────────────────────────────────────────

  /// Watch all plants, ordered by most recently planted
  Stream<List<Plant>> watchAllPlants() {
    return (select(plants)
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.plantedDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch plants filtered by season
  Stream<List<Plant>> watchPlantsBySeason(String seasonId) {
    return (select(plants)
          ..where((t) => t.seasonId.equals(seasonId))
          ..orderBy([
            (t) => OrderingTerm(
                expression: t.plantedDate, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Get a single plant by ID
  Future<Plant?> getPlantById(String plantId) {
    return (select(plants)..where((t) => t.id.equals(plantId)))
        .getSingleOrNull();
  }

  /// Watch a single plant by ID
  Stream<Plant?> watchPlant(String plantId) {
    return (select(plants)..where((t) => t.id.equals(plantId)))
        .watchSingleOrNull();
  }

  /// Insert a new plant
  Future<void> insertPlant(PlantsCompanion plant) {
    return into(plants).insert(plant);
  }

  /// Update an existing plant
  Future<bool> updatePlant(PlantsCompanion plant) {
    return (update(plants)..where((t) => t.id.equals(plant.id.value)))
        .write(plant)
        .then((rows) => rows > 0);
  }

  /// Delete a plant by ID
  Future<int> deletePlantById(String plantId) {
    return (delete(plants)..where((t) => t.id.equals(plantId))).go();
  }

  // ─── Journal Entry CRUD ───────────────────────────────────

  /// Watch all journal entries, newest first
  Stream<List<JournalEntry>> watchAllJournalEntries() {
    return (select(journalEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch journal entries for a specific plant
  Stream<List<JournalEntry>> watchJournalEntriesForPlant(String plantId) {
    return (select(journalEntries)
          ..where((t) => t.plantId.equals(plantId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Insert a new journal entry
  Future<void> insertJournalEntry(JournalEntriesCompanion entry) {
    return into(journalEntries).insert(entry);
  }

  /// Delete a journal entry by ID
  Future<int> deleteJournalEntry(String entryId) {
    return (delete(journalEntries)..where((t) => t.id.equals(entryId))).go();
  }

  // ─── Season CRUD ────────────────────────────────────────────

  /// Watch all seasons, newest first
  Stream<List<Season>> watchAllSeasons() {
    return (select(seasons)
          ..orderBy([
            (t) => OrderingTerm(expression: t.year, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.startDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// Get the active season (if any)
  Future<Season?> getActiveSeason() {
    return (select(seasons)..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  /// Watch the active season
  Stream<Season?> watchActiveSeason() {
    return (select(seasons)..where((t) => t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  /// Insert a new season
  Future<void> insertSeason(SeasonsCompanion season) {
    return into(seasons).insert(season);
  }

  /// Update a season
  Future<bool> updateSeason(SeasonsCompanion season) {
    return (update(seasons)..where((t) => t.id.equals(season.id.value)))
        .write(season)
        .then((rows) => rows > 0);
  }

  /// Delete a season
  Future<int> deleteSeasonById(String seasonId) {
    return (delete(seasons)..where((t) => t.id.equals(seasonId))).go();
  }

  // ─── Harvest CRUD ───────────────────────────────────────────

  /// Watch all harvests for a season
  Stream<List<Harvest>> watchHarvestsBySeason(String seasonId) {
    return (select(harvests)
          ..where((t) => t.seasonId.equals(seasonId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch all harvests for a plant
  Stream<List<Harvest>> watchHarvestsByPlant(String plantId) {
    return (select(harvests)
          ..where((t) => t.plantId.equals(plantId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Watch all harvests across all seasons
  Stream<List<Harvest>> watchAllHarvests() {
    return (select(harvests)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.date, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  /// Insert a harvest
  Future<void> insertHarvest(HarvestsCompanion harvest) {
    return into(harvests).insert(harvest);
  }

  /// Delete a harvest
  Future<int> deleteHarvestById(String harvestId) {
    return (delete(harvests)..where((t) => t.id.equals(harvestId))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase.createInBackground(file);
  });
}
