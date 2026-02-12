import 'package:drift/drift.dart';

/// Drift table definition for plants
class Plants extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get variety => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('vegetable'))();
  DateTimeColumn get plantedDate => dateTime()();
  DateTimeColumn get expectedHarvestDate => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('seedling'))();
  TextColumn get gardenBedId => text().nullable()();
  TextColumn get seasonId => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get photoUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
