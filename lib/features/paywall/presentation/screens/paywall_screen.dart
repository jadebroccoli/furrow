import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/constants/app_constants.dart';
import '../../../../shared/theme/color_schemes.dart';
import '../providers/entitlement_providers.dart';

/// Paywall screen — shown when a free user hits a Pro limit
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key, this.feature});

  /// What feature triggered this paywall (e.g., "Unlock unlimited plants")
  final String? feature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Furrow Pro'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Hero icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primary,
                      FurrowColors.harvestGold,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  size: 52,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                feature ?? 'Upgrade to Pro',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Get the most out of your garden',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // Feature list
              _FeatureRow(
                icon: Icons.eco,
                text: 'Unlimited plants',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.insights,
                text: 'Unlimited seasons & analytics',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.schedule,
                text: 'Smart harvest timing',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.tips_and_updates,
                text: 'Care recommendations',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.notifications_active,
                text: 'Watering reminders',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.emoji_events,
                text: 'Season recap summaries',
                theme: theme,
                colorScheme: colorScheme,
              ),
              _FeatureRow(
                icon: Icons.download,
                text: 'CSV export',
                theme: theme,
                colorScheme: colorScheme,
              ),

              const Spacer(flex: 2),

              // CTA buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    // TODO: Wire to RevenueCat yearly package
                    ref.read(isProProvider.notifier).setPro(true);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Welcome to Furrow Pro!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    'Yearly — ${AppConstants.proYearlyPrice} (Save 44%)',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Wire to RevenueCat monthly package
                    ref.read(isProProvider.notifier).setPro(true);
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Welcome to Furrow Pro!'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text('Monthly — ${AppConstants.proMonthlyPrice}'),
                ),
              ),
              const SizedBox(height: 12),

              // Restore purchases
              TextButton(
                onPressed: () {
                  // TODO: Wire to RevenueCat restore purchases
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No previous purchases found'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Text(
                  'Restore Purchases',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.text,
    required this.theme,
    required this.colorScheme,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}
