import 'package:freezed_annotation/freezed_annotation.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// A photo journal entry linked to a plant
@freezed
class JournalEntry with _$JournalEntry {
  const factory JournalEntry({
    required String id,
    required String plantId,
    required DateTime date,
    String? note,
    String? photoPath,
    double? weatherTemp,
    String? weatherCondition,
    required DateTime createdAt,
  }) = _JournalEntry;

  factory JournalEntry.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryFromJson(json);
}
