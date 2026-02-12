import 'package:drift/drift.dart';

/// Drift table definition for harvest records
class Harvests extends Table {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  TextColumn get plantName => text().nullable()();
  TextColumn get seasonId => text()();
  DateTimeColumn get date => dateTime()();
  RealColumn get quantity => real()();
  TextColumn get unit => text().withDefault(const Constant('lbs'))();
  IntColumn get quality =>
      integer().withDefault(const Constant(3))(); // 1-5 rating
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
