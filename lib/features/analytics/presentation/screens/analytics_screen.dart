import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/color_schemes.dart';
import '../../../../shared/utils/csv_export.dart';
import '../providers/analytics_providers.dart';

/// Analytics screen — charts and insights from harvest data
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overallAsync = ref.watch(overallStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Analytics', style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Export CSV',
            onPressed: () async {
              try {
                await exportCsv(ref);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: overallAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 88),
            children: [
              // ─── Summary cards row ─────────────────────────
              _OverallStatsRow(stats: stats, theme: theme, colorScheme: colorScheme),

              const SizedBox(height: 24),

              // ─── Season comparison bar chart ───────────────
              _SectionTitle(title: 'Harvest by Season', theme: theme),
              const SizedBox(height: 8),
              _SeasonBarChart(theme: theme, colorScheme: colorScheme),

              const SizedBox(height: 32),

              // ─── Top plants horizontal bar chart ───────────
              _SectionTitle(title: 'Top Plants', theme: theme),
              const SizedBox(height: 8),
              _TopPlantsChart(theme: theme, colorScheme: colorScheme),

              const SizedBox(height: 32),

              // ─── Plant status distribution pie chart ───────
              _SectionTitle(title: 'Plant Status', theme: theme),
              const SizedBox(height: 8),
              _StatusPieChart(theme: theme, colorScheme: colorScheme),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}

// ─── Overall stats row ───────────────────────────────────────────

class _OverallStatsRow extends StatelessWidget {
  const _OverallStatsRow({
    required this.stats,
    required this.theme,
    required this.colorScheme,
  });

  final Map<String, dynamic> stats;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _MiniStatCard(
            icon: Icons.yard,
            label: 'Plants',
            value: '${stats['totalPlants']}',
            color: colorScheme.primary,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _MiniStatCard(
            icon: Icons.agriculture,
            label: 'Harvests',
            value: '${stats['totalHarvests']}',
            color: FurrowColors.harvestGold,
            theme: theme,
          ),
          const SizedBox(width: 8),
          _MiniStatCard(
            icon: Icons.star,
            label: 'Avg Quality',
            value: (stats['avgQuality'] as double).toStringAsFixed(1),
            color: const Color(0xFFFF8A00),
            theme: theme,
          ),
          const SizedBox(width: 8),
          _MiniStatCard(
            icon: Icons.insights,
            label: 'Seasons',
            value: '${stats['totalSeasons']}',
            color: FurrowColors.frostBlue,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Section title ───────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.theme});
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(title, style: theme.textTheme.titleMedium),
    );
  }
}

// ─── Season bar chart ────────────────────────────────────────────

class _SeasonBarChart extends ConsumerWidget {
  const _SeasonBarChart({required this.theme, required this.colorScheme});
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(seasonSummariesProvider);

    return summariesAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (summaries) {
        if (summaries.isEmpty) {
          return _EmptyChartCard(
            message: 'Create seasons and log harvests to see comparisons.',
            theme: theme,
          );
        }

        final maxQty = summaries.fold<double>(
            0, (m, s) => s.totalQuantity > m ? s.totalQuantity : m);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxQty == 0 ? 10 : maxQty * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final summary = summaries[group.x.toInt()];
                          return BarTooltipItem(
                            '${summary.seasonName}\n${summary.totalQuantity.toStringAsFixed(1)} total\n${summary.harvestCount} harvests',
                            theme.textTheme.bodySmall!.copyWith(
                              color: colorScheme.onInverseSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= summaries.length) {
                              return const SizedBox.shrink();
                            }
                            // Abbreviate long names
                            final name = summaries[idx].seasonName;
                            final short = name.length > 10
                                ? '${name.substring(0, 9)}…'
                                : name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                short,
                                style: theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxQty == 0 ? 2 : maxQty / 4,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: summaries.asMap().entries.map((entry) {
                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.totalQuantity,
                            color: colorScheme.primary,
                            width: 28,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Top plants horizontal bar chart ─────────────────────────────

class _TopPlantsChart extends ConsumerWidget {
  const _TopPlantsChart({required this.theme, required this.colorScheme});
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topPlantsProvider);

    return topAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (plants) {
        if (plants.isEmpty) {
          return _EmptyChartCard(
            message: 'Log harvests to see your top performing plants.',
            theme: theme,
          );
        }

        final maxQty = plants.fold<double>(
            0, (m, p) => p.totalQuantity > m ? p.totalQuantity : m);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
              child: SizedBox(
                height: (plants.length * 44.0).clamp(120, 360),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxQty == 0 ? 10 : maxQty * 1.2,
                    barTouchData: BarTouchData(
                      touchTooltipData: BarTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final plant = plants[group.x.toInt()];
                          return BarTooltipItem(
                            '${plant.plantName}\n${plant.totalQuantity.toStringAsFixed(1)} total\n⭐ ${plant.avgQuality.toStringAsFixed(1)}',
                            theme.textTheme.bodySmall!.copyWith(
                              color: colorScheme.onInverseSurface,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= plants.length) {
                              return const SizedBox.shrink();
                            }
                            final name = plants[idx].plantName;
                            final short = name.length > 8
                                ? '${name.substring(0, 7)}…'
                                : name;
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                short,
                                style: theme.textTheme.labelSmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          },
                          reservedSize: 30,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 36,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        strokeWidth: 1,
                      ),
                    ),
                    barGroups: plants.asMap().entries.map((entry) {
                      // Cycle through some nice colors
                      final colors = [
                        colorScheme.primary,
                        FurrowColors.harvestGold,
                        FurrowColors.seedlingGreen,
                        const Color(0xFFFF8A00),
                        FurrowColors.frostBlue,
                        colorScheme.tertiary,
                        FurrowColors.alertRed,
                        colorScheme.secondary,
                      ];
                      final color = colors[entry.key % colors.length];

                      return BarChartGroupData(
                        x: entry.key,
                        barRods: [
                          BarChartRodData(
                            toY: entry.value.totalQuantity,
                            color: color,
                            width: 22,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Status pie chart ────────────────────────────────────────────

class _StatusPieChart extends ConsumerWidget {
  const _StatusPieChart({required this.theme, required this.colorScheme});
  final ThemeData theme;
  final ColorScheme colorScheme;

  Color _statusColor(String status) {
    switch (status) {
      case 'planned':
        return colorScheme.outline;
      case 'seedling':
        return FurrowColors.seedlingGreen;
      case 'growing':
        return colorScheme.primary;
      case 'flowering':
        return FurrowColors.harvestGold;
      case 'harvesting':
        return const Color(0xFFFF8A00);
      case 'dormant':
        return colorScheme.outlineVariant;
      case 'removed':
        return colorScheme.error;
      default:
        return colorScheme.tertiary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(plantStatusDistributionProvider);

    return statusAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Error: $e'),
      data: (statusCounts) {
        if (statusCounts.isEmpty) {
          return _EmptyChartCard(
            message: 'Add plants to see status distribution.',
            theme: theme,
          );
        }

        final total =
            statusCounts.fold<int>(0, (sum, sc) => sum + sc.count);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Pie chart
                  Expanded(
                    flex: 3,
                    child: SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 36,
                          sections: statusCounts.map((sc) {
                            final pct = (sc.count / total * 100).round();
                            return PieChartSectionData(
                              color: _statusColor(sc.status),
                              value: sc.count.toDouble(),
                              title: '$pct%',
                              radius: 50,
                              titleStyle: theme.textTheme.labelSmall!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: statusCounts.map((sc) {
                        final label =
                            sc.status[0].toUpperCase() + sc.status.substring(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _statusColor(sc.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '$label (${sc.count})',
                                  style: theme.textTheme.labelSmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Empty chart placeholder ─────────────────────────────────────

class _EmptyChartCard extends StatelessWidget {
  const _EmptyChartCard({required this.message, required this.theme});
  final String message;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
