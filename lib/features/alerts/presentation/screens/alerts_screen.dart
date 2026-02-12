import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../../core/services/weather_service.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../providers/alert_providers.dart';
import '../widgets/frost_alert_card.dart';

/// Frost alerts screen - Tab 3
/// Shows 7-day forecast with frost warnings highlighted
class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locationAsync = ref.watch(userLocationProvider);
    final forecastAsync = ref.watch(forecastProvider);
    final frostDays = ref.watch(frostAlertDaysProvider);
    final useCelsius = ref.watch(tempUnitProvider) == TempUnit.celsius;

    return Scaffold(
      appBar: AppBar(
        title: Text('Alerts', style: theme.textTheme.titleLarge),
        actions: [
          // Refresh button
          if (locationAsync.value != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                ref.invalidate(forecastProvider);
              },
            ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'Profile & Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: locationAsync.when(
        // No location yet — show enable prompt
        data: (position) {
          if (position == null) {
            return EmptyState(
              icon: Icons.ac_unit_outlined,
              title: 'No alerts',
              subtitle:
                  'Enable location to get frost warnings for your area.\nWe\'ll watch the forecast so you don\'t have to.',
              actionLabel: 'Enable Location',
              onAction: () {
                ref.read(userLocationProvider.notifier).requestAndFetch();
              },
            );
          }

          // Have location — show forecast
          return forecastAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 48),
                    const SizedBox(height: 16),
                    Text('Could not load forecast',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('$error',
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.invalidate(forecastProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
            data: (forecast) {
              if (forecast.isEmpty) {
                return const Center(
                  child: Text('No forecast data available'),
                );
              }

              return ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 88),
                children: [
                  // Frost alert summary banner
                  if (frostDays.isNotEmpty)
                    _FrostSummaryBanner(
                      frostDays: frostDays,
                      useCelsius: useCelsius,
                      theme: theme,
                      colorScheme: colorScheme,
                    ),

                  // No frost = all clear banner
                  if (frostDays.isEmpty)
                    _AllClearBanner(theme: theme, colorScheme: colorScheme),

                  // Section header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text('7-Day Forecast',
                        style: theme.textTheme.titleMedium),
                  ),

                  // Full 7-day forecast
                  ...forecast.map((day) {
                    final dateFormat = DateFormat('EEEE, MMM d');
                    final hasFrost = day.frostSeverity != null;
                    final unit = useCelsius ? '°C' : '°F';
                    final low = useCelsius
                        ? day.minTempC.round()
                        : day.minTempF.round();
                    final high = useCelsius
                        ? day.maxTempC.round()
                        : day.maxTempF.round();

                    if (hasFrost) {
                      return FrostAlertCard(
                        date: dateFormat.format(day.date),
                        lowTemp: '$low$unit',
                        severity: day.frostSeverity!,
                        description:
                            '${day.weatherIcon} ${day.weatherDescription} · High $high$unit',
                      );
                    }

                    // Normal day (no frost)
                    return _NormalDayCard(
                      day: day,
                      useCelsius: useCelsius,
                      theme: theme,
                      colorScheme: colorScheme,
                    );
                  }),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_off, size: 48),
                const SizedBox(height: 16),
                Text('Location Error',
                    style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('$error',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    ref
                        .read(userLocationProvider.notifier)
                        .requestAndFetch();
                  },
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner shown when frost days are detected
class _FrostSummaryBanner extends StatelessWidget {
  const _FrostSummaryBanner({
    required this.frostDays,
    required this.useCelsius,
    required this.theme,
    required this.colorScheme,
  });

  final List<DailyForecast> frostDays;
  final bool useCelsius;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final worstDay = frostDays.reduce(
        (a, b) => a.minTempF < b.minTempF ? a : b);
    final color = worstDay.hasHardFreeze
        ? FurrowColors.frostBlue
        : worstDay.hasFrostDanger
            ? FurrowColors.alertRed
            : FurrowColors.harvestGold;

    final lowestTemp = useCelsius
        ? '${worstDay.minTempC.round()}°C'
        : '${worstDay.minTempF.round()}°F';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${frostDays.length} frost ${frostDays.length == 1 ? 'day' : 'days'} ahead',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Lowest: $lowestTemp — protect your plants!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color,
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

/// Banner shown when no frost is expected
class _AllClearBanner extends StatelessWidget {
  const _AllClearBanner({
    required this.theme,
    required this.colorScheme,
  });

  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FurrowColors.seedlingGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: FurrowColors.seedlingGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              color: FurrowColors.seedlingGreen, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All clear!',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: FurrowColors.seedlingGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'No frost expected in the next 7 days.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: FurrowColors.seedlingGreen,
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

/// Card for a normal (non-frost) forecast day
class _NormalDayCard extends StatelessWidget {
  const _NormalDayCard({
    required this.day,
    required this.useCelsius,
    required this.theme,
    required this.colorScheme,
  });

  final DailyForecast day;
  final bool useCelsius;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d');
    final high = useCelsius ? day.maxTempC.round() : day.maxTempF.round();
    final low = useCelsius ? day.minTempC.round() : day.minTempF.round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(day.weatherIcon, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(day.date),
                      style: theme.textTheme.titleSmall,
                    ),
                    Text(
                      day.weatherDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$high°',
                    style: theme.textTheme.titleMedium,
                  ),
                  Text(
                    '$low°',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
