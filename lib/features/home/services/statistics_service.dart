import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/history_repository.dart';
import '../../settings/preferences_manager.dart';

/// Time period for statistics
enum StatisticsPeriod {
  week('Week', 7),
  month('Month', 30),
  year('Year', 365),
  allTime('All Time', -1);

  const StatisticsPeriod(this.label, this.days);
  final String label;
  final int days; // -1 means all time
}

/// Statistics data for a specific period
class ShareStatistics {
  final int totalShares;
  final Map<DateTime, int> sharesByDay;
  final double averagePerDay;
  final StatisticsPeriod period;

  const ShareStatistics({
    required this.totalShares,
    required this.sharesByDay,
    required this.averagePerDay,
    required this.period,
  });

  static ShareStatistics empty(StatisticsPeriod period) {
    return ShareStatistics(
      totalShares: 0,
      sharesByDay: {},
      averagePerDay: 0.0,
      period: period,
    );
  }
}

/// Service for calculating sharing statistics
class StatisticsService {
  final HistoryRepository _repository;

  StatisticsService(this._repository);

  /// Get statistics for a specific period
  Future<ShareStatistics> getStatistics(StatisticsPeriod period) async {
    final allShares = await _repository.getShared();

    if (allShares.isEmpty) {
      return ShareStatistics.empty(period);
    }

    // Filter by period
    final now = DateTime.now();
    final filteredShares = period == StatisticsPeriod.allTime
        ? allShares
        : allShares.where((entry) {
            final difference = now.difference(entry.timestamp).inDays;
            return difference <= period.days;
          }).toList();

    if (filteredShares.isEmpty) {
      return ShareStatistics.empty(period);
    }

    // Group by day
    final sharesByDay = <DateTime, int>{};
    for (final entry in filteredShares) {
      final day = DateTime(
        entry.timestamp.year,
        entry.timestamp.month,
        entry.timestamp.day,
      );
      sharesByDay[day] = (sharesByDay[day] ?? 0) + 1;
    }

    // Calculate average
    final totalDays = period == StatisticsPeriod.allTime
        ? now.difference(filteredShares.last.timestamp).inDays + 1
        : period.days;
    final averagePerDay = filteredShares.length / totalDays;

    return ShareStatistics(
      totalShares: filteredShares.length,
      sharesByDay: sharesByDay,
      averagePerDay: averagePerDay,
      period: period,
    );
  }

  /// Get chart data points for a period
  Future<List<ChartDataPoint>> getChartData(StatisticsPeriod period) async {
    final statistics = await getStatistics(period);

    if (statistics.sharesByDay.isEmpty) {
      return [];
    }

    final now = DateTime.now();
    final points = <ChartDataPoint>[];

    if (period == StatisticsPeriod.allTime) {
      // For all time, use actual data points
      final sortedDays = statistics.sharesByDay.keys.toList()
        ..sort((a, b) => a.compareTo(b));

      for (final day in sortedDays) {
        points.add(
          ChartDataPoint(date: day, count: statistics.sharesByDay[day]!),
        );
      }
    } else {
      // For specific periods, fill in missing days with 0
      for (int i = period.days - 1; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day - i);
        points.add(
          ChartDataPoint(date: day, count: statistics.sharesByDay[day] ?? 0),
        );
      }
    }

    return points;
  }
}

/// Data point for chart
class ChartDataPoint {
  final DateTime date;
  final int count;

  const ChartDataPoint({required this.date, required this.count});
}

/// Provider for StatisticsService
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  final repository = ref.watch(historyRepositoryProvider);
  return StatisticsService(repository);
});

/// Provider for current statistics period
final currentPeriodProvider = StateProvider<StatisticsPeriod>((ref) {
  return StatisticsPeriod.week;
});

/// Provider for statistics based on current period
final statisticsProvider = FutureProvider<ShareStatistics>((ref) {
  final service = ref.watch(statisticsServiceProvider);
  final period = ref.watch(currentPeriodProvider);
  return service.getStatistics(period);
});

/// Provider for chart data based on current period
final chartDataProvider = FutureProvider<List<ChartDataPoint>>((ref) {
  final service = ref.watch(statisticsServiceProvider);
  final period = ref.watch(currentPeriodProvider);
  return service.getChartData(period);
});

/// Provider for received statistics based on current period
final receivedStatisticsProvider = FutureProvider<ShareStatistics>((ref) async {
  final repository = ref.watch(historyRepositoryProvider);
  final period = ref.watch(currentPeriodProvider);

  final allReceived = await repository.getReceived();

  if (allReceived.isEmpty) {
    return ShareStatistics.empty(period);
  }

  // Filter by period
  final now = DateTime.now();
  final filteredReceived = period == StatisticsPeriod.allTime
      ? allReceived
      : allReceived.where((entry) {
          final difference = now.difference(entry.timestamp).inDays;
          return difference <= period.days;
        }).toList();

  if (filteredReceived.isEmpty) {
    return ShareStatistics.empty(period);
  }

  // Group by day
  final sharesByDay = <DateTime, int>{};
  for (final entry in filteredReceived) {
    final day = DateTime(
      entry.timestamp.year,
      entry.timestamp.month,
      entry.timestamp.day,
    );
    sharesByDay[day] = (sharesByDay[day] ?? 0) + 1;
  }

  // Calculate average
  final totalDays = period == StatisticsPeriod.allTime
      ? now.difference(filteredReceived.last.timestamp).inDays + 1
      : period.days;
  final averagePerDay = filteredReceived.length / totalDays;

  return ShareStatistics(
    totalShares: filteredReceived.length,
    sharesByDay: sharesByDay,
    averagePerDay: averagePerDay,
    period: period,
  );
});

/// Provider for received chart data based on current period
final receivedChartDataProvider = FutureProvider<List<ChartDataPoint>>((
  ref,
) async {
  final statistics = await ref.watch(receivedStatisticsProvider.future);

  if (statistics.sharesByDay.isEmpty) {
    return [];
  }

  final now = DateTime.now();
  final points = <ChartDataPoint>[];
  final period = statistics.period;

  if (period == StatisticsPeriod.allTime) {
    // For all time, use actual data points
    final sortedDays = statistics.sharesByDay.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    for (final day in sortedDays) {
      points.add(
        ChartDataPoint(date: day, count: statistics.sharesByDay[day]!),
      );
    }
  } else {
    // For specific periods, fill in missing days with 0
    for (int i = period.days - 1; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      points.add(
        ChartDataPoint(date: day, count: statistics.sharesByDay[day] ?? 0),
      );
    }
  }

  return points;
});
