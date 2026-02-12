import 'package:freezed_annotation/freezed_annotation.dart';

part 'season.freezed.dart';
part 'season.g.dart';

/// A growing season (e.g., "Spring 2026")
@freezed
class Season with _$Season {
  const factory Season({
    required String id,
    required String name,
    required int year,
    required DateTime startDate,
    DateTime? endDate,
    String? notes,
    @Default(false) bool isActive,
    required DateTime createdAt,
  }) = _Season;

  factory Season.fromJson(Map<String, dynamic> json) =>
      _$SeasonFromJson(json);
}
