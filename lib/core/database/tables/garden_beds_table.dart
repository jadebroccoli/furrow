import 'package:drift/drift.dart';

/// Drift table definition for garden beds
class GardenBeds extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get sunExposure =>
      text().withDefault(const Constant('fullSun'))();
  TextColumn get soilType => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
