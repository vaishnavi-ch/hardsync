import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/env_config.dart';
import '../providers/settings_provider.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';

class SettingsModal extends StatelessWidget {
  const SettingsModal({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Call settings',
                        style: GoogleFonts.newsreader(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: HardSyncColors.ink,
                        ),
                      ),
                      Text(
                        'Prepare your practice room.',
                        style: GoogleFonts.plusJakartaSans(
                          color: HardSyncColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 94,
                  height: 78,
                  child: AppIllustration(
                    HardSyncAssets.illusPrivatePracticeSpace,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _SettingSwitch(
              asset: HardSyncAssets.iconHeartbeatPulseHealth,
              title: 'Start with microphone on',
              subtitle: 'Begin ready to speak.',
              value: settings.micEnabled,
              onChanged: (_) => settings.toggleMic(),
            ),
            const SizedBox(height: 10),
            _SettingSwitch(
              asset: HardSyncAssets.iconLaptopComputer,
              title: 'Start with camera on',
              subtitle: 'Enable visual coaching cues.',
              value: settings.cameraEnabled,
              onChanged: (_) => settings.toggleCamera(),
            ),
            const SizedBox(height: 18),
            Text(
              'Connection readiness',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: HardSyncColors.ink,
              ),
            ),
            const SizedBox(height: 10),
            _ProviderState(
              asset: HardSyncAssets.iconWifiSignal,
              label: 'Audio and video',
              ready: EnvConfig.hasGeminiKey,
            ),
            const SizedBox(height: 8),
            _ProviderState(
              asset: HardSyncAssets.iconBrainAiMind,
              label: 'Coaching intelligence',
              ready: EnvConfig.hasGeminiKey,
            ),
            if (EnvConfig.testCalls) ...[
              const SizedBox(height: 10),
              const Text(
                'Local testing is enabled. Real provider usage still applies.',
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final String asset;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SettingSwitch({
    required this.asset,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: Row(
      children: [
        AppIcon(asset, size: 34),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: HardSyncColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: HardSyncColors.violet,
        ),
      ],
    ),
  );
}

class _ProviderState extends StatelessWidget {
  final String asset;
  final String label;
  final bool ready;
  const _ProviderState({
    required this.asset,
    required this.label,
    required this.ready,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: HardSyncColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: HardSyncColors.border),
    ),
    child: Row(
      children: [
        AppIcon(asset, size: 25),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ready ? HardSyncColors.oliveMist : HardSyncColors.apricotMist,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            ready ? 'Ready' : 'Unavailable',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: ready ? HardSyncColors.olive : HardSyncColors.apricot,
            ),
          ),
        ),
      ],
    ),
  );
}
