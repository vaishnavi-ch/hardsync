import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/env_config.dart';

class RevenueCatService {
  static const ultraEntitlementId = 'ultra';
  static final RevenueCatService instance = RevenueCatService._internal();

  RevenueCatService._internal();

  bool _isConfigured = false;
  bool _isUsingTestStore = false;
  CustomerInfo? _customerInfo;
  final List<VoidCallback> _listeners = [];

  bool get isConfigured => _isConfigured;
  bool get isUsingTestStore => _isUsingTestStore;
  CustomerInfo? get customerInfo => _customerInfo;

  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void _notifyListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }

  bool get isUltraSubscriber {
    if (!_isConfigured || _customerInfo == null) return false;
    final active = _customerInfo!.entitlements.active;
    if (active.isEmpty) return false;
    return active.containsKey(ultraEntitlementId) ||
        (!kReleaseMode &&
            _isUsingTestStore &&
            active.containsKey('test_ultra'));
  }

  Future<void> init({String? appUserId}) async {
    if (_isConfigured) return;

    if (!EnvConfig.isRevenueCatConfigured) {
      debugPrint(
        '[RevenueCatService] No RevenueCat public SDK key in .env. Billing unavailable.',
      );
      _isConfigured = false;
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
      late PurchasesConfiguration configuration;

      if (!kReleaseMode &&
          EnvConfig.useRevenueCatTestStore &&
          EnvConfig.revenueCatTestStoreKey.isNotEmpty) {
        _isUsingTestStore = true;
        configuration = PurchasesConfiguration(EnvConfig.revenueCatTestStoreKey)
          ..appUserID = appUserId;
        debugPrint(
          '[RevenueCatService] Using RevenueCat Test Store with accelerated sandbox renewals.',
        );
      } else if (kIsWeb) {
        _isUsingTestStore = false;
        if (EnvConfig.revenueCatWebKey.isEmpty) return;
        configuration = PurchasesConfiguration(EnvConfig.revenueCatWebKey)
          ..appUserID = appUserId;
      } else if (Platform.isIOS || Platform.isMacOS) {
        _isUsingTestStore = false;
        if (EnvConfig.revenueCatAppleKey.isEmpty) return;
        configuration = PurchasesConfiguration(EnvConfig.revenueCatAppleKey)
          ..appUserID = appUserId;
      } else if (Platform.isAndroid) {
        _isUsingTestStore = false;
        if (EnvConfig.revenueCatGoogleKey.isEmpty) return;
        configuration = PurchasesConfiguration(EnvConfig.revenueCatGoogleKey)
          ..appUserID = appUserId;
      } else {
        return;
      }

      await Purchases.configure(configuration);
      _customerInfo = await Purchases.getCustomerInfo();
      _isConfigured = true;

      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _notifyListeners();
        debugPrint(
          '[RevenueCatService] Customer info updated. Ultra active: $isUltraSubscriber',
        );
      });

      debugPrint(
        '[RevenueCatService] Initialized RevenueCat for ${kIsWeb ? "Web" : Platform.operatingSystem}',
      );
      // The subscription provider can finish its initial refresh before SDK
      // setup. Publish the first CustomerInfo so existing Test Store purchases
      // are reflected without requiring a new purchase or app restart.
      _notifyListeners();
    } catch (e) {
      debugPrint(
        '[RevenueCatService] Initialization failed: $e. Billing unavailable.',
      );
      _isConfigured = false;
      _isUsingTestStore = false;
    }
  }

  Future<Offerings?> getOfferings() async {
    if (!_isConfigured) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCatService] Error fetching offerings: $e');
      return null;
    }
  }

  /// Keeps RevenueCat's customer identity aligned with the Supabase UUID.
  /// This is required for cross-device restores and server-side entitlement
  /// checks. RevenueCat safely merges an earlier anonymous customer when its
  /// documented alias rules allow it.
  Future<void> identify(String? appUserId) async {
    if (!_isConfigured) return;
    try {
      if (appUserId == null || appUserId.trim().isEmpty) {
        if (!await Purchases.isAnonymous) {
          _customerInfo = await Purchases.logOut();
        }
      } else {
        _customerInfo = (await Purchases.logIn(appUserId.trim())).customerInfo;
      }
      _notifyListeners();
    } catch (e) {
      debugPrint('[RevenueCatService] Customer identity sync failed: $e');
    }
  }

  Future<void> refreshCustomerInfo() async {
    if (!_isConfigured) return;
    _customerInfo = await Purchases.getCustomerInfo();
    _notifyListeners();
  }

  Future<bool> purchasePackage(Package package) async {
    if (!_isConfigured) return false;
    try {
      _customerInfo = (await Purchases.purchase(
        PurchaseParams.package(package),
      )).customerInfo;
      _notifyListeners();
      return isUltraSubscriber;
    } catch (e) {
      debugPrint('[RevenueCatService] Purchase error: $e');
      rethrow;
    }
  }

  Future<bool> purchaseAnnualPlan() async {
    if (!_isConfigured) return false;

    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.annual;
      if (package != null) {
        _customerInfo = (await Purchases.purchase(
          PurchaseParams.package(package),
        )).customerInfo;
        return isUltraSubscriber;
      }
      return false;
    } catch (e) {
      debugPrint('[RevenueCatService] Purchase error: $e');
      return false;
    }
  }

  Future<bool> purchaseMonthlyPlan() async {
    if (!_isConfigured) return false;

    try {
      final offerings = await Purchases.getOfferings();
      final package = offerings.current?.monthly;
      if (package != null) {
        _customerInfo = (await Purchases.purchase(
          PurchaseParams.package(package),
        )).customerInfo;
        return isUltraSubscriber;
      }
      return false;
    } catch (e) {
      debugPrint('[RevenueCatService] Purchase error: $e');
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_isConfigured) return false;
    // RevenueCat Flutter web does not support restorePurchases. Web access is
    // recovered by logging in with the same Supabase UUID and refreshing info.
    if (kIsWeb) {
      await refreshCustomerInfo();
      return isUltraSubscriber;
    }

    try {
      _customerInfo = await Purchases.restorePurchases();
      _notifyListeners();
      return isUltraSubscriber;
    } catch (e) {
      debugPrint('[RevenueCatService] Restore purchases error: $e');
      return false;
    }
  }
}
