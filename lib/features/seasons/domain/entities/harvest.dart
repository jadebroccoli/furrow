import 'package:freezed_annotation/freezed_annotation.dart';

part 'harvest.freezed.dart';
part 'harvest.g.dart';

/// Unit of measurement for harvest quantity
enum HarvestUnit {
  lbs,
  kg,
  oz,
  grams,
  count,
  bunches,
}

/// A recorded harvest from a plant
@freezed
class Harvest with _$Harvest {
  const factory Harvest({
    required String id,
    required String plantId,
    required String seasonId,
    required DateTime date,
    required double quantity,
    @Default(HarvestUnit.lbs) HarvestUnit unit,
    @Default(3) int quality, // 1-5 rating
    String? notes,
    required DateTime createdAt,
  }) = _Harvest;

  factory Harvest.fromJson(Map<String, dynamic> json) =>
      _$HarvestFromJson(json);
}
