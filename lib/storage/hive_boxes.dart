/// Hive box names for the analytics module.
class HiveBoxNames {
  /// Box for storing aggregated metrics.
  static const String aggregatedMetrics = 'aggregated_metrics';
  
  /// Key prefix for daily metrics.
  static const String dailyPrefix = 'metrics_daily_';
  
  /// Key prefix for weekly metrics.
  static const String weeklyPrefix = 'metrics_weekly_';
  
  /// Key prefix for monthly metrics.
  static const String monthlyPrefix = 'metrics_monthly_';
  
  /// Generate a key for a metrics entry.
  static String metricsKey(PeriodType periodType, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    switch (periodType) {
      case PeriodType.daily:
        return '$dailyPrefix$dateStr';
      case PeriodType.weekly:
        return '$weeklyPrefix$dateStr';
      case PeriodType.monthly:
        return '$monthlyPrefix$dateStr';
    }
  }
}

/// Period types for aggregation.
enum PeriodType {
  daily,
  weekly,
  monthly,
}
