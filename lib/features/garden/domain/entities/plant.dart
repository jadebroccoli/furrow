import 'package:freezed_annotation/freezed_annotation.dart';

part 'plant.freezed.dart';
part 'plant.g.dart';

/// Plant status throughout its lifecycle
enum PlantStatus {
  planned,
  seedling,
  growing,
  flowering,
  harvesting,
  dormant,
  removed,
}

/// Category of plant
enum PlantCategory {
  vegetable,
  herb,
  fruit,
  flower,
  legume,
  root,
  houseplant,
  other,
}

/// Categories that follow a seed-to-harvest lifecycle.
/// Non-harvestable categories (flower, houseplant) get care-only UI.
const Set<String> _harvestableCategories = {
  'vegetable', 'herb', 'fruit', 'legume', 'root',
};

/// Whether a category follows the harvest lifecycle
bool isHarvestable(String category) =>
    _harvestableCategories.contains(category);

/// Core Plant entity - the central model in Furrow
@freezed
class Plant with _$Plant {
  const factory Plant({
    required String id,
    required String name,
    String? variety,
    @Default(PlantCategory.vegetable) PlantCategory category,
    required DateTime plantedDate,
    DateTime? expectedHarvestDate,
    @Default(PlantStatus.seedling) PlantStatus status,
    String? gardenBedId,
    String? seasonId,
    String? notes,
    String? photoUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Plant;

  factory Plant.fromJson(Map<String, dynamic> json) => _$PlantFromJson(json);
}
