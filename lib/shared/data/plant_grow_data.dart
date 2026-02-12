import 'plant_species_data.dart';

/// Static grow data per plant category.
/// Used for harvest timing estimates and progress indicators.
class PlantGrowData {
  const PlantGrowData({
    required this.category,
    required this.daysToHarvestMin,
    required this.daysToHarvestMax,
  });

  final String category;
  final int daysToHarvestMin;
  final int daysToHarvestMax;

  /// Midpoint estimate in days
  int get daysToHarvestEstimate => (daysToHarvestMin + daysToHarvestMax) ~/ 2;
}

/// Lookup table — keys match PlantCategory.name strings stored in the database
const Map<String, PlantGrowData> plantGrowDataTable = {
  'vegetable': PlantGrowData(
      category: 'vegetable', daysToHarvestMin: 50, daysToHarvestMax: 90),
  'herb': PlantGrowData(
      category: 'herb', daysToHarvestMin: 30, daysToHarvestMax: 60),
  'fruit': PlantGrowData(
      category: 'fruit', daysToHarvestMin: 60, daysToHarvestMax: 120),
  'flower': PlantGrowData(
      category: 'flower', daysToHarvestMin: 45, daysToHarvestMax: 75),
  'legume': PlantGrowData(
      category: 'legume', daysToHarvestMin: 55, daysToHarvestMax: 80),
  'root': PlantGrowData(
      category: 'root', daysToHarvestMin: 60, daysToHarvestMax: 100),
  'houseplant': PlantGrowData(
      category: 'houseplant', daysToHarvestMin: 0, daysToHarvestMax: 0),
  'other': PlantGrowData(
      category: 'other', daysToHarvestMin: 60, daysToHarvestMax: 90),
};

/// Compute expected harvest date from planted date and category.
/// Returns null for non-harvestable categories (daysToHarvest == 0).
DateTime? estimatedHarvestDate(String category, DateTime plantedDate) {
  final data = plantGrowDataTable[category];
  if (data == null) return null;
  if (data.daysToHarvestEstimate <= 0) return null; // non-harvestable
  return plantedDate.add(Duration(days: data.daysToHarvestEstimate));
}

/// Compute progress fraction (0.0 to 1.0+) from planted date to expected harvest
double harvestProgress(DateTime plantedDate, DateTime? expectedHarvestDate) {
  if (expectedHarvestDate == null) return 0.0;
  final total = expectedHarvestDate.difference(plantedDate).inDays;
  if (total <= 0) return 1.0;
  final elapsed = DateTime.now().difference(plantedDate).inDays;
  return (elapsed / total).clamp(0.0, 1.5); // allow slight overshoot for "overdue"
}

/// Days remaining until expected harvest (negative means overdue)
int? daysUntilHarvest(DateTime? expectedHarvestDate) {
  if (expectedHarvestDate == null) return null;
  return expectedHarvestDate.difference(DateTime.now()).inDays;
}

/// Compute expected harvest date, preferring species-specific data.
/// Falls back to category-level data if species not found.
/// Returns null for non-harvestable plants (daysToHarvest == 0).
DateTime? estimatedHarvestDateForPlant(
    String plantName, String category, DateTime plantedDate) {
  final species = lookupSpecies(plantName);
  if (species != null) {
    if (species.daysToHarvestEstimate <= 0) return null; // non-harvestable
    return plantedDate.add(Duration(days: species.daysToHarvestEstimate));
  }
  return estimatedHarvestDate(category, plantedDate);
}
