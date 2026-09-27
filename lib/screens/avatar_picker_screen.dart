import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme/hardsync_assets.dart';
import '../theme/hardsync_theme.dart';

/// Shown once, right after a user finishes signing up (or the first time an
/// existing account has no avatar set). Lets them pick a preset avatar or
/// skip entirely. [onDone] is called once the choice (or skip) has been
/// applied, so the caller can move on to the app.
class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  String? _selectedPreset;
  bool _saving = false;
  String? _error;

  void _choosePreset(String asset) {
    setState(() {
      _selectedPreset = asset;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_selectedPreset == null || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await SupabaseService.instance.updateOwnProfile({
        'avatar_url': _selectedPreset,
      });
      widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = "Couldn't save your avatar. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HardSyncColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _saving ? null : widget.onDone,
                      child: const Text('Skip'),
                    ),
                  ),
                  Text(
                    'Pick your avatar',
                    style: TextStyle(
                      color: HardSyncColors.ink,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Choose one of ours, or skip for now.',
                    style: TextStyle(
                      color: HardSyncColors.inkMuted,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Expanded(
                    child: SingleChildScrollView(
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: HardSyncAssets.avatarPresets.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                        ),
                        itemBuilder: (context, index) {
                          final asset = HardSyncAssets.avatarPresets[index];
                          final selected = _selectedPreset == asset;
                          return GestureDetector(
                            onTap: _saving ? null : () => _choosePreset(asset),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                AppAvatar(
                                  asset,
                                  size: 64,
                                  borderWidth: selected ? 3 : 2,
                                  borderColor: selected
                                      ? HardSyncColors.violet
                                      : Colors.white,
                                ),
                                if (selected)
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: HardSyncColors.violet,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        size: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: HardSyncColors.crimson,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: HardSyncColors.ink,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        disabledBackgroundColor:
                            HardSyncColors.ink.withValues(alpha: .35),
                      ),
                      onPressed: (_selectedPreset != null && !_saving)
                          ? _save
                          : null,
                      child: _saving
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
