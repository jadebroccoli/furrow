import 'plant_grow_data.dart';
import 'care_tips_data.dart';

/// Species-level plant data for ~75 commonly grown garden plants.
/// Provides accurate harvest timing, watering, sun, and care tips
/// per individual plant species rather than broad category.
class PlantSpeciesInfo {
  const PlantSpeciesInfo({
    required this.name,
    required this.category,
    required this.daysToHarvestMin,
    required this.daysToHarvestMax,
    required this.wateringFrequency,
    required this.sunNeeds,
    required this.tips,
    this.aliases = const [],
  });

  /// Display name: "Tomato"
  final String name;

  /// Must match PlantCategory.name: "vegetable", "herb", etc.
  final String category;

  final int daysToHarvestMin;
  final int daysToHarvestMax;

  /// e.g., "Every 1-2 days (deep watering)"
  final String wateringFrequency;

  /// e.g., "Full sun (6-8 hours)"
  final String sunNeeds;

  /// 3 actionable care tips
  final List<String> tips;

  /// Alternative names for search matching: ["tomatoes", "cherry tomato", ...]
  final List<String> aliases;

  /// Midpoint estimate in days
  int get daysToHarvestEstimate =>
      (daysToHarvestMin + daysToHarvestMax) ~/ 2;

  /// Convert to PlantGrowData for compatibility with existing helpers
  PlantGrowData toGrowData() => PlantGrowData(
        category: category,
        daysToHarvestMin: daysToHarvestMin,
        daysToHarvestMax: daysToHarvestMax,
      );

  /// Convert to CareTips for compatibility with existing display widgets
  CareTips toCareTips() => CareTips(
        category: category,
        wateringFrequency: wateringFrequency,
        sunNeeds: sunNeeds,
        tips: tips,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// SPECIES TABLE — 75 plants keyed by lowercase canonical name
// ═══════════════════════════════════════════════════════════════════════════

const Map<String, PlantSpeciesInfo> plantSpeciesTable = {
  // ─── VEGETABLES (25) ─────────────────────────────────────────────────

  'tomato': PlantSpeciesInfo(
    name: 'Tomato',
    category: 'vegetable',
    daysToHarvestMin: 60,
    daysToHarvestMax: 85,
    wateringFrequency: 'Every 1-2 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Stake or cage plants early to support heavy fruit',
      'Prune suckers for larger tomatoes on indeterminate varieties',
      'Water at the base to prevent leaf diseases',
    ],
    aliases: [
      'tomatoes', 'cherry tomato', 'cherry tomatoes',
      'beefsteak tomato', 'roma tomato', 'grape tomato',
      'heirloom tomato', 'plum tomato',
    ],
  ),

  'bell pepper': PlantSpeciesInfo(
    name: 'Bell Pepper',
    category: 'vegetable',
    daysToHarvestMin: 60,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Wait for full color change for sweeter flavor',
      'Mulch to maintain even soil moisture',
      'Support branches when heavy with fruit',
    ],
    aliases: ['bell peppers', 'pepper', 'peppers', 'sweet pepper', 'capsicum'],
  ),

  'cucumber': PlantSpeciesInfo(
    name: 'Cucumber',
    category: 'vegetable',
    daysToHarvestMin: 50,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Trellis vining types for straighter fruit and easier harvest',
      'Pick regularly to encourage continued production',
      'Avoid wetting foliage to prevent powdery mildew',
    ],
    aliases: ['cucumbers', 'cuke', 'cukes'],
  ),

  'zucchini': PlantSpeciesInfo(
    name: 'Zucchini',
    category: 'vegetable',
    daysToHarvestMin: 45,
    daysToHarvestMax: 65,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest at 6-8 inches for best flavor and texture',
      'Check daily — zucchini grows fast in warm weather',
      'Hand-pollinate if fruit drops early (use a small brush)',
    ],
    aliases: ['zucchinis', 'courgette', 'summer squash'],
  ),

  'winter squash': PlantSpeciesInfo(
    name: 'Winter Squash',
    category: 'vegetable',
    daysToHarvestMin: 80,
    daysToHarvestMax: 110,
    wateringFrequency: 'Every 2-3 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Cure in the sun for 10 days after harvest for longer storage',
      'Limit to 2-3 fruits per vine for larger squash',
      'Slip cardboard under fruit to prevent rot on damp soil',
    ],
    aliases: ['butternut squash', 'acorn squash', 'spaghetti squash', 'squash'],
  ),

  'pumpkin': PlantSpeciesInfo(
    name: 'Pumpkin',
    category: 'vegetable',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Give each plant 50-100 sq ft of room to sprawl',
      'Limit to 2-3 pumpkins per vine for larger fruit',
      'Harvest when skin is hard and stem begins to dry',
    ],
    aliases: ['pumpkins', 'jack o lantern'],
  ),

  'corn': PlantSpeciesInfo(
    name: 'Corn',
    category: 'vegetable',
    daysToHarvestMin: 60,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Plant in blocks of 4+ rows for proper wind pollination',
      'Side-dress with nitrogen when plants are knee-high',
      'Harvest when silks turn brown and kernels release milky juice',
    ],
    aliases: ['sweet corn', 'maize'],
  ),

  'eggplant': PlantSpeciesInfo(
    name: 'Eggplant',
    category: 'vegetable',
    daysToHarvestMin: 65,
    daysToHarvestMax: 85,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest when skin is glossy — dull skin means overripe',
      'Use pruning shears to cut fruit (stems are tough)',
      'Mulch heavily to keep soil warm in cooler climates',
    ],
    aliases: ['eggplants', 'aubergine'],
  ),

  'broccoli': PlantSpeciesInfo(
    name: 'Broccoli',
    category: 'vegetable',
    daysToHarvestMin: 60,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 1-2 days (consistent moisture)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest main head before yellow flowers appear',
      'Leave plant in ground for side shoots after main harvest',
      'Prefers cool weather — plant in spring or fall',
    ],
    aliases: ['brocoli'],
  ),

  'cauliflower': PlantSpeciesInfo(
    name: 'Cauliflower',
    category: 'vegetable',
    daysToHarvestMin: 55,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 1-2 days (consistent moisture)',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Blanch heads by tying outer leaves over the curd',
      'Very sensitive to heat — bolts quickly in warm weather',
      'Consistent watering prevents hollow stems',
    ],
    aliases: [],
  ),

  'cabbage': PlantSpeciesInfo(
    name: 'Cabbage',
    category: 'vegetable',
    daysToHarvestMin: 70,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Harvest when heads feel firm and solid',
      'Mulch to keep soil cool and moist',
      'Watch for cabbage worms — handpick or use row covers',
    ],
    aliases: ['cabbages', 'red cabbage', 'napa cabbage'],
  ),

  'brussels sprouts': PlantSpeciesInfo(
    name: 'Brussels Sprouts',
    category: 'vegetable',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Remove lower leaves as sprouts develop for better air flow',
      'Flavor improves after a light frost',
      'Top the plant 3 weeks before harvest for uniform sprouts',
    ],
    aliases: ['brussel sprouts', 'brussels sprout'],
  ),

  'kale': PlantSpeciesInfo(
    name: 'Kale',
    category: 'vegetable',
    daysToHarvestMin: 50,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Harvest outer leaves first — the plant keeps producing',
      'Flavor sweetens after frost',
      'One of the most cold-hardy garden vegetables',
    ],
    aliases: ['curly kale', 'lacinato kale', 'dinosaur kale'],
  ),

  'spinach': PlantSpeciesInfo(
    name: 'Spinach',
    category: 'vegetable',
    daysToHarvestMin: 35,
    daysToHarvestMax: 50,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Partial to full sun (3-5 hours)',
    tips: [
      'Sow every 2 weeks for continuous harvest',
      'Bolts quickly in heat — grow in spring or fall',
      'Cut-and-come-again harvesting extends production',
    ],
    aliases: [],
  ),

  'lettuce': PlantSpeciesInfo(
    name: 'Lettuce',
    category: 'vegetable',
    daysToHarvestMin: 30,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Partial to full sun (4-6 hours)',
    tips: [
      'Succession plant every 2 weeks for continuous salads',
      'Harvest in morning when leaves are crispest',
      'Provide afternoon shade in warm climates to delay bolting',
    ],
    aliases: ['romaine', 'butter lettuce', 'iceberg', 'leaf lettuce', 'mesclun'],
  ),

  'swiss chard': PlantSpeciesInfo(
    name: 'Swiss Chard',
    category: 'vegetable',
    daysToHarvestMin: 50,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Cut outer stalks at the base — inner leaves keep growing',
      'Both leaves and stems are edible (cook stems longer)',
      'Tolerates both heat and light frost well',
    ],
    aliases: ['chard', 'rainbow chard', 'silverbeet'],
  ),

  'celery': PlantSpeciesInfo(
    name: 'Celery',
    category: 'vegetable',
    daysToHarvestMin: 85,
    daysToHarvestMax: 120,
    wateringFrequency: 'Daily (moisture-loving)',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Needs consistent moisture — never let soil dry out',
      'Blanch stalks by wrapping with paper for milder flavor',
      'Heavy feeder — side-dress with compost monthly',
    ],
    aliases: [],
  ),

  'asparagus': PlantSpeciesInfo(
    name: 'Asparagus',
    category: 'vegetable',
    daysToHarvestMin: 730,
    daysToHarvestMax: 1095,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (8 hours)',
    tips: [
      'Do not harvest the first 2 years — let ferns establish roots',
      'Produces for 15-20 years once established',
      'Stop harvesting when spears are thinner than a pencil',
    ],
    aliases: [],
  ),

  'artichoke': PlantSpeciesInfo(
    name: 'Artichoke',
    category: 'vegetable',
    daysToHarvestMin: 150,
    daysToHarvestMax: 180,
    wateringFrequency: 'Every 2-3 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest buds before they open into flowers',
      'Cut 1-3 inches below the bud with a sharp knife',
      'Mulch heavily in winter for perennial production',
    ],
    aliases: ['artichokes', 'globe artichoke'],
  ),

  'okra': PlantSpeciesInfo(
    name: 'Okra',
    category: 'vegetable',
    daysToHarvestMin: 50,
    daysToHarvestMax: 65,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Harvest pods at 2-3 inches — larger pods get tough',
      'Soak seeds overnight before planting for faster germination',
      'Thrives in hot weather — wait until soil is warm to plant',
    ],
    aliases: [],
  ),

  'cantaloupe': PlantSpeciesInfo(
    name: 'Cantaloupe',
    category: 'vegetable',
    daysToHarvestMin: 75,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Ripe when stem slips easily from the fruit',
      'Reduce watering as fruit ripens for sweeter flavor',
      'Place fruit on straw or cardboard to prevent rot',
    ],
    aliases: ['cantaloupes', 'muskmelon', 'rockmelon', 'melon'],
  ),

  'watermelon': PlantSpeciesInfo(
    name: 'Watermelon',
    category: 'vegetable',
    daysToHarvestMin: 70,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 2-3 days (deep watering)',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Ripe when the ground spot turns from white to creamy yellow',
      'Reduce watering a week before harvest for sweeter fruit',
      'Needs lots of space — 6+ feet between plants',
    ],
    aliases: ['watermelons'],
  ),

  'hot pepper': PlantSpeciesInfo(
    name: 'Hot Pepper',
    category: 'vegetable',
    daysToHarvestMin: 60,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Slight water stress can increase pepper heat level',
      'Wear gloves when harvesting very hot varieties',
      'Peppers get hotter as they ripen from green to red',
    ],
    aliases: [
      'chili pepper', 'chili peppers', 'hot peppers', 'jalapeno',
      'habanero', 'cayenne', 'serrano', 'thai chili',
    ],
  ),

  'kohlrabi': PlantSpeciesInfo(
    name: 'Kohlrabi',
    category: 'vegetable',
    daysToHarvestMin: 45,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Harvest when bulb is 2-3 inches in diameter — larger gets woody',
      'Both the bulb and young leaves are edible',
      'Fast-growing cool-season crop — plant in spring or fall',
    ],
    aliases: [],
  ),

  'bok choy': PlantSpeciesInfo(
    name: 'Bok Choy',
    category: 'vegetable',
    daysToHarvestMin: 40,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Partial to full sun (3-5 hours)',
    tips: [
      'Harvest whole plant or cut outer leaves for continuous harvest',
      'Bolts quickly in warm weather — best in spring or fall',
      'Baby bok choy matures in about 30 days',
    ],
    aliases: ['pak choi', 'pak choy', 'chinese cabbage'],
  ),

  // ─── HERBS (12) ──────────────────────────────────────────────────────

  'basil': PlantSpeciesInfo(
    name: 'Basil',
    category: 'herb',
    daysToHarvestMin: 25,
    daysToHarvestMax: 40,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Pinch off flower buds to extend leaf production',
      'Harvest from the top down to encourage bushier growth',
      'Very frost-sensitive — bring indoors or harvest before first frost',
    ],
    aliases: ['sweet basil', 'thai basil', 'genovese basil'],
  ),

  'cilantro': PlantSpeciesInfo(
    name: 'Cilantro',
    category: 'herb',
    daysToHarvestMin: 20,
    daysToHarvestMax: 35,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Partial to full sun (4-6 hours)',
    tips: [
      'Sow every 2-3 weeks for continuous harvest',
      'Bolts fast in heat — grow in spring, fall, or partial shade',
      'Let some plants bolt to collect coriander seeds',
    ],
    aliases: ['coriander', 'chinese parsley'],
  ),

  'parsley': PlantSpeciesInfo(
    name: 'Parsley',
    category: 'herb',
    daysToHarvestMin: 60,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Cut outer stems first — inner stems continue growing',
      'Soak seeds overnight for faster (but still slow) germination',
      'Biennial — produces leaves year one, flowers year two',
    ],
    aliases: ['flat leaf parsley', 'italian parsley', 'curly parsley'],
  ),

  'dill': PlantSpeciesInfo(
    name: 'Dill',
    category: 'herb',
    daysToHarvestMin: 40,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Direct sow — dill does not transplant well',
      'Let some flower heads go to seed for self-sowing next year',
      'Harvest fronds before flowers open for best flavor',
    ],
    aliases: ['dill weed'],
  ),

  'mint': PlantSpeciesInfo(
    name: 'Mint',
    category: 'herb',
    daysToHarvestMin: 15,
    daysToHarvestMax: 30,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Partial to full sun (3-6 hours)',
    tips: [
      'Grow in a pot — mint spreads aggressively in garden beds',
      'Cut stems regularly to prevent legginess',
      'Pinch flowers to keep foliage production strong',
    ],
    aliases: ['peppermint', 'spearmint', 'chocolate mint'],
  ),

  'rosemary': PlantSpeciesInfo(
    name: 'Rosemary',
    category: 'herb',
    daysToHarvestMin: 80,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 5-7 days (drought tolerant)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Prefers dry conditions — overwatering causes root rot',
      'Prune after flowering to maintain shape',
      'Can overwinter indoors on a sunny windowsill',
    ],
    aliases: [],
  ),

  'thyme': PlantSpeciesInfo(
    name: 'Thyme',
    category: 'herb',
    daysToHarvestMin: 70,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 5-7 days (drought tolerant)',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Trim regularly but never more than one-third at a time',
      'Excellent drainage is essential — mix sand into soil',
      'Harvest just before flowers open for peak oil content',
    ],
    aliases: ['lemon thyme', 'english thyme'],
  ),

  'oregano': PlantSpeciesInfo(
    name: 'Oregano',
    category: 'herb',
    daysToHarvestMin: 60,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Flavor intensifies when plants are slightly drought-stressed',
      'Cut back by two-thirds after flowering for fresh growth',
      'Spreads readily — contain in pots or divide yearly',
    ],
    aliases: ['greek oregano', 'italian oregano'],
  ),

  'sage': PlantSpeciesInfo(
    name: 'Sage',
    category: 'herb',
    daysToHarvestMin: 75,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Prune woody stems in spring to rejuvenate the plant',
      'Avoid overhead watering — sage is prone to mildew',
      'Harvest lightly the first year to establish strong roots',
    ],
    aliases: ['garden sage', 'common sage'],
  ),

  'chives': PlantSpeciesInfo(
    name: 'Chives',
    category: 'herb',
    daysToHarvestMin: 30,
    daysToHarvestMax: 45,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Cut to 2 inches above soil — regrows multiple times per season',
      'Purple flowers are edible and attract pollinators',
      'Divide clumps every 3 years to keep vigorous',
    ],
    aliases: ['garlic chives'],
  ),

  'lavender': PlantSpeciesInfo(
    name: 'Lavender',
    category: 'herb',
    daysToHarvestMin: 90,
    daysToHarvestMax: 200,
    wateringFrequency: 'Every 7-10 days (drought tolerant)',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Needs excellent drainage — add gravel to planting hole',
      'Prune after flowering to prevent woody, leggy growth',
      'Harvest flower spikes when about half the buds have opened',
    ],
    aliases: ['english lavender', 'french lavender'],
  ),

  'lemongrass': PlantSpeciesInfo(
    name: 'Lemongrass',
    category: 'herb',
    daysToHarvestMin: 75,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest by cutting stalks at ground level when 12+ inches tall',
      'Bring indoors before frost — not cold-hardy below 40°F',
      'Divide clumps yearly to keep plants productive',
    ],
    aliases: [],
  ),

  // ─── FRUITS (10) ─────────────────────────────────────────────────────

  'strawberry': PlantSpeciesInfo(
    name: 'Strawberry',
    category: 'fruit',
    daysToHarvestMin: 60,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Pinch off first-year flowers on June-bearing types for stronger roots',
      'Mulch with straw to keep berries clean and prevent rot',
      'Replace plants every 3 years for best production',
    ],
    aliases: ['strawberries'],
  ),

  'blueberry': PlantSpeciesInfo(
    name: 'Blueberry',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 730,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Requires acidic soil (pH 4.5-5.5) — use sulfur to lower pH',
      'Plant 2+ varieties for better cross-pollination and yield',
      'Do not harvest first 2 years — remove flowers to build roots',
    ],
    aliases: ['blueberries'],
  ),

  'raspberry': PlantSpeciesInfo(
    name: 'Raspberry',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 540,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Prune spent canes to ground after fruiting',
      'Trellis canes for easier harvest and better air circulation',
      'Everbearing types produce on first-year canes in fall',
    ],
    aliases: ['raspberries'],
  ),

  'blackberry': PlantSpeciesInfo(
    name: 'Blackberry',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 540,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Tip-prune new canes in summer for branching and more fruit',
      'Berries do not ripen further after picking',
      'Train on trellises to manage thorny canes',
    ],
    aliases: ['blackberries'],
  ),

  'grape': PlantSpeciesInfo(
    name: 'Grape',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 1095,
    wateringFrequency: 'Every 3-5 days (deep watering)',
    sunNeeds: 'Full sun (7-8 hours)',
    tips: [
      'Prune heavily in late winter — grapes fruit on new growth',
      'Thin clusters for larger, sweeter grapes',
      'Provide strong trellising — mature vines are heavy',
    ],
    aliases: ['grapes', 'grapevine'],
  ),

  'fig': PlantSpeciesInfo(
    name: 'Fig',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 730,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (8 hours)',
    tips: [
      'Figs are ripe when they droop and feel soft at the neck',
      'In cold climates, wrap trees or grow in containers',
      'Do not over-fertilize — too much nitrogen reduces fruiting',
    ],
    aliases: ['figs', 'fig tree'],
  ),

  'lemon': PlantSpeciesInfo(
    name: 'Lemon',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 1095,
    wateringFrequency: 'Every 3-5 days (deep watering)',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Feed with citrus fertilizer 3 times per year',
      'Bring potted trees indoors when temps drop below 50°F',
      'Yellow color does not always indicate ripeness — feel for softness',
    ],
    aliases: ['lemons', 'meyer lemon', 'lemon tree'],
  ),

  'lime': PlantSpeciesInfo(
    name: 'Lime',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 1095,
    wateringFrequency: 'Every 3-5 days (deep watering)',
    sunNeeds: 'Full sun (8+ hours)',
    tips: [
      'Limes are harvested green — they turn yellow when overripe',
      'Protect from cold — less cold-hardy than lemons',
      'Feed with citrus-specific fertilizer regularly',
    ],
    aliases: ['limes', 'key lime', 'lime tree'],
  ),

  'peach': PlantSpeciesInfo(
    name: 'Peach',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 1095,
    wateringFrequency: 'Every 3-5 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Thin fruit to 6-8 inches apart for larger peaches',
      'Requires 200-1000 chill hours depending on variety',
      'Prune to an open-center shape for air circulation',
    ],
    aliases: ['peaches', 'nectarine', 'nectarines', 'peach tree'],
  ),

  'apple': PlantSpeciesInfo(
    name: 'Apple',
    category: 'fruit',
    daysToHarvestMin: 365,
    daysToHarvestMax: 1825,
    wateringFrequency: 'Every 3-7 days (deep watering)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Most apples need a second variety nearby for pollination',
      'Thin fruit clusters to 1 apple per spur for larger fruit',
      'Prune annually in late winter for health and productivity',
    ],
    aliases: ['apples', 'apple tree', 'crabapple'],
  ),

  // ─── FLOWERS (8) ─────────────────────────────────────────────────────

  'sunflower': PlantSpeciesInfo(
    name: 'Sunflower',
    category: 'flower',
    daysToHarvestMin: 55,
    daysToHarvestMax: 75,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Direct sow after last frost — sunflowers dislike transplanting',
      'Stake tall varieties to prevent toppling in wind',
      'Leave spent heads for birds or harvest seeds when back turns brown',
    ],
    aliases: ['sunflowers'],
  ),

  'marigold': PlantSpeciesInfo(
    name: 'Marigold',
    category: 'flower',
    daysToHarvestMin: 45,
    daysToHarvestMax: 65,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Plant near vegetables — marigolds repel many garden pests',
      'Deadhead regularly for continuous blooming all season',
      'Let some flowers go to seed for free plants next year',
    ],
    aliases: ['marigolds', 'french marigold', 'african marigold'],
  ),

  'zinnia': PlantSpeciesInfo(
    name: 'Zinnia',
    category: 'flower',
    daysToHarvestMin: 45,
    daysToHarvestMax: 65,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'The more you cut, the more they bloom — great for bouquets',
      'Space plants for air circulation to prevent powdery mildew',
      'Direct sow in warm soil — they germinate in 4-7 days',
    ],
    aliases: ['zinnias'],
  ),

  'petunia': PlantSpeciesInfo(
    name: 'Petunia',
    category: 'flower',
    daysToHarvestMin: 55,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Pinch back leggy stems mid-summer for a second flush',
      'Feed weekly with liquid fertilizer for prolific blooms',
      'Excellent for containers, hanging baskets, and borders',
    ],
    aliases: ['petunias', 'wave petunia'],
  ),

  'dahlia': PlantSpeciesInfo(
    name: 'Dahlia',
    category: 'flower',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Pinch the center shoot when 12 inches tall for more blooms',
      'Stake tall varieties at planting time to avoid root damage later',
      'Dig up tubers after first frost and store over winter',
    ],
    aliases: ['dahlias'],
  ),

  'cosmos': PlantSpeciesInfo(
    name: 'Cosmos',
    category: 'flower',
    daysToHarvestMin: 50,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 3-5 days (drought tolerant)',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Thrives in poor soil — too much fertilizer reduces flowers',
      'Self-sows freely — let spent flowers drop for next year',
      'Attracts butterflies and beneficial pollinators',
    ],
    aliases: [],
  ),

  'nasturtium': PlantSpeciesInfo(
    name: 'Nasturtium',
    category: 'flower',
    daysToHarvestMin: 35,
    daysToHarvestMax: 55,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Completely edible — flowers, leaves, and seeds all taste peppery',
      'Do not fertilize — rich soil produces leaves over flowers',
      'Plant near vegetables as a trap crop for aphids',
    ],
    aliases: ['nasturtiums'],
  ),

  'sweet pea': PlantSpeciesInfo(
    name: 'Sweet Pea',
    category: 'flower',
    daysToHarvestMin: 60,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Soak seeds overnight before planting for faster germination',
      'Pick flowers frequently to keep the plant blooming',
      'Provide netting or string for vines to climb',
    ],
    aliases: ['sweet peas', 'sweetpea'],
  ),

  // ─── LEGUMES (8) ─────────────────────────────────────────────────────

  'green bean': PlantSpeciesInfo(
    name: 'Green Bean',
    category: 'legume',
    daysToHarvestMin: 50,
    daysToHarvestMax: 65,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Pick beans when young and firm for best texture',
      'Bush types are easier — pole types yield more over time',
      'Avoid harvesting when plants are wet to prevent disease',
    ],
    aliases: ['green beans', 'string bean', 'string beans', 'bush bean', 'pole bean'],
  ),

  'snap pea': PlantSpeciesInfo(
    name: 'Snap Pea',
    category: 'legume',
    daysToHarvestMin: 55,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Harvest when pods are plump but before peas get starchy',
      'Provide trellising for climbing varieties',
      'Cool-season crop — plant as early as soil can be worked',
    ],
    aliases: ['snap peas', 'sugar snap', 'sugar snap pea'],
  ),

  'snow pea': PlantSpeciesInfo(
    name: 'Snow Pea',
    category: 'legume',
    daysToHarvestMin: 55,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Harvest when pods are flat — before peas swell inside',
      'Eat pods whole — both pod and pea are edible',
      'Plant in early spring or fall for best performance',
    ],
    aliases: ['snow peas', 'pea', 'peas', 'chinese pea'],
  ),

  'lima bean': PlantSpeciesInfo(
    name: 'Lima Bean',
    category: 'legume',
    daysToHarvestMin: 65,
    daysToHarvestMax: 90,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Needs warm soil (65°F+) to germinate — do not rush planting',
      'Harvest when pods are plump and bright green',
      'Can be dried on the vine for storage beans',
    ],
    aliases: ['lima beans', 'butter bean', 'butter beans'],
  ),

  'black bean': PlantSpeciesInfo(
    name: 'Black Bean',
    category: 'legume',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Let pods dry completely on the plant before harvesting',
      'Shell beans and dry further indoors for storage',
      'Like all legumes, fixes nitrogen — great rotation crop',
    ],
    aliases: ['black beans', 'black turtle bean'],
  ),

  'chickpea': PlantSpeciesInfo(
    name: 'Chickpea',
    category: 'legume',
    daysToHarvestMin: 90,
    daysToHarvestMax: 110,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Drought tolerant once established — reduce water during pod fill',
      'Harvest when leaves start to wither and pods turn tan',
      'Each pod contains only 1-2 beans — plant generously',
    ],
    aliases: ['chickpeas', 'garbanzo', 'garbanzo bean'],
  ),

  'lentil': PlantSpeciesInfo(
    name: 'Lentil',
    category: 'legume',
    daysToHarvestMin: 80,
    daysToHarvestMax: 110,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest when lower pods are brown and upper pods are still green',
      'Pull whole plants and hang upside down to dry',
      'Cool-season crop — plant in early spring',
    ],
    aliases: ['lentils'],
  ),

  'soybean': PlantSpeciesInfo(
    name: 'Soybean',
    category: 'legume',
    daysToHarvestMin: 80,
    daysToHarvestMax: 100,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Harvest edamame when pods are green and plump',
      'For dry soybeans, let pods turn brown on the plant',
      'Inoculate seeds with soybean-specific rhizobia for best yield',
    ],
    aliases: ['soybeans', 'edamame', 'soy bean'],
  ),

  // ─── ROOT VEGETABLES (12) ────────────────────────────────────────────

  'carrot': PlantSpeciesInfo(
    name: 'Carrot',
    category: 'root',
    daysToHarvestMin: 60,
    daysToHarvestMax: 80,
    wateringFrequency: 'Every 2-3 days (consistent moisture)',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Keep soil loose and rock-free for straight roots',
      'Thin seedlings to 2-3 inches apart for proper sizing',
      'Flavor sweetens after light frost',
    ],
    aliases: ['carrots'],
  ),

  'potato': PlantSpeciesInfo(
    name: 'Potato',
    category: 'root',
    daysToHarvestMin: 70,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Hill soil around stems as plants grow for more tubers',
      'Stop watering when foliage yellows — harvest 2 weeks later',
      'Cure in a dark place for 2 weeks before storing',
    ],
    aliases: ['potatoes', 'spud', 'russet', 'yukon gold'],
  ),

  'sweet potato': PlantSpeciesInfo(
    name: 'Sweet Potato',
    category: 'root',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Start slips from a sprouted sweet potato 6-8 weeks early',
      'Needs warm soil (65°F+) and a long growing season',
      'Cure at 80-85°F for 10 days to develop sweetness',
    ],
    aliases: ['sweet potatoes', 'yam', 'yams'],
  ),

  'onion': PlantSpeciesInfo(
    name: 'Onion',
    category: 'root',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Choose long-day or short-day varieties based on latitude',
      'Stop watering when tops start to fall over',
      'Cure for 2-3 weeks in a dry, airy spot before storing',
    ],
    aliases: ['onions', 'yellow onion', 'red onion', 'white onion'],
  ),

  'garlic': PlantSpeciesInfo(
    name: 'Garlic',
    category: 'root',
    daysToHarvestMin: 180,
    daysToHarvestMax: 270,
    wateringFrequency: 'Every 3-5 days',
    sunNeeds: 'Full sun (6-8 hours)',
    tips: [
      'Plant individual cloves in fall for summer harvest',
      'Harvest when lower 2-3 leaves are brown but upper leaves are green',
      'Cut scapes (curly flower stems) for bonus garlic-flavored ingredient',
    ],
    aliases: ['garlic cloves', 'hardneck garlic', 'softneck garlic'],
  ),

  'beet': PlantSpeciesInfo(
    name: 'Beet',
    category: 'root',
    daysToHarvestMin: 50,
    daysToHarvestMax: 70,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Both roots and greens are edible — harvest greens early',
      'Thin to 3-4 inches apart for round, well-formed roots',
      'Harvest at golf-ball size for tender texture',
    ],
    aliases: ['beets', 'beetroot'],
  ),

  'radish': PlantSpeciesInfo(
    name: 'Radish',
    category: 'root',
    daysToHarvestMin: 22,
    daysToHarvestMax: 35,
    wateringFrequency: 'Every 1-2 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'One of the fastest vegetables — great for impatient gardeners',
      'Do not let them get too large or they turn pithy and hot',
      'Perfect for succession sowing every 2 weeks',
    ],
    aliases: ['radishes', 'daikon', 'french breakfast radish'],
  ),

  'turnip': PlantSpeciesInfo(
    name: 'Turnip',
    category: 'root',
    daysToHarvestMin: 40,
    daysToHarvestMax: 60,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Harvest when roots are 2-3 inches — larger turnips get woody',
      'Both roots and greens are nutritious and edible',
      'Spring and fall crops — bolts in summer heat',
    ],
    aliases: ['turnips'],
  ),

  'parsnip': PlantSpeciesInfo(
    name: 'Parsnip',
    category: 'root',
    daysToHarvestMin: 100,
    daysToHarvestMax: 130,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full to partial sun (4-6 hours)',
    tips: [
      'Extremely slow to germinate — be patient (2-3 weeks)',
      'Flavor dramatically improves after hard frost',
      'Can be left in the ground all winter and harvested as needed',
    ],
    aliases: ['parsnips'],
  ),

  'ginger': PlantSpeciesInfo(
    name: 'Ginger',
    category: 'root',
    daysToHarvestMin: 240,
    daysToHarvestMax: 300,
    wateringFrequency: 'Every 1-2 days (keep moist)',
    sunNeeds: 'Partial sun (2-5 hours)',
    tips: [
      'Plant a fresh rhizome from the grocery store with visible buds',
      'Prefers warm, humid conditions — great for containers indoors',
      'Harvest baby ginger at 4 months or full ginger at 8-10 months',
    ],
    aliases: ['ginger root'],
  ),

  'leek': PlantSpeciesInfo(
    name: 'Leek',
    category: 'root',
    daysToHarvestMin: 100,
    daysToHarvestMax: 130,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Blanch the stems by hilling soil around them as they grow',
      'Very cold-hardy — can be harvested well into winter',
      'Start seeds indoors 10-12 weeks before transplanting',
    ],
    aliases: ['leeks'],
  ),

  'shallot': PlantSpeciesInfo(
    name: 'Shallot',
    category: 'root',
    daysToHarvestMin: 90,
    daysToHarvestMax: 120,
    wateringFrequency: 'Every 2-3 days',
    sunNeeds: 'Full sun (6 hours)',
    tips: [
      'Plant individual bulbs — each one multiplies into a cluster',
      'Harvest when tops fall over and turn brown',
      'Cure like onions in a dry, well-ventilated area',
    ],
    aliases: ['shallots'],
  ),

  // ─── HOUSEPLANTS (10) ────────────────────────────────────────────────

  'pothos': PlantSpeciesInfo(
    name: 'Pothos',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 7-10 days (let soil dry between)',
    sunNeeds: 'Low to medium indirect light',
    tips: [
      'One of the easiest houseplants — tolerates neglect well',
      'Trim leggy vines to encourage fuller, bushier growth',
      'Propagate easily by placing stem cuttings in water',
    ],
    aliases: ['golden pothos', 'devil\'s ivy', 'devils ivy', 'epipremnum'],
  ),

  'snake plant': PlantSpeciesInfo(
    name: 'Snake Plant',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 14-21 days (very drought tolerant)',
    sunNeeds: 'Low to bright indirect light',
    tips: [
      'Overwatering is the #1 killer — err on the side of dry',
      'Excellent air purifier — great for bedrooms',
      'Propagate by dividing pups or rooting leaf cuttings',
    ],
    aliases: ['sansevieria', 'mother in law tongue', 'dracaena trifasciata'],
  ),

  'monstera': PlantSpeciesInfo(
    name: 'Monstera',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 7-10 days',
    sunNeeds: 'Bright indirect light',
    tips: [
      'Provide a moss pole or trellis for climbing support',
      'Fenestrations (leaf holes) develop with age and good light',
      'Wipe leaves monthly to remove dust and improve light absorption',
    ],
    aliases: ['monstera deliciosa', 'swiss cheese plant'],
  ),

  'spider plant': PlantSpeciesInfo(
    name: 'Spider Plant',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 7-10 days',
    sunNeeds: 'Bright indirect light',
    tips: [
      'Produces baby "spiderettes" that can be propagated easily',
      'Brown tips usually mean the water has too much fluoride — use filtered',
      'Very resilient and forgiving of irregular watering',
    ],
    aliases: ['spider plants', 'chlorophytum', 'airplane plant'],
  ),

  'peace lily': PlantSpeciesInfo(
    name: 'Peace Lily',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 5-7 days',
    sunNeeds: 'Low to medium indirect light',
    tips: [
      'Droops dramatically when thirsty — perks right back up after watering',
      'One of the best low-light bloomers for indoor spaces',
      'Wipe leaves regularly to keep them glossy and dust-free',
    ],
    aliases: ['spathiphyllum'],
  ),

  'succulent': PlantSpeciesInfo(
    name: 'Succulent',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 10-14 days (soak and dry method)',
    sunNeeds: 'Bright direct to indirect light (4-6 hours)',
    tips: [
      'Use fast-draining cactus/succulent soil mix',
      'Water deeply but infrequently — let soil dry completely',
      'Stretching (etiolation) means the plant needs more light',
    ],
    aliases: ['succulents', 'echeveria', 'sempervivum', 'hen and chicks'],
  ),

  'cactus': PlantSpeciesInfo(
    name: 'Cactus',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 14-30 days (minimal water)',
    sunNeeds: 'Bright direct light (6+ hours)',
    tips: [
      'Most cacti need a dry winter rest period for spring blooms',
      'Use a gritty, fast-draining soil with extra perlite',
      'Handle with tongs or folded newspaper to avoid spines',
    ],
    aliases: ['cacti', 'prickly pear', 'barrel cactus'],
  ),

  'fiddle leaf fig': PlantSpeciesInfo(
    name: 'Fiddle Leaf Fig',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 7-10 days',
    sunNeeds: 'Bright indirect light (6 hours)',
    tips: [
      'Very sensitive to drafts and temperature changes — find a spot and commit',
      'Brown spots often mean overwatering or inconsistent watering',
      'Rotate quarterly for even growth on all sides',
    ],
    aliases: ['fiddle leaf', 'ficus lyrata', 'flf'],
  ),

  'rubber plant': PlantSpeciesInfo(
    name: 'Rubber Plant',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 7-14 days',
    sunNeeds: 'Medium to bright indirect light',
    tips: [
      'Wipe large leaves with a damp cloth to keep them shiny',
      'Prune to control size and encourage branching',
      'Tolerates lower light but grows slower and may lose variegation',
    ],
    aliases: ['ficus elastica', 'rubber tree', 'rubber fig'],
  ),

  'aloe vera': PlantSpeciesInfo(
    name: 'Aloe Vera',
    category: 'houseplant',
    daysToHarvestMin: 0,
    daysToHarvestMax: 0,
    wateringFrequency: 'Every 14-21 days (drought tolerant)',
    sunNeeds: 'Bright indirect to direct light',
    tips: [
      'Gel from inner leaves soothes minor burns and skin irritation',
      'Pups (baby plants) can be separated and repotted',
      'Overwatering causes root rot — always use well-draining soil',
    ],
    aliases: ['aloe'],
  ),
};

// ═══════════════════════════════════════════════════════════════════════════
// LOOKUP & SEARCH FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════════

/// Lazily-built reverse-index: alias (lowercase) → canonical species key
late final Map<String, String> _aliasIndex = _buildAliasIndex();

Map<String, String> _buildAliasIndex() {
  final index = <String, String>{};
  for (final entry in plantSpeciesTable.entries) {
    index[entry.key] = entry.key;
    index[entry.value.name.toLowerCase()] = entry.key;
    for (final alias in entry.value.aliases) {
      index[alias.toLowerCase()] = entry.key;
    }
  }
  return index;
}

/// Look up species info by plant name.
/// Tries: exact key → alias → substring match → null (caller falls back to category).
PlantSpeciesInfo? lookupSpecies(String plantName) {
  final normalized = plantName.trim().toLowerCase();
  if (normalized.isEmpty) return null;

  // 1. Exact key match
  final exact = plantSpeciesTable[normalized];
  if (exact != null) return exact;

  // 2. Alias index match
  final aliasKey = _aliasIndex[normalized];
  if (aliasKey != null) return plantSpeciesTable[aliasKey];

  // 3. Substring: input contains a known species key or vice-versa
  //    e.g., "Cherry Tomato" contains "tomato" → matches tomato entry
  for (final entry in plantSpeciesTable.entries) {
    if (normalized.contains(entry.key) || entry.key.contains(normalized)) {
      return entry.value;
    }
  }

  return null;
}

/// Return species that match a search query (for autocomplete).
/// Prefix matches appear first, then substring matches.
List<PlantSpeciesInfo> searchSpecies(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final prefixMatches = <PlantSpeciesInfo>[];
  final containsMatches = <PlantSpeciesInfo>[];

  for (final info in plantSpeciesTable.values) {
    final nameLower = info.name.toLowerCase();
    if (nameLower.startsWith(q)) {
      prefixMatches.add(info);
    } else if (nameLower.contains(q)) {
      containsMatches.add(info);
    } else if (info.aliases.any((a) => a.toLowerCase().contains(q))) {
      containsMatches.add(info);
    }
  }

  return [...prefixMatches, ...containsMatches];
}
