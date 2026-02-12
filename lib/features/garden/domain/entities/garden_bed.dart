import 'package:freezed_annotation/freezed_annotation.dart';

part 'garden_bed.freezed.dart';
part 'garden_bed.g.dart';

/// Sun exposure level for a garden bed
enum SunExposure {
  fullSun,
  partialSun,
  partialShade,
  fullShade,
}

/// A physical garden bed or growing area
@freezed
class GardenBed with _$GardenBed {
  const factory GardenBed({
    required String id,
    required String name,
    String? description,
    String? location,
    @Default(SunExposure.fullSun) SunExposure sunExposure,
    String? soilType,
    required DateTime createdAt,
  }) = _GardenBed;

  factory GardenBed.fromJson(Map<String, dynamic> json) =>
      _$GardenBedFromJson(json);
}
