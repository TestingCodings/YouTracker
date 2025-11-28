import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/aggregated_metrics.dart';

/// A heatmap-style chart showing engagement patterns by hour and day.
class EngagementPatternChart extends StatelessWidget {
  final EngagementDistribution engagement;

  const EngagementPatternChart({
    super.key,
    required this.engagement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hourly distribution bar chart
        Text(
          'Comments by Hour of Day',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.5,
          child: _buildHourlyChart(theme, isDark),
        ),
        const SizedBox(height: 24),
        
        // Weekly distribution bar chart
        Text(
          'Comments by Day of Week',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 2.0,
          child: _buildWeekdayChart(theme, isDark),
        ),
      ],
    );
  }

  Widget _buildHourlyChart(ThemeData theme, bool isDark) {
    final hourlyData = engagement.hourlyCommentPattern;
    if (hourlyData.isEmpty) {
      return Center(
        child: Text(
          'No hourly data available',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        ),
      );
    }

    final maxCount = hourlyData.values.fold<int>(
        0, (max, v) => v > max ? v : max);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                isDark ? Colors.grey[800]! : Colors.grey[200]!,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final hour = group.x;
              final count = rod.toY.toInt();
              final hourStr = hour == 0 ? '12 AM' : (hour < 12 ? '$hour AM' : (hour == 12 ? '12 PM' : '${hour - 12} PM'));
              return BarTooltipItem(
                '$hourStr\n$count comments',
                TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final hour = value.toInt();
                if (hour % 4 == 0) {
                  final hourStr = hour == 0 ? '12a' : (hour < 12 ? '${hour}a' : (hour == 12 ? '12p' : '${hour - 12}p'));
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      hourStr,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 9,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 22,
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(24, (hour) {
          final count = hourlyData[hour] ?? 0;
          return BarChartGroupData(
            x: hour,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: _getHourColor(hour, theme),
                width: 8,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(2),
                  topRight: Radius.circular(2),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWeekdayChart(ThemeData theme, bool isDark) {
    final weekdayData = engagement.weekdayCommentPattern;
    if (weekdayData.isEmpty) {
      return Center(
        child: Text(
          'No weekly data available',
          style: TextStyle(color: isDark ? Colors.white54 : Colors.black38),
        ),
      );
    }

    final maxCount = weekdayData.values.fold<int>(
        0, (max, v) => v > max ? v : max);

    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxCount * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) =>
                isDark ? Colors.grey[800]! : Colors.grey[200]!,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final dayIndex = group.x;
              final count = rod.toY.toInt();
              return BarTooltipItem(
                '${dayLabels[dayIndex]}\n$count comments',
                TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxCount > 5 ? maxCount / 4 : 1,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < dayLabels.length) {
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      dayLabels[index],
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 25,
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxCount > 5 ? maxCount / 4 : 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: isDark ? Colors.white24 : Colors.black12,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (dayIndex) {
          final count = weekdayData[dayIndex + 1] ?? 0; // weekday is 1-7
          return BarChartGroupData(
            x: dayIndex,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: _getWeekdayColor(dayIndex, theme),
                width: 28,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: maxCount * 1.2,
                  color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Color _getHourColor(int hour, ThemeData theme) {
    // Morning (6-12): yellow/orange
    // Afternoon (12-18): primary color
    // Evening (18-24): purple
    // Night (0-6): dark blue
    if (hour >= 6 && hour < 12) {
      return Colors.orange.shade400;
    } else if (hour >= 12 && hour < 18) {
      return theme.colorScheme.primary;
    } else if (hour >= 18 && hour < 24) {
      return Colors.purple.shade400;
    } else {
      return Colors.indigo.shade400;
    }
  }

  Color _getWeekdayColor(int dayIndex, ThemeData theme) {
    // Weekend days are different color
    if (dayIndex >= 5) {
      return theme.colorScheme.secondary;
    }
    return theme.colorScheme.primary;
  }
}
