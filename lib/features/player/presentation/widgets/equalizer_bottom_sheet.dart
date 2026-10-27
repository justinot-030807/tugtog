import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../player_controller.dart';

/// Bottom sheet dialog for adjusting Android hardware equalizer bands and presets.
class EqualizerBottomSheet extends ConsumerStatefulWidget {
  const EqualizerBottomSheet({super.key});

  @override
  ConsumerState<EqualizerBottomSheet> createState() =>
      _EqualizerBottomSheetState();
}

class _EqualizerBottomSheetState extends ConsumerState<EqualizerBottomSheet> {
  bool _isLoading = true;
  bool _isEnabled = false;
  AndroidEqualizerParameters? _parameters;
  final Map<int, double> _bandGains = {};
  String _selectedPreset = 'Flat';

  @override
  void initState() {
    super.initState();
    _loadEqualizer();
  }

  Future<void> _loadEqualizer() async {
    final controller = ref.read(playerControllerProvider.notifier);
    final eq = controller.equalizer;

    if (eq != null) {
      try {
        final enabled = eq.enabled;
        final params = await controller.getEqualizerParameters();
        if (mounted) {
          setState(() {
            _isEnabled = enabled;
            _parameters = params;
            if (params != null) {
              for (var i = 0; i < params.bands.length; i++) {
                _bandGains[i] = params.bands[i].gain;
              }
            }
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleEnabled(bool enabled) async {
    final controller = ref.read(playerControllerProvider.notifier);
    await controller.setEqualizerEnabled(enabled);
    setState(() => _isEnabled = enabled);
  }

  Future<void> _setBandGain(int index, double gain) async {
    final controller = ref.read(playerControllerProvider.notifier);
    await controller.setEqualizerBandGain(index, gain);
    setState(() {
      _bandGains[index] = gain;
      _selectedPreset = 'Custom';
    });
  }

  Future<void> _applyPreset(String preset) async {
    if (_parameters == null) return;
    final bandsCount = _parameters!.bands.length;
    final Map<int, double> targetGains = {};

    switch (preset) {
      case 'Flat':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = 0.0;
        }
        break;
      case 'Bass Boost':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = i < 2 ? 6.0 : (i == 2 ? 2.0 : 0.0);
        }
        break;
      case 'Treble Boost':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = i >= bandsCount - 2 ? 6.0 : 0.0;
        }
        break;
      case 'Vocal':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i >= 1 && i <= 3) ? 5.0 : -1.0;
        }
        break;
      case 'Rock':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i == 0 || i == bandsCount - 1) ? 5.0 : 1.0;
        }
        break;
    }

    for (final entry in targetGains.entries) {
      await ref
          .read(playerControllerProvider.notifier)
          .setEqualizerBandGain(entry.key, entry.value);
    }

    setState(() {
      _selectedPreset = preset;
      _bandGains.addAll(targetGains);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header & Enable Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.equalizer, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Equalizer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (_parameters != null)
                  Switch(
                    value: _isEnabled,
                    activeThumbColor: AppColors.primary,
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                    onChanged: _toggleEnabled,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (_parameters == null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hardware Equalizer is not supported on this device/emulator. Tugtog utilizes native Android media audiofx when available.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else ...[
              // Preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    'Flat',
                    'Bass Boost',
                    'Treble Boost',
                    'Vocal',
                    'Rock',
                  ].map((preset) {
                    final isSelected = _selectedPreset == preset;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(preset),
                        selected: isSelected,
                        selectedColor: AppColors.primary.withValues(alpha: 0.3),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 12,
                        ),
                        onSelected: _isEnabled
                            ? (_) => _applyPreset(preset)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Frequency Band Sliders
              SizedBox(
                height: 170,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(_parameters!.bands.length, (index) {
                    final band = _parameters!.bands[index];
                    final gain = _bandGains[index] ?? band.gain;
                    final freqHz = band.centerFrequency;
                    final freqLabel = freqHz >= 1000
                        ? '${(freqHz / 1000).toStringAsFixed(1)}k'
                        : '$freqHz';

                    return Column(
                      children: [
                        Text(
                          '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(0)}dB',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: gain
                                  .clamp(_parameters!.minDecibels,
                                      _parameters!.maxDecibels)
                                  .toDouble(),
                              min: _parameters!.minDecibels,
                              max: _parameters!.maxDecibels,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.surfaceElevated,
                              onChanged: _isEnabled
                                  ? (val) => _setBandGain(index, val)
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          freqLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
