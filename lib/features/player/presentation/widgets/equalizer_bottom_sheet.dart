import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../player_controller.dart';

/// Descriptor for an equalizer frequency band.
class EqBandInfo {
  final int index;
  final double centerFrequency;
  final String label;
  final double minDecibels;
  final double maxDecibels;

  const EqBandInfo({
    required this.index,
    required this.centerFrequency,
    required this.label,
    this.minDecibels = -10.0,
    this.maxDecibels = 10.0,
  });
}

/// Spotify-style Equalizer Bottom Sheet supporting hardware DSP, custom presets,
/// real-time 5-band slider adjustments, and direct system sound effects (Dolby Atmos / Mi Sound) integration.
class EqualizerBottomSheet extends ConsumerStatefulWidget {
  const EqualizerBottomSheet({super.key});

  @override
  ConsumerState<EqualizerBottomSheet> createState() =>
      _EqualizerBottomSheetState();
}

class _EqualizerBottomSheetState extends ConsumerState<EqualizerBottomSheet> {
  bool _isLoading = true;
  bool _isEnabled = true;
  bool _isHardwareSupported = false;
  AndroidEqualizerParameters? _parameters;
  final Map<int, double> _bandGains = {};
  String _selectedPreset = 'Flat';

  static const List<String> _presets = [
    'Flat',
    'Bass Boost',
    'Treble Boost',
    'Vocal',
    'Rock',
    'Pop',
    'Electronic',
    'Hip-Hop',
  ];

  static const List<EqBandInfo> _defaultBands = [
    EqBandInfo(index: 0, centerFrequency: 60, label: '60Hz'),
    EqBandInfo(index: 1, centerFrequency: 230, label: '230Hz'),
    EqBandInfo(index: 2, centerFrequency: 910, label: '910Hz'),
    EqBandInfo(index: 3, centerFrequency: 3600, label: '3.6kHz'),
    EqBandInfo(index: 4, centerFrequency: 14000, label: '14kHz'),
  ];

  @override
  void initState() {
    super.initState();
    _loadEqualizer();
  }

  Future<void> _loadEqualizer() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEnabled = prefs.getBool('tugtog_eq_enabled') ?? true;
    final savedPreset = prefs.getString('tugtog_eq_preset') ?? 'Flat';

    final controller = ref.read(playerControllerProvider.notifier);
    final eq = controller.equalizer;

    AndroidEqualizerParameters? params;
    bool hwSupported = false;

    if (eq != null) {
      try {
        params = await controller.getEqualizerParameters();
        if (params != null && params.bands.isNotEmpty) {
          hwSupported = true;
          await controller.setEqualizerEnabled(savedEnabled);
        }
      } catch (_) {}
    }

    final bandsCount = (params != null && params.bands.isNotEmpty)
        ? params.bands.length
        : _defaultBands.length;

    for (var i = 0; i < bandsCount; i++) {
      final savedGain = prefs.getDouble('tugtog_eq_band_$i');
      if (savedGain != null) {
        _bandGains[i] = savedGain;
        if (hwSupported) {
          await controller.setEqualizerBandGain(i, savedGain);
        }
      } else if (params != null && i < params.bands.length) {
        _bandGains[i] = params.bands[i].gain;
      } else {
        _bandGains[i] = 0.0;
      }
    }

    if (mounted) {
      setState(() {
        _isEnabled = savedEnabled;
        _selectedPreset = savedPreset;
        _parameters = params;
        _isHardwareSupported = hwSupported;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEnabled(bool enabled) async {
    final controller = ref.read(playerControllerProvider.notifier);
    await controller.setEqualizerEnabled(enabled);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tugtog_eq_enabled', enabled);

    setState(() => _isEnabled = enabled);
  }

  Future<void> _setBandGain(int index, double gain) async {
    final controller = ref.read(playerControllerProvider.notifier);
    if (_isHardwareSupported) {
      await controller.setEqualizerBandGain(index, gain);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tugtog_eq_band_$index', gain);
    await prefs.setString('tugtog_eq_preset', 'Custom');

    setState(() {
      _bandGains[index] = gain;
      _selectedPreset = 'Custom';
    });
  }

  Future<void> _applyPreset(String preset) async {
    final bandsCount = _effectiveBands.length;
    final Map<int, double> targetGains = {};

    switch (preset) {
      case 'Flat':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = 0.0;
        }
        break;
      case 'Bass Boost':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = i == 0 ? 6.0 : (i == 1 ? 4.0 : (i == 2 ? 1.0 : 0.0));
        }
        break;
      case 'Treble Boost':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = i >= bandsCount - 1 ? 6.0 : (i >= bandsCount - 2 ? 4.0 : 0.0);
        }
        break;
      case 'Vocal':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i == 2) ? 5.0 : ((i == 1 || i == 3) ? 3.0 : 0.0);
        }
        break;
      case 'Rock':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i == 0 || i == bandsCount - 1) ? 5.0 : (i == 1 ? 2.5 : -1.0);
        }
        break;
      case 'Pop':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i == 1 || i == 2) ? 4.0 : (i == 3 ? 2.0 : -1.0);
        }
        break;
      case 'Electronic':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = (i == 0 || i == bandsCount - 1) ? 5.0 : (i == 1 ? 3.0 : 1.0);
        }
        break;
      case 'Hip-Hop':
        for (var i = 0; i < bandsCount; i++) {
          targetGains[i] = i == 0 ? 6.0 : (i == 1 ? 4.0 : (i == 4 ? 3.0 : 0.0));
        }
        break;
    }

    final controller = ref.read(playerControllerProvider.notifier);
    final prefs = await SharedPreferences.getInstance();

    for (final entry in targetGains.entries) {
      if (_isHardwareSupported) {
        await controller.setEqualizerBandGain(entry.key, entry.value);
      }
      await prefs.setDouble('tugtog_eq_band_${entry.key}', entry.value);
    }
    await prefs.setString('tugtog_eq_preset', preset);

    setState(() {
      _selectedPreset = preset;
      _bandGains.addAll(targetGains);
    });
  }

  Future<void> _handleOpenSystemEqualizer() async {
    final controller = ref.read(playerControllerProvider.notifier);
    final opened = await controller.openSystemEqualizer();

    if (!mounted) return;
    if (opened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening System Sound Effects & Equalizer panel...'),
          backgroundColor: AppColors.surfaceElevated,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System sound panel not detected. Tugtog In-App Equalizer is active.'),
          backgroundColor: AppColors.surfaceElevated,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  List<EqBandInfo> get _effectiveBands {
    if (_parameters != null && _parameters!.bands.isNotEmpty) {
      return List.generate(_parameters!.bands.length, (i) {
        final b = _parameters!.bands[i];
        final freq = b.centerFrequency;
        final label = freq >= 1000
            ? '${(freq / 1000).toStringAsFixed(1)}kHz'
            : '${freq.round()}Hz';
        return EqBandInfo(
          index: i,
          centerFrequency: freq,
          label: label,
          minDecibels: _parameters!.minDecibels,
          maxDecibels: _parameters!.maxDecibels,
        );
      });
    }
    return _defaultBands;
  }

  @override
  Widget build(BuildContext context) {
    final bands = _effectiveBands;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.equalizer_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Equalizer',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          _isHardwareSupported
                              ? 'Hardware Audio DSP Active'
                              : 'In-App 5-Band Audio Equalizer',
                          style: TextStyle(
                            fontSize: 11,
                            color: _isHardwareSupported
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isEnabled,
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
                  onChanged: _toggleEnabled,
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else ...[
              // Preset chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: _presets.map((preset) {
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
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.1),
                        ),
                        backgroundColor: AppColors.surfaceElevated,
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
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
                height: 200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(bands.length, (index) {
                    final band = bands[index];
                    final gain = _bandGains[index] ?? 0.0;
                    final minDb = band.minDecibels;
                    final maxDb = band.maxDecibels;

                    return Column(
                      children: [
                        Text(
                          '${gain > 0 ? '+' : ''}${gain.toStringAsFixed(0)}dB',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _isEnabled
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              value: gain.clamp(minDb, maxDb).toDouble(),
                              min: minDb,
                              max: maxDb,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.background,
                              onChanged: _isEnabled
                                  ? (val) => _setBandGain(index, val)
                                  : null,
                            ),
                          ),
                        ),
                        Text(
                          band.label,
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
              const SizedBox(height: 16),

              // Button to open Device System Equalizer (Dolby Atmos / Mi Sound Enhancer)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _handleOpenSystemEqualizer,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text(
                    'Open System Equalizer / Dolby Atmos',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
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
