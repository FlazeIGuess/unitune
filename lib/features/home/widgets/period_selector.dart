import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../services/statistics_service.dart';

/// Period selector for statistics
/// Similar design to History Tab Bar
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPeriod = ref.watch(currentPeriodProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize:
            MainAxisSize.max, // Changed from min to max for full width
        children: StatisticsPeriod.values.map((period) {
          final isSelected = currentPeriod == period;
          return Expanded(
            // Wrap each tab in Expanded for equal width
            child: _PeriodTab(
              period: period,
              isSelected: isSelected,
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(currentPeriodProvider.notifier).state = period;
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  final StatisticsPeriod period;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeriodTab({
    required this.period,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          // Center the text
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
            style: AppTheme.typography.labelMedium.copyWith(
              color: isSelected
                  ? context.primaryColor
                  : AppTheme.colors.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
            child: Text(
              period.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
