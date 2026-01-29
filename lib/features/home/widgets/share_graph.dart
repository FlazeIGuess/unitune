import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../services/statistics_service.dart';

/// Interactive share graph with scrubbing support
class ShareGraph extends StatefulWidget {
  final List<ChartDataPoint> data;
  final StatisticsPeriod period;

  const ShareGraph({super.key, required this.data, required this.period});

  @override
  State<ShareGraph> createState() => _ShareGraphState();
}

class _ShareGraphState extends State<ShareGraph> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState();
    }

    final maxY = widget.data
        .map((e) => e.count)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final spots = widget.data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.count.toDouble());
    }).toList();

    return LiquidGlass.withOwnLayer(
      settings: const LiquidGlassSettings(
        blur: 8,
        ambientStrength: 0.4,
        glassColor: Color(0x0DFFFFFF),
        thickness: 8,
        lightIntensity: 0.4,
        saturation: 1.2,
        refractiveIndex: 1.1,
      ),
      shape: LiquidRoundedSuperellipse(borderRadius: 16),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.white.withValues(alpha: 0.05),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: _getBottomInterval(),
                  getTitlesWidget: (value, meta) {
                    return _buildBottomTitle(value.toInt());
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: maxY > 0 ? maxY / 4 : 1,
                  getTitlesWidget: (value, meta) {
                    if (value == 0) return const SizedBox.shrink();
                    return Text(
                      value.toInt().toString(),
                      style: AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textMuted,
                        fontSize: 9,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (widget.data.length - 1).toDouble(),
            minY: 0,
            maxY: maxY > 0 ? maxY * 1.2 : 10,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: context.primaryColor,
                barWidth: 2,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isHighlighted = _touchedIndex == index;
                    return FlDotCirclePainter(
                      radius: isHighlighted ? 4 : 2,
                      color: context.primaryColor,
                      strokeWidth: isHighlighted ? 1.5 : 0,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.primaryColor.withValues(alpha: 0.3),
                      context.primaryColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchCallback: (event, response) {
                if (response?.lineBarSpots != null &&
                    response!.lineBarSpots!.isNotEmpty) {
                  final index = response.lineBarSpots!.first.spotIndex;
                  if (_touchedIndex != index) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _touchedIndex = index;
                    });
                  }
                } else {
                  setState(() {
                    _touchedIndex = null;
                  });
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (touchedSpot) =>
                    AppTheme.colors.backgroundCard,
                tooltipRoundedRadius: 12,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final dataPoint = widget.data[spot.spotIndex];
                    final dateStr = _formatDate(dataPoint.date);
                    final count = dataPoint.count;

                    return LineTooltipItem(
                      '$count ${count == 1 ? 'song' : 'songs'}\n$dateStr',
                      AppTheme.typography.labelMedium.copyWith(
                        color: AppTheme.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }).toList();
                },
              ),
            ),
          ),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.show_chart,
              size: 32,
              color: AppTheme.colors.textMuted.withValues(alpha: 0.3),
            ),
            SizedBox(height: AppTheme.spacing.s),
            Text(
              'No shares yet',
              style: AppTheme.typography.bodyMedium.copyWith(
                color: AppTheme.colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getBottomInterval() {
    final length = widget.data.length;
    if (length <= 7) return 1;
    if (length <= 30) return 7;
    if (length <= 90) return 30;
    return 60;
  }

  Widget _buildBottomTitle(int index) {
    if (index < 0 || index >= widget.data.length) {
      return const SizedBox.shrink();
    }

    final date = widget.data[index].date;
    String label;

    switch (widget.period) {
      case StatisticsPeriod.week:
        label = DateFormat('E').format(date).substring(0, 1); // M, T, W, ...
        break;
      case StatisticsPeriod.month:
        label = DateFormat('d').format(date); // 1, 8, 15, ...
        break;
      case StatisticsPeriod.year:
        label = DateFormat('MMM').format(date).substring(0, 1); // J, F, M, ...
        break;
      case StatisticsPeriod.allTime:
        label = DateFormat('MMM').format(date).substring(0, 1);
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: AppTheme.typography.labelMedium.copyWith(
          color: AppTheme.colors.textMuted,
          fontSize: 9,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
