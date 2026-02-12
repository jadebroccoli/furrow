import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../../core/database/app_database.dart';
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../../../garden/presentation/providers/plant_providers.dart';
import '../providers/season_providers.dart';

/// Seasons screen - Tab 4
/// Shows list of seasons with harvest summaries
class SeasonsScreen extends ConsumerWidget {
  const SeasonsScreen({super.key});

  void _showCreateSeasonDialog(BuildContext context, WidgetRef ref) {
    // ─── Free tier season limit check ─────────────────────
    final isPro = ref.read(isProProvider);
    final seasons = ref.read(seasonsStreamProvider).value ?? [];
    if (!isPro && seasons.length >= AppConstants.freeSeasonLimit) {
      context.push('/paywall?feature=Unlock%20unlimited%20seasons');
      return;
    }

    final nameController = TextEditingController(
      text: 'Spring ${DateTime.now().year}',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Season'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Season Name',
                hintText: 'e.g., Spring 2026',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(seasonActionsProvider).createSeason(
                      name: nameController.text.trim(),
                      year: DateTime.now().year,
                      startDate: DateTime.now(),
                      isActive: true,
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final seasonsAsync = ref.watch(seasonsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Seasons', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Analytics',
            onPressed: () {
              final isPro = ref.read(isProProvider);
              if (!isPro) {
                context.push('/paywall?feature=Unlock%20analytics%20dashboard');
                return;
              }
              context.push('/analytics');
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateSeasonDialog(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: seasonsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (seasons) {
          if (seasons.isEmpty) {
            return EmptyState(
              icon: Icons.insights_outlined,
              title: 'No seasons yet',
              subtitle:
                  'Create your first growing season to start tracking harvests and compare year over year.',
              actionLabel: 'New Season',
              onAction: () => _showCreateSeasonDialog(context, ref),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            itemCount: seasons.length,
            itemBuilder: (context, index) {
              final season = seasons[index];
              return _SeasonCard(season: season);
            },
          );
        },
      ),
    );
  }
}

/// Card showing a season with its harvest summary
class _SeasonCard extends ConsumerWidget {
  const _SeasonCard({required this.season});

  final Season season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy');
    final harvestsAsync = ref.watch(harvestsBySeasonProvider(season.id));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/season/${season.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: name + active badge + chevron
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        season.name,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  if (season.isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: FurrowColors.seedlingGreen
                            .withValues(alpha: 0.15),
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
                  if (!season.isActive)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'delete') {
                          ref
                              .read(seasonActionsProvider)
                              .deleteSeason(season.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete Season'),
                        ),
                      ],
                    ),
                  Icon(Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant, size: 20),
                ],
              ),
              const SizedBox(height: 8),

              // Date range
              Text(
                season.endDate != null
                    ? '${dateFormat.format(season.startDate)} — ${dateFormat.format(season.endDate!)}'
                    : 'Started ${dateFormat.format(season.startDate)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              // Harvest summary
              harvestsAsync.when(
                loading: () => const SizedBox(
                  height: 20,
                  child: LinearProgressIndicator(),
                ),
                error: (_, __) => const Text('Error loading harvests'),
                data: (harvests) {
                  if (harvests.isEmpty) {
                    return Text(
                      'No harvests logged yet',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    );
                  }

                  final totalQty = harvests.fold<double>(
                      0, (sum, h) => sum + h.quantity);
                  final avgQuality = harvests.fold<double>(
                          0, (sum, h) => sum + h.quality) /
                      harvests.length;

                  return Row(
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
                        label: '${avgQuality.toStringAsFixed(1)} avg',
                        color: const Color(0xFFFF8A00),
                      ),
                    ],
                  );
                },
              ),

              // End season button
              if (season.isActive) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      final isPro = ref.read(isProProvider);
                      if (isPro) {
                        // Pro: show season recap bottom sheet
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (_) => _SeasonRecapSheet(season: season),
                        );
                      } else {
                        // Free: simple confirmation
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('End Season'),
                            content: Text(
                                'End "${season.name}"? You can still view its data.'),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () =>
                                    Navigator.of(ctx).pop(true),
                                child: const Text('End Season'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          ref
                              .read(seasonActionsProvider)
                              .endSeason(season.id);
                        }
                      }
                    },
                    child: const Text('End Season'),
                  ),
                ),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small stat chip used in season cards
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

/// Pro season recap bottom sheet shown before ending a season
class _SeasonRecapSheet extends ConsumerWidget {
  const _SeasonRecapSheet({required this.season});

  final Season season;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final harvestsAsync = ref.watch(harvestsBySeasonProvider(season.id));
    final plantsAsync = ref.watch(plantsStreamProvider);
    final duration = DateTime.now().difference(season.startDate).inDays;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Row(
              children: [
                Icon(Icons.emoji_events,
                    color: FurrowColors.harvestGold, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Season Recap: ${season.name}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats
            harvestsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Error: $e'),
              data: (harvests) {
                if (harvests.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No harvests were logged this season.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                final totalQty = harvests.fold<double>(
                    0, (s, h) => s + h.quantity);
                final avgQuality = harvests.fold<double>(
                        0, (s, h) => s + h.quality) /
                    harvests.length;

                // Find best plant by quantity
                final plantTotals = <String, double>{};
                for (final h in harvests) {
                  plantTotals[h.plantId] =
                      (plantTotals[h.plantId] ?? 0) + h.quantity;
                }
                String? bestPlantId;
                double bestQty = 0;
                for (final entry in plantTotals.entries) {
                  if (entry.value > bestQty) {
                    bestQty = entry.value;
                    bestPlantId = entry.key;
                  }
                }

                // Get plant name
                final plants = plantsAsync.value ?? [];
                final bestPlantName = plants
                    .where((p) => p.id == bestPlantId)
                    .map((p) => p.name)
                    .firstOrNull ?? 'Unknown';

                return Column(
                  children: [
                    // Stats grid
                    Row(
                      children: [
                        _RecapStat(
                          label: 'Harvests',
                          value: '${harvests.length}',
                          icon: Icons.agriculture,
                          color: colorScheme.primary,
                          theme: theme,
                        ),
                        const SizedBox(width: 12),
                        _RecapStat(
                          label: 'Total Qty',
                          value: totalQty.toStringAsFixed(1),
                          icon: Icons.scale,
                          color: FurrowColors.harvestGold,
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _RecapStat(
                          label: 'Avg Quality',
                          value: '${avgQuality.toStringAsFixed(1)} / 5',
                          icon: Icons.star,
                          color: const Color(0xFFFF8A00),
                          theme: theme,
                        ),
                        const SizedBox(width: 12),
                        _RecapStat(
                          label: 'Duration',
                          value: '$duration days',
                          icon: Icons.timer,
                          color: FurrowColors.frostBlue,
                          theme: theme,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Best plant
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: FurrowColors.harvestGold
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: FurrowColors.harvestGold, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Top producer: $bestPlantName (${bestQty.toStringAsFixed(1)})',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // End Season button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  ref.read(seasonActionsProvider).endSeason(season.id);
                  Navigator.of(context).pop();
                },
                child: const Text('End Season'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stat card used in the recap sheet
class _RecapStat extends StatelessWidget {
  const _RecapStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
