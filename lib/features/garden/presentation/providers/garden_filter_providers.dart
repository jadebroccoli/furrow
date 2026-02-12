import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import 'plant_providers.dart';

// ─── Sort ────────────────────────────────────────────────

enum GardenSortMode {
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  nameAZ('Name A → Z'),
  nameZA('Name Z → A'),
  status('Status');

  const GardenSortMode(this.label);
  final String label;
}

final gardenSortProvider = StateProvider<GardenSortMode>(
  (ref) => GardenSortMode.newestFirst,
);

// ─── Search ──────────────────────────────────────────────

final gardenSearchProvider = StateProvider<String>((ref) => '');

// ─── Category filter ─────────────────────────────────────

final gardenCategoryFilterProvider = StateProvider<Set<String>>(
  (ref) => {},
);

// ─── Status filter ───────────────────────────────────────

final gardenStatusFilterProvider = StateProvider<Set<String>>(
  (ref) => {},
);

// ─── Filtered + sorted plant list ────────────────────────

final filteredPlantsProvider = Provider<AsyncValue<List<Plant>>>((ref) {
  final plantsAsync = ref.watch(plantsStreamProvider);
  final search = ref.watch(gardenSearchProvider).toLowerCase();
  final categories = ref.watch(gardenCategoryFilterProvider);
  final statuses = ref.watch(gardenStatusFilterProvider);
  final sortMode = ref.watch(gardenSortProvider);

  return plantsAsync.whenData((plants) {
    final filtered = plants.where((p) {
      // Search
      if (search.isNotEmpty) {
        final name = p.name.toLowerCase();
        final variety = (p.variety ?? '').toLowerCase();
        final category = p.category.toLowerCase();
        if (!name.contains(search) &&
            !variety.contains(search) &&
            !category.contains(search)) {
          return false;
        }
      }

      // Category filter
      if (categories.isNotEmpty && !categories.contains(p.category)) {
        return false;
      }

      // Status filter
      if (statuses.isNotEmpty && !statuses.contains(p.status)) {
        return false;
      }

      return true;
    }).toList();

    // Sort
    switch (sortMode) {
      case GardenSortMode.newestFirst:
        filtered.sort((a, b) => b.plantedDate.compareTo(a.plantedDate));
      case GardenSortMode.oldestFirst:
        filtered.sort((a, b) => a.plantedDate.compareTo(b.plantedDate));
      case GardenSortMode.nameAZ:
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case GardenSortMode.nameZA:
        filtered.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      case GardenSortMode.status:
        const statusOrder = [
          'planned',
          'seedling',
          'growing',
          'flowering',
          'harvesting',
          'dormant',
          'removed',
        ];
        filtered.sort((a, b) {
          final ai = statusOrder.indexOf(a.status);
          final bi = statusOrder.indexOf(b.status);
          return ai.compareTo(bi);
        });
    }

    return filtered;
  });
});

/// Whether any filter is active (used for badge indicator)
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final search = ref.watch(gardenSearchProvider);
  final categories = ref.watch(gardenCategoryFilterProvider);
  final statuses = ref.watch(gardenStatusFilterProvider);
  final sort = ref.watch(gardenSortProvider);
  return search.isNotEmpty ||
      categories.isNotEmpty ||
      statuses.isNotEmpty ||
      sort != GardenSortMode.newestFirst;
});
