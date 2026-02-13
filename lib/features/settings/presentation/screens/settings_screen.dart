import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/revenue_cat_service.dart';
import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../../../paywall/presentation/providers/entitlement_providers.dart';
import '../providers/settings_providers.dart';

/// Settings screen — theme mode, temperature unit, about
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ref.watch(themeModeProvider);
    final tempUnit = ref.watch(tempUnitProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(
          top: 8,
          bottom: MediaQuery.of(context).padding.bottom + 24,
        ),
        children: [
          // ─── Appearance ──────────────────────────────────────
          _SectionHeader(title: 'Appearance', theme: theme),

          // Theme mode selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Theme', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 12),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (modes) {
                        ref
                            .read(themeModeProvider.notifier)
                            .setThemeMode(modes.first);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Units ──────────────────────────────────────────
          _SectionHeader(title: 'Units', theme: theme),

          // Temperature unit toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: SwitchListTile(
                title: const Text('Temperature Unit'),
                subtitle: Text(
                  tempUnit == TempUnit.fahrenheit
                      ? 'Fahrenheit (°F)'
                      : 'Celsius (°C)',
                ),
                secondary: Icon(
                  Icons.thermostat,
                  color: colorScheme.primary,
                ),
                value: tempUnit == TempUnit.celsius,
                onChanged: (_) {
                  ref.read(tempUnitProvider.notifier).toggle();
                },
              ),
            ),
          ),

          // Hint text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Affects frost alerts and forecast display.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),

          // ─── Subscription ─────────────────────────────────
          _SectionHeader(title: 'Subscription', theme: theme),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current tier
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ref.watch(isProProvider)
                                ? FurrowColors.harvestGold
                                    .withValues(alpha: 0.15)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ref.watch(isProProvider) ? '⭐ Pro' : 'Free',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ref.watch(isProProvider)
                                  ? FurrowColors.harvestGold
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (!ref.watch(isProProvider))
                          FilledButton.tonalIcon(
                            onPressed: () => context.push('/paywall'),
                            icon: const Icon(Icons.rocket_launch, size: 16),
                            label: const Text('Upgrade'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Limits info
                    if (!ref.watch(isProProvider)) ...[
                      Text(
                        'Free tier: ${AppConstants.freePlantLimit} plants, '
                        '${AppConstants.freeSeasonLimit} season',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Upgrade for unlimited plants & seasons, analytics, '
                        'harvest timing, care tips, watering reminders, and CSV export.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Text(
                        'All features unlocked. Thank you for supporting Furrow!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          RevenueCatService.instance.presentCustomerCenter();
                        },
                        icon: const Icon(Icons.manage_accounts, size: 18),
                        label: const Text('Manage Subscription'),
                      ),
                    ],

                    // Debug toggle — only visible in debug builds
                    if (kDebugMode) ...[
                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Debug: Pro Override'),
                        subtitle: const Text(
                            'Toggle Pro status for testing'),
                        value: ref.watch(isProProvider),
                        onChanged: (_) {
                          ref.read(isProProvider.notifier).toggle();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ─── About ──────────────────────────────────────────
          _SectionHeader(title: 'About', theme: theme),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.yard,
                            color: colorScheme.primary, size: 28),
                        const SizedBox(width: 12),
                        Text(
                          AppConstants.appName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Version ${AppConstants.appVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.appDescription,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section header label
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.theme});

  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
