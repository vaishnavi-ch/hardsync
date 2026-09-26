import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'config/env_config.dart';
import 'services/revenuecat_service.dart';
import 'theme/hardsync_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.init();
  final requestedId = Uri.base.queryParameters['testUser']?.trim();
  final testUser = requestedId == null || requestedId.isEmpty
      ? 'hardsync-test-store'
      : requestedId;
  await RevenueCatService.instance.init(appUserId: testUser);
  runApp(RevenueCatTestHarness(testUser: testUser));
}

class RevenueCatTestHarness extends StatelessWidget {
  const RevenueCatTestHarness({super.key, required this.testUser});

  final String testUser;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: HardSyncTheme.lightTheme,
      home: kReleaseMode
          ? const Scaffold(
              body: Center(child: Text('Test Store is disabled in release builds.')),
            )
          : _HarnessScreen(testUser: testUser),
    );
  }
}

class _HarnessScreen extends StatefulWidget {
  const _HarnessScreen({required this.testUser});

  final String testUser;

  @override
  State<_HarnessScreen> createState() => _HarnessScreenState();
}

class _HarnessScreenState extends State<_HarnessScreen> {
  Offerings? _offerings;
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh({bool clearMessage = true}) async {
    setState(() {
      _loading = true;
      if (clearMessage) _message = null;
    });
    try {
      await RevenueCatService.instance.refreshCustomerInfo();
      final offerings = await RevenueCatService.instance.getOfferings();
      if (mounted) setState(() => _offerings = offerings);
    } catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _purchase(Package package) async {
    setState(() => _message = 'Opening RevenueCat Test Store…');
    try {
      await RevenueCatService.instance.purchasePackage(package);
      if (mounted) setState(() => _message = 'Purchase completed.');
    } catch (error) {
      if (mounted) setState(() => _message = 'Purchase ended: $error');
    }
    await _refresh(clearMessage: false);
  }

  Future<void> _restore() async {
    final restored = await RevenueCatService.instance.restorePurchases();
    if (mounted) {
      setState(() => _message = restored
          ? 'Restore completed with an active entitlement.'
          : 'Restore completed; no active entitlement found.');
    }
    await _refresh(clearMessage: false);
  }

  @override
  Widget build(BuildContext context) {
    final service = RevenueCatService.instance;
    final packages = _offerings?.current?.availablePackages ?? const <Package>[];
    final active = service.customerInfo?.entitlements.active.keys.toList() ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('RevenueCat Test Store')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Text('Sandbox customer', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                SelectableText(widget.testUser),
                const SizedBox(height: 20),
                _StatusRow(label: 'SDK configured', value: '${service.isConfigured}'),
                _StatusRow(label: 'Using Test Store', value: '${service.isUsingTestStore}'),
                _StatusRow(label: 'Current offering', value: _offerings?.current?.identifier ?? 'none'),
                _StatusRow(label: 'Active entitlements', value: active.isEmpty ? 'none' : active.join(', ')),
                const SizedBox(height: 24),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (!_loading && packages.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No packages are attached to the current RevenueCat offering. Add the Pro and Ultra Test Store products to the current offering, then refresh.',
                      ),
                    ),
                  ),
                for (final package in packages)
                  Card(
                    child: ListTile(
                      title: Text(package.storeProduct.title),
                      subtitle: Text('${package.identifier} · ${package.storeProduct.priceString}'),
                      trailing: FilledButton(
                        onPressed: () => _purchase(package),
                        child: const Text('Test purchase'),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                    OutlinedButton.icon(
                      onPressed: service.isConfigured ? _restore : null,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Restore'),
                    ),
                  ],
                ),
                if (_message != null) ...[
                  const SizedBox(height: 18),
                  Text(_message!, key: const Key('test-store-message')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
