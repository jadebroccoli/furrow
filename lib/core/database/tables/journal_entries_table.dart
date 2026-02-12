import 'package:drift/drift.dart';

/// Drift table definition for journal entries
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get plantId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get photoPath => text().nullable()();
  RealColumn get weatherTemp => real().nullable()();
  TextColumn get weatherCondition => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
