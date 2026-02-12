import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/theme/color_schemes.dart';
import '../../../../core/database/app_database.dart';
import '../../../garden/domain/entities/plant.dart' show isHarvestable;
import '../../../garden/presentation/providers/plant_providers.dart';
import '../../../garden/presentation/widgets/plant_card.dart';
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../providers/season_providers.dart';

/// Season detail screen — shows plants and harvests for a specific season.
/// Navigated to by tapping a season card on the Seasons tab.
class SeasonDetailScreen extends ConsumerWidget {
  const SeasonDetailScreen({
    super.key,
    required this.seasonId,
  });

  final String seasonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final seasonsAsync = ref.watch(seasonsStreamProvider);
    final plantsAsync = ref.watch(plantsBySeasonProvider(seasonId));
    final harvestsAsync = ref.watch(harvestsBySeasonProvider(seasonId));
    final allPlantsAsync = ref.watch(plantsStreamProvider);
    final isPro = ref.watch(isProProvider);
    final dateFormat = DateFormat('MMM d, yyyy');

    // Find the season from the list
    final season = seasonsAsync.valueOrNull
        ?.where((s) => s.id == seasonId)
        .firstOrNull;

    if (season == null) {
      return Scaffold(
        appBar: AppBar(),
        body: seasonsAsync.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const Center(child: Text('Season not found')),
      );
    }

    final duration = (season.endDate ?? DateTime.now())
        .difference(season.startDate)
        .inDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(season.name),
        actions: [
          if (season.isActive)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color:
                    FurrowColors.seedlingGreen.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: FurrowColors.seedlingGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ─── Season info header ──────────────────────────────
          _SeasonInfoHeader(
            season: season,
            duration: duration,
            dateFormat: dateFormat,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 24),

          // ─── Plants section ──────────────────────────────────
          _SectionHeader(
            icon: Icons.yard,
            title: 'Plants',
            count: plantsAsync.valueOrNull?.length,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          plantsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (plants) {
              if (plants.isEmpty) {
                return _EmptySection(
                  icon: Icons.yard_outlined,
                  message: 'No plants assigned to this season yet',
                  hint:
                      'Assign plants to a season when adding them from the Garden tab.',
                  theme: theme,
                  colorScheme: colorScheme,
                );
              }

              return Column(
                children: plants.map((plant) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PlantCard(
                      name: plant.name,
                      variety: plant.variety,
                      status: plant.status,
                      plantedDate: dateFormat.format(plant.plantedDate),
                      category: plant.category,
                      photoUrl: plant.photoUrl,
                      plantedDateRaw: plant.plantedDate,
                      expectedHarvestDate: plant.expectedHarvestDate,
                      showProgress:
                          isPro && isHarvestable(plant.category),
                      onTap: () => context.push('/plant/${plant.id}'),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // ─── Harvests section ────────────────────────────────
          _SectionHeader(
            icon: Icons.agriculture,
            title: 'Harvests',
            count: harvestsAsync.valueOrNull?.length,
            theme: theme,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 8),
          harvestsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Text('Error: $e'),
            data: (harvests) {
              if (harvests.isEmpty) {
                return _EmptySection(
                  icon: Icons.agriculture_outlined,
                  message: 'No harvests logged yet',
                  hint:
                      'Log harvests from individual plant detail pages.',
                  theme: theme,
                  colorScheme: colorScheme,
                );
              }

              // Summary stat chips
              final totalQty = harvests.fold<double>(
                  0, (sum, h) => sum + h.quantity);
              final avgQuality = harvests.fold<double>(
                      0, (sum, h) => sum + h.quality) /
                  harvests.length;

              // Plant name lookup map
              final allPlants = allPlantsAsync.valueOrNull ?? [];
              final plantNameMap = {
                for (final p in allPlants) p.id: p.name,
              };

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat chips row
                  Row(
                    children: [
                      _StatChip(
                        icon: Icons.agriculture,
                        label: '${harvests.length} harvests',
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.scale,
                        label: '${totalQty.toStringAsFixed(1)} total',
                        color: FurrowColors.harvestGold,
                      ),
                      const SizedBox(width: 8),
                      _StatChip(
                        icon: Icons.star,
                        label:
                            '${avgQuality.toStringAsFixed(1)} avg',
                        color: const Color(0xFFFF8A00),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Individual harvest entries
                  ...harvests.map((h) => _HarvestRow(
                        harvest: h,
                        plantName:
                            h.plantName ?? plantNameMap[h.plantId] ?? 'Unknown',
                        dateFormat: dateFormat,
                        theme: theme,
                        colorScheme: colorScheme,
                      )),
                ],
              );
            },
          ),

          // ─── Pro upsell (free tier only) ─────────────────────
          if (!isPro) ...[
            const SizedBox(height: 24),
            _ProUpsellCard(
              theme: theme,
              colorScheme: colorScheme,
              onTap: () => context.push(
                  '/paywall?feature=Unlock%20season%20analytics'),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────

/// Header showing season date range + duration
class _SeasonInfoHeader extends StatelessWidget {
  const _SeasonInfoHeader({
    required this.season,
    required this.duration,
    required this.dateFormat,
    required this.theme,
    required this.colorScheme,
  });

  final Season season;
  final int duration;
  final DateFormat dateFormat;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final dateRange = season.endDate != null
        ? '${dateFormat.format(season.startDate)} — ${dateFormat.format(season.endDate!)}'
        : 'Started ${dateFormat.format(season.startDate)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today,
              size: 20, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateRange,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$duration days',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header with icon, title, and optional count
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    this.count,
    required this.theme,
    required this.colorScheme,
  });

  final IconData icon;
  final String title;
  final int? count;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleMedium),
        if (count != null) ...[
          const SizedBox(width: 6),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Empty state for a section
class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.icon,
    required this.message,
    required this.hint,
    required this.theme,
    required this.colorScheme,
  });

  final IconData icon;
  final String message;
  final String hint;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Individual harvest entry row
class _HarvestRow extends StatelessWidget {
  const _HarvestRow({
    required this.harvest,
    required this.plantName,
    required this.dateFormat,
    required this.theme,
    required this.colorScheme,
  });

  final Harvest harvest;
  final String plantName;
  final DateFormat dateFormat;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            // Plant name + date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plantName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dateFormat.format(harvest.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Quantity
            Text(
              '${harvest.quantity.toStringAsFixed(1)} ${harvest.unit}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),

            // Quality stars
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < harvest.quality ? Icons.star : Icons.star_border,
                  size: 14,
                  color: i < harvest.quality
                      ? const Color(0xFFFF8A00)
                      : colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat chip — matches the pattern used in seasons_screen.dart
class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Pro upsell card for free-tier users
class _ProUpsellCard extends StatelessWidget {
  const _ProUpsellCard({
    required this.theme,
    required this.colorScheme,
    required this.onTap,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.bar_chart_rounded,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Season Analytics',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Compare seasons, track top producers, and export data with Furrow Pro.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
