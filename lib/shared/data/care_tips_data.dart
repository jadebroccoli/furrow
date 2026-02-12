import 'plant_species_data.dart';

/// Care recommendations per plant category
class CareTips {
  const CareTips({
    required this.category,
    required this.wateringFrequency,
    required this.sunNeeds,
    required this.tips,
  });

  final String category;
  final String wateringFrequency;
  final String sunNeeds;
  final List<String> tips;
}

/// Lookup table — keys match PlantCategory.name strings stored in the database
const Map<String, CareTips> careTipsTable = {
  'vegetable': CareTips(
    category: 'vegetable',
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Mulch around plants to retain moisture',
      'Rotate crops yearly to prevent soil depletion',
      'Side-dress with compost mid-season',
    ],
  ),
  'herb': CareTips(
    category: 'herb',
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (4-6 hours)',
    tips: [
      'Pinch back regularly to encourage bushy growth',
      'Harvest in the morning for best flavor',
      'Most herbs prefer well-drained soil',
    ],
  ),
  'fruit': CareTips(
    category: 'fruit',
    wateringFrequency: 'Every 2-3 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Thin fruit clusters for larger individual fruits',
      'Support heavy branches to prevent breaking',
      'Feed with potassium-rich fertilizer when fruiting',
    ],
  ),
  'flower': CareTips(
    category: 'flower',
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-8 hours)',
    tips: [
      'Deadhead spent blooms to encourage new flowers',
      'Group by water needs for efficient care',
      'Add bone meal for stronger root development',
    ],
  ),
  'legume': CareTips(
    category: 'legume',
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Inoculate seeds with nitrogen-fixing bacteria',
      'Provide trellising for climbing varieties',
      'Leave roots in soil after harvest to enrich nitrogen',
    ],
  ),
  'root': CareTips(
    category: 'root',
    wateringFrequency: 'Every 2-3 days (consistent moisture)',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Keep soil loose and rock-free for straight growth',
      'Thin seedlings early to avoid crowding',
      'Avoid fresh manure which can cause forking',
    ],
  ),
  'houseplant': CareTips(
    category: 'houseplant',
    wateringFrequency: 'Every 7-10 days',
    sunNeeds: 'Indirect light (varies by species)',
    tips: [
      'Check soil moisture before watering — most houseplants prefer drying out slightly between waterings',
      'Wipe leaves periodically to remove dust and improve light absorption',
      'Rotate pots quarterly for even growth toward light sources',
    ],
  ),
  'other': CareTips(
    category: 'other',
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Varies',
    tips: [
      'Research specific needs for this plant type',
      'Monitor soil moisture regularly',
      'Adjust care based on observed growth patterns',
    ],
  ),
};

/// Look up care tips, preferring species-specific data.
/// Falls back to category-level data if species not found.
CareTips? careTipsForPlant(String plantName, String category) {
  final species = lookupSpecies(plantName);
  if (species != null) return species.toCareTips();
  return careTipsTable[category];
}
