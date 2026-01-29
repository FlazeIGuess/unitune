import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/dynamic_theme.dart';
import '../services/statistics_service.dart';
import 'period_selector.dart';
import 'minimal_trend_graph.dart';
import 'package:intl/intl.dart';

/// Statistics card showing share count and graph with swipeable pages
class StatisticsCard extends ConsumerStatefulWidget {
  const StatisticsCard({super.key});

  @override
  ConsumerState<StatisticsCard> createState() => _StatisticsCardState();
}

class _StatisticsCardState extends ConsumerState<StatisticsCard> {
  int? _selectedIndex;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Ensure full width to match other cards
      padding: EdgeInsets.all(
        AppTheme.spacing.l,
      ), // Changed back to l (24px) to match Info Card width
      decoration: BoxDecoration(
        color: AppTheme.colors.glassBase,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.colors.glassBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch, // Changed from start to stretch
        children: [
          // Swipeable Content
          SizedBox(
            height: 300,
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                  _selectedIndex = null; // Reset selection on page change
                });
              },
              children: [
                _buildStatisticsPage(
                  title: 'Songs Shared',
                  statisticsProvider: statisticsProvider,
                  chartDataProvider: chartDataProvider,
                ),
                _buildStatisticsPage(
                  title: 'Songs Received',
                  statisticsProvider: receivedStatisticsProvider,
                  chartDataProvider: receivedChartDataProvider,
                ),
              ],
            ),
          ),

          SizedBox(height: AppTheme.spacing.s),
          // Page Indicator Dots at bottom
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPageDot(0),
                SizedBox(width: 8),
                _buildPageDot(1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageDot(int index) {
    final isActive = _currentPage == index;
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive
              ? context.primaryColor
              : AppTheme.colors.textMuted.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Widget _buildStatisticsPage({
    required String title,
    required FutureProvider<ShareStatistics> statisticsProvider,
    required FutureProvider<List<ChartDataPoint>> chartDataProvider,
  }) {
    final statisticsAsync = ref.watch(statisticsProvider);
    final chartDataAsync = ref.watch(chartDataProvider);
    final currentPeriod = ref.watch(currentPeriodProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title - Left aligned and larger
        Text(
          title,
          style: AppTheme.typography.displayLarge.copyWith(
            color: AppTheme.colors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 28,
          ),
        ),
        SizedBox(height: AppTheme.spacing.m),
        // Period Selector
        const PeriodSelector(),
        SizedBox(height: AppTheme.spacing.l),
        // Statistics Number
        statisticsAsync.when(
          data: (statistics) =>
              _buildStatisticsHeader(statistics, chartDataAsync.value),
          loading: () => _buildLoadingHeader(),
          error: (_, __) => _buildErrorHeader(),
        ),
        SizedBox(height: AppTheme.spacing.m),
        // Graph
        chartDataAsync.when(
          data: (chartData) => MinimalTrendGraph(
            data: chartData.map((e) => e.count.toDouble()).toList(),
            labels: chartData
                .map((e) => _formatLabel(e.date, currentPeriod))
                .toList(),
            lineColor: context.primaryColor,
            gradientStartColor: context.primaryColor.withValues(alpha: 0.3),
            gradientEndColor: context.primaryColor.withValues(alpha: 0.0),
            height: 120, // Increased for better visibility
            onPointSelected: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
          loading: () => _buildLoadingGraph(),
          error: (_, __) => _buildErrorGraph(),
        ),
      ],
    );
  }

  Widget _buildStatisticsHeader(
    ShareStatistics statistics,
    List<ChartDataPoint>? chartData,
  ) {
    // Show selected point data if available
    if (_selectedIndex != null &&
        chartData != null &&
        _selectedIndex! < chartData.length) {
      final selectedPoint = chartData[_selectedIndex!];
      final label = _formatLabel(selectedPoint.date, statistics.period);

      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Selected value
          Text(
            selectedPoint.count.toString(),
            style: AppTheme.typography.displayLarge.copyWith(
              color: context.primaryColor,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          SizedBox(width: 8),
          // Selected label (date/time)
          Text(
            label,
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // Default: show total
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Big number
        Text(
          statistics.totalShares.toString(),
          style: AppTheme.typography.displayLarge.copyWith(
            color: AppTheme.colors.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        if (statistics.totalShares > 0 &&
            statistics.period != StatisticsPeriod.allTime) ...[
          SizedBox(width: 8),
          Text(
            '${statistics.averagePerDay.toStringAsFixed(1)} per day',
            style: AppTheme.typography.bodyMedium.copyWith(
              color: AppTheme.colors.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  String _formatLabel(DateTime date, StatisticsPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    }

    switch (period) {
      case StatisticsPeriod.week:
        return DateFormat('EEEE').format(date); // Monday, Tuesday, etc.
      case StatisticsPeriod.month:
        return DateFormat('MMM d').format(date); // Jan 15
      case StatisticsPeriod.year:
      case StatisticsPeriod.allTime:
        return DateFormat('MMM yyyy').format(date); // Jan 2024
    }
  }

  Widget _buildLoadingHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.colors.glassBase,
            borderRadius: BorderRadius.circular(AppTheme.radii.medium),
          ),
        ),
        SizedBox(height: AppTheme.spacing.xs),
        Container(
          width: 100,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.colors.glassBase,
            borderRadius: BorderRadius.circular(AppTheme.radii.small),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorHeader() {
    return Text(
      'Error loading statistics',
      style: AppTheme.typography.bodyMedium.copyWith(
        color: AppTheme.colors.accentError,
      ),
    );
  }

  Widget _buildLoadingGraph() {
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(color: context.primaryColor),
      ),
    );
  }

  Widget _buildErrorGraph() {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          'Error loading graph',
          style: AppTheme.typography.bodyMedium.copyWith(
            color: AppTheme.colors.accentError,
          ),
        ),
      ),
    );
  }
}
