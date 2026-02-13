import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

/// RevenueCat wrapper — handles SDK init, purchases, entitlement checks,
/// pre-built paywalls, and Customer Center.
///
/// Follows the same singleton pattern as [NotificationService].
class RevenueCatService {
  RevenueCatService._();

  static final RevenueCatService instance = RevenueCatService._();

  // ── RevenueCat public API keys ──────────────────────────────────────
  // These are safe to ship in the binary (they are public, not secret).
  static const String _androidApiKey = 'test_RBJAGMopSZyNPOjoMCPXdeCSZXN';
  static const String _iosApiKey = 'test_RBJAGMopSZyNPOjoMCPXdeCSZXN';

  /// The entitlement identifier configured in the RevenueCat dashboard.
  static const String entitlementId = 'Broccoli Studios Pro';

  bool _isInitialized = false;

  // ── Lifecycle ───────────────────────────────────────────────────────

  /// Initialize the RevenueCat SDK. Call once at app startup.
  Future<void> initialize() async {
    if (_isInitialized) return;

    final apiKey = Platform.isIOS ? _iosApiKey : _androidApiKey;

    await Purchases.configure(PurchasesConfiguration(apiKey));

    if (kDebugMode) {
      await Purchases.setLogLevel(LogLevel.debug);
    }

    _isInitialized = true;
  }

  // ── Entitlements ────────────────────────────────────────────────────

  /// Returns `true` when the current user has an active entitlement.
  Future<bool> isProUser() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Register a listener for customer-info updates (subscription renewal,
  /// expiry, etc.).
  void addCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.addCustomerInfoUpdateListener(listener);
  }

  /// Remove a previously-registered listener.
  void removeCustomerInfoListener(void Function(CustomerInfo) listener) {
    Purchases.removeCustomerInfoUpdateListener(listener);
  }

  // ── Offerings ───────────────────────────────────────────────────────

  /// Fetch the currently-available offerings from RevenueCat.
  Future<Offerings> getOfferings() async {
    return Purchases.getOfferings();
  }

  // ── Purchasing ──────────────────────────────────────────────────────

  /// Purchase a [Package] and return `true` if the entitlement
  /// is now active. Uses the v9 PurchaseResult return type.
  Future<bool> purchasePackage(Package package) async {
    try {
      final result = await Purchases.purchasePackage(package);
      return result.customerInfo.entitlements.all[entitlementId]?.isActive ??
          false;
    } on PlatformException catch (e) {
      // User cancelled — not a real error.
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    }
  }

  /// Restore previous purchases. Returns `true` if entitlement is now active.
  Future<bool> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      return info.entitlements.all[entitlementId]?.isActive ?? false;
    } catch (_) {
      return false;
    }
  }

  // ── Pre-built Paywall ───────────────────────────────────────────────

  /// Present RevenueCat's native paywall. Only shows if the user does
  /// NOT already have the [entitlementId] entitlement.
  Future<PaywallResult> presentPaywall() async {
    return RevenueCatUI.presentPaywallIfNeeded(entitlementId);
  }

  /// Present the paywall unconditionally (even if user is already Pro).
  Future<PaywallResult> presentPaywallAlways() async {
    return RevenueCatUI.presentPaywall();
  }

  // ── Customer Center ─────────────────────────────────────────────────

  /// Present RevenueCat's Customer Center for subscription management.
  Future<void> presentCustomerCenter() async {
    await RevenueCatUI.presentCustomerCenter();
  }
}
