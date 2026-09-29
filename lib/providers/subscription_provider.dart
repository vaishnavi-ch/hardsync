import 'package:flutter/foundation.dart';
import '../models/subscription_tier.dart';
import '../services/backend_service.dart';
import '../services/revenuecat_service.dart';
import '../services/supabase_service.dart';

class SubscriptionProvider with ChangeNotifier {
  SubscriptionTier _tier = SubscriptionTier.free;
  bool _loaded = false, _disposed = false;
  int _request = 0;
  SubscriptionProvider() {
    SupabaseService.instance.addListener(refresh);
    RevenueCatService.instance.addListener(refresh);
    refresh();
  }
  SubscriptionTier get currentTier => _tier;
  bool get isLoaded => _loaded;
  bool get canUseAudioCalls => _tier.canUseAudioCalls;
  bool get canUseVideoCalls => _tier.canUseVideoCalls;
  bool get canUseLiveFaceAnalysis => _tier == SubscriptionTier.ultra;

  Future<void> refresh() async {
    final request = ++_request;
    var verifiedTier = SubscriptionTier.free;
    try {
      // 1. Check RevenueCat client entitlements first
      if (RevenueCatService.instance.isUltraSubscriber) {
        verifiedTier = SubscriptionTier.ultra;
      } else if (RevenueCatService.instance.isProSubscriber) {
        verifiedTier = SubscriptionTier.pro;
      }

      // Test Store entitlements are accepted only in debug builds.
      // When the Test Store is active, automatically grant Ultra so every
      // call mode (text, audio, video) can be tested locally without
      // requiring a RevenueCat Test Store purchase first.
      // The server also bypasses the tier gate when REVENUECAT_USE_TEST_STORE=true.
      if (!kReleaseMode && RevenueCatService.instance.isUsingTestStore) {
        // If the user has already purchased a Test Store package, use that tier;
        // otherwise default to Ultra so nothing is blocked during dev/testing.
        if (verifiedTier == SubscriptionTier.free) {
          verifiedTier = SubscriptionTier.ultra;
        }
        if (!_disposed && request == _request) _tier = verifiedTier;
        return;
      }

      // 2. Cross-reference with backend (production path only)
      var data = await BackendService.request('/api/account');
      var serverTier = SubscriptionTier.values.firstWhere(
        (t) => t.name == data['tier'],
        orElse: () => SubscriptionTier.free,
      );
      // A non-subscription purchase (e.g. a consumable) also notifies this
      // provider, since it shares RevenueCat's customer-info listener with
      // subscriptions. That purchase never touches the pro/ultra entitlement,
      // so if the server suddenly reports a lower tier than what RevenueCat's
      // own local entitlements still show, re-check once after a beat before
      // accepting it — a real expiry/cancellation still confirms on the
      // second look, but a transient sync gap after a purchase self-corrects.
      if (serverTier.index < verifiedTier.index) {
        await Future<void>.delayed(const Duration(milliseconds: 1500));
        if (_disposed || request != _request) return;
        data = await BackendService.request('/api/account');
        serverTier = SubscriptionTier.values.firstWhere(
          (t) => t.name == data['tier'],
          orElse: () => SubscriptionTier.free,
        );
      }
      if (!_disposed && request == _request) {
        // The server performs its own RevenueCat lookup and is authoritative,
        // including subscription expiry (tier can move downward).
        _tier = serverTier;
      }
    } catch (_) {
      if (!_disposed && request == _request) _tier = verifiedTier;
    } finally {
      if (!_disposed && request == _request) {
        _loaded = true;
        notifyListeners();
      }
    }
  }

  Future<void> setTier(SubscriptionTier tier) async {
    try {
      final res = await BackendService.request('/api/account/tier', {
        'tier': tier.name,
      });
      final serverTier = SubscriptionTier.values.firstWhere(
        (t) => t.name == res['tier'],
        orElse: () => SubscriptionTier.free,
      );
      _tier = serverTier;
      notifyListeners();
    } catch (_) {
      // Unverified local changes cannot unlock paid tiers
      await refresh();
    }
  }

  Future<void> upgradeTo(SubscriptionTier tier) => setTier(tier);

  @override
  void dispose() {
    _disposed = true;
    SupabaseService.instance.removeListener(refresh);
    RevenueCatService.instance.removeListener(refresh);
    super.dispose();
  }
}
