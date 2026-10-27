import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../sleep_timer_notifier.dart';

/// Bottom sheet dialog allowing selection of sleep timer duration or turning it off.
class SleepTimerBottomSheet extends ConsumerWidget {
  const SleepTimerBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    final notifier = ref.read(sleepTimerProvider.notifier);

    final options = [
      {'label': '5 minutes', 'duration': const Duration(minutes: 5)},
      {'label': '10 minutes', 'duration': const Duration(minutes: 10)},
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
      {'label': '45 minutes', 'duration': const Duration(minutes: 45)},
      {'label': '1 hour', 'duration': const Duration(hours: 1)},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

            // Title & Active remaining badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.bedtime_outlined, color: AppColors.primary, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Stop audio in',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (timerState.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      timerState.formattedRemaining,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Preset options
            ...options.map((opt) {
              final label = opt['label'] as String;
              final duration = opt['duration'] as Duration;
              final isSelected = timerState.isActive && timerState.activeLabel == label;

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  notifier.setTimer(duration, label);
                  Navigator.pop(context);
                },
              );
            }),

            // End of track option
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              title: Text(
                'End of track',
                style: TextStyle(
                  color: (timerState.isActive && timerState.isEndOfTrack)
                      ? AppColors.primary
                      : AppColors.textPrimary,
                  fontWeight: (timerState.isActive && timerState.isEndOfTrack)
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 15,
                ),
              ),
              trailing: (timerState.isActive && timerState.isEndOfTrack)
                  ? const Icon(Icons.check, color: AppColors.primary, size: 20)
                  : null,
              onTap: () {
                notifier.setEndOfTrack();
                Navigator.pop(context);
              },
            ),

            // Turn off option (only if currently active)
            if (timerState.isActive)
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Text(
                  'Turn off timer',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                onTap: () {
                  notifier.cancelTimer();
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }
}
