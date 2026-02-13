import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../../core/services/revenue_cat_service.dart';

/// Single source of truth: is the user a Pro subscriber?
/// Backed by RevenueCat entitlement checks.
final isProProvider = StateNotifierProvider<ProStatusNotifier, bool>((ref) {
  final notifier = ProStatusNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

class ProStatusNotifier extends StateNotifier<bool> {
  ProStatusNotifier() : super(false) {
    _init();
  }

  bool _debugOverride = false;

  Future<void> _init() async {
    // Check current entitlement status on launch
    final isPro = await RevenueCatService.instance.isProUser();
    if (mounted) state = isPro || _debugOverride;

    // Listen for real-time changes (renewal, expiration, etc.)
    RevenueCatService.instance.addCustomerInfoListener(_onCustomerInfoUpdate);
  }

  void _onCustomerInfoUpdate(CustomerInfo info) {
    final active =
        info.entitlements.all[RevenueCatService.entitlementId]?.isActive ??
            false;
    if (mounted) state = active || _debugOverride;
  }

  /// Re-check entitlement (e.g. after a paywall purchase).
  Future<void> refresh() async {
    final isPro = await RevenueCatService.instance.isProUser();
    if (mounted) state = isPro || _debugOverride;
  }

  /// Debug toggle — only works in debug builds.
  void toggle() {
    if (kDebugMode) {
      _debugOverride = !_debugOverride;
      state = _debugOverride;
    }
  }

  @override
  void dispose() {
    RevenueCatService.instance.removeCustomerInfoListener(
      _onCustomerInfoUpdate,
    );
    super.dispose();
  }
}
