import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../seasons/presentation/providers/season_providers.dart';
import '../../../garden/presentation/providers/plant_providers.dart';

// ─── Data models for charts ──────────────────────────────────────

/// One bar in the season comparison chart
class SeasonSummary {
  const SeasonSummary({
    required this.seasonName,
    required this.harvestCount,
    required this.totalQuantity,
    required this.avgQuality,
  });

  final String seasonName;
  final int harvestCount;
  final double totalQuantity;
  final double avgQuality;
}

/// One entry in the "top plants" chart
class PlantHarvestSummary {
  const PlantHarvestSummary({
    required this.plantName,
    required this.harvestCount,
    required this.totalQuantity,
    required this.avgQuality,
  });

  final String plantName;
  final int harvestCount;
  final double totalQuantity;
  final double avgQuality;
}

/// Plant status breakdown for pie chart
class StatusCount {
  const StatusCount({required this.status, required this.count});
  final String status;
  final int count;
}

// ─── Providers ───────────────────────────────────────────────────

/// Season-by-season harvest summaries for bar chart comparison
final seasonSummariesProvider = Provider<AsyncValue<List<SeasonSummary>>>((ref) {
  final seasonsAsync = ref.watch(seasonsStreamProvider);
  final allHarvestsAsync = ref.watch(allHarvestsProvider);

  return seasonsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (seasons) {
      return allHarvestsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (harvests) {
          // Group harvests by season
          final summaries = <SeasonSummary>[];
          for (final season in seasons) {
            final seasonHarvests =
                harvests.where((h) => h.seasonId == season.id).toList();
            if (seasonHarvests.isEmpty) {
              summaries.add(SeasonSummary(
                seasonName: season.name,
                harvestCount: 0,
                totalQuantity: 0,
                avgQuality: 0,
              ));
            } else {
              final totalQty =
                  seasonHarvests.fold<double>(0, (s, h) => s + h.quantity);
              final avgQual =
                  seasonHarvests.fold<double>(0, (s, h) => s + h.quality) /
                      seasonHarvests.length;

              summaries.add(SeasonSummary(
                seasonName: season.name,
                harvestCount: seasonHarvests.length,
                totalQuantity: totalQty,
                avgQuality: avgQual,
              ));
            }
          }
          // Most recent season last (for chart left-to-right reading)
          return AsyncValue.data(summaries.reversed.toList());
        },
      );
    },
  );
});

/// Top plants ranked by total harvest quantity
final topPlantsProvider =
    Provider<AsyncValue<List<PlantHarvestSummary>>>((ref) {
  final plantsAsync = ref.watch(plantsStreamProvider);
  final allHarvestsAsync = ref.watch(allHarvestsProvider);

  return plantsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (plants) {
      return allHarvestsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (harvests) {
          // Build a plant ID → name map from live plants
          final plantNames = <String, String>{};
          for (final p in plants) {
            plantNames[p.id] = p.name;
          }

          // Backfill names from harvest records (survives plant deletion)
          for (final h in harvests) {
            if (!plantNames.containsKey(h.plantId) && h.plantName != null) {
              plantNames[h.plantId] = h.plantName!;
            }
          }

          // Group harvests by plant
          final grouped = <String, List<Harvest>>{};
          for (final h in harvests) {
            grouped.putIfAbsent(h.plantId, () => []).add(h);
          }

          final summaries = grouped.entries.map((entry) {
            final name = plantNames[entry.key] ?? 'Unknown';
            final hList = entry.value;
            final totalQty = hList.fold<double>(0, (s, h) => s + h.quantity);
            final avgQual =
                hList.fold<double>(0, (s, h) => s + h.quality) / hList.length;

            return PlantHarvestSummary(
              plantName: name,
              harvestCount: hList.length,
              totalQuantity: totalQty,
              avgQuality: avgQual,
            );
          }).toList();

          // Sort by total quantity descending, take top 8
          summaries.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
          return AsyncValue.data(summaries.take(8).toList());
        },
      );
    },
  );
});

/// Plant status distribution for pie chart
final plantStatusDistributionProvider =
    Provider<AsyncValue<List<StatusCount>>>((ref) {
  final plantsAsync = ref.watch(plantsStreamProvider);

  return plantsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (plants) {
      final counts = <String, int>{};
      for (final p in plants) {
        counts[p.status] = (counts[p.status] ?? 0) + 1;
      }

      final result = counts.entries
          .map((e) => StatusCount(status: e.key, count: e.value))
          .toList();
      result.sort((a, b) => b.count.compareTo(a.count));

      return AsyncValue.data(result);
    },
  );
});

/// Overall stats across all time
final overallStatsProvider = Provider<AsyncValue<Map<String, dynamic>>>((ref) {
  final plantsAsync = ref.watch(plantsStreamProvider);
  final harvestsAsync = ref.watch(allHarvestsProvider);
  final seasonsAsync = ref.watch(seasonsStreamProvider);

  return plantsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (plants) {
      return harvestsAsync.when(
        loading: () => const AsyncValue.loading(),
        error: (e, st) => AsyncValue.error(e, st),
        data: (harvests) {
          return seasonsAsync.when(
            loading: () => const AsyncValue.loading(),
            error: (e, st) => AsyncValue.error(e, st),
            data: (seasons) {
              final totalQty =
                  harvests.fold<double>(0, (s, h) => s + h.quantity);
              final avgQuality = harvests.isEmpty
                  ? 0.0
                  : harvests.fold<double>(0, (s, h) => s + h.quality) /
                      harvests.length;

              return AsyncValue.data({
                'totalPlants': plants.length,
                'totalHarvests': harvests.length,
                'totalQuantity': totalQty,
                'avgQuality': avgQuality,
                'totalSeasons': seasons.length,
              });
            },
          );
        },
      );
    },
  );
});
