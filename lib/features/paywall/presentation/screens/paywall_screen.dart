import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import '../../../../core/services/revenue_cat_service.dart';
import '../providers/entitlement_providers.dart';

/// Paywall screen — presents RevenueCat's native paywall UI.
///
/// The paywall design is configured in the RevenueCat dashboard, not in code.
/// This screen simply triggers the native presentation and handles the result.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key, this.feature});

  /// What feature triggered this paywall (e.g., "Unlock unlimited plants").
  /// Currently unused by the native paywall but kept for route compatibility.
  final String? feature;

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    // Present the native paywall as soon as this screen mounts.
    _showPaywall();
  }

  Future<void> _showPaywall() async {
    final result = await RevenueCatService.instance.presentPaywall();

    if (!mounted) return;

    switch (result) {
      case PaywallResult.purchased:
      case PaywallResult.restored:
        // Refresh entitlement state and pop back with success message.
        await ref.read(isProProvider.notifier).refresh();
        if (mounted) {
          context.pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result == PaywallResult.purchased
                    ? 'Welcome to Furrow Pro! 🌱'
                    : 'Purchases restored! Welcome back to Pro.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      case PaywallResult.cancelled:
      case PaywallResult.error:
      case PaywallResult.notPresented:
        // User dismissed, errored, or already has entitlement — just go back.
        if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a minimal loading state while the native paywall is presenting.
    // The native paywall overlays on top of this.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
