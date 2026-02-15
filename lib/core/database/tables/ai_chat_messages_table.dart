import 'package:drift/drift.dart';

/// Drift table for AI chat messages (Garden Advisor)
class AiChatMessages extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()(); // 'user' or 'assistant'
  TextColumn get content => text()();
  TextColumn get plantId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
