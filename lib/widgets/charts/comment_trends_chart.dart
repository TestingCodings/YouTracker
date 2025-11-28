import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/aggregated_metrics.dart';

/// A line chart showing comment trends over time.
class CommentTrendsChart extends StatelessWidget {
  final List<AggregatedMetrics> metrics;
  final bool showReplies;

  const CommentTrendsChart({
    super.key,
    required this.metrics,
    this.showReplies = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (metrics.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final sortedMetrics = List<AggregatedMetrics>.from(metrics)
      ..sort((a, b) => a.date.compareTo(b.date));

    final commentSpots = <FlSpot>[];
    final replySpots = <FlSpot>[];

    for (var i = 0; i < sortedMetrics.length; i++) {
      commentSpots.add(FlSpot(i.toDouble(), sortedMetrics[i].totalComments.toDouble()));
      replySpots.add(FlSpot(i.toDouble(), sortedMetrics[i].totalReplies.toDouble()));
    }

    final maxY = sortedMetrics.fold<double>(0, (max, m) {
      final total = m.totalComments + m.totalReplies;
      return total > max ? total.toDouble() : max;
    });

    return AspectRatio(
      aspectRatio: 1.6,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: maxY > 10 ? maxY / 5 : 2,
              verticalInterval: sortedMetrics.length > 7 ? (sortedMetrics.length / 7).ceilToDouble() : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.white24 : Colors.black12,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.white24 : Colors.black12,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  interval: sortedMetrics.length > 7 ? (sortedMetrics.length / 7).ceilToDouble() : 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < sortedMetrics.length) {
                      final date = sortedMetrics[index].date;
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          DateFormat('M/d').format(date),
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: maxY > 10 ? maxY / 5 : 2,
                  reservedSize: 35,
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
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
            ),
            minX: 0,
            maxX: (sortedMetrics.length - 1).toDouble(),
            minY: 0,
            maxY: maxY * 1.1,
            lineBarsData: [
              LineChartBarData(
                spots: commentSpots,
                isCurved: true,
                color: theme.colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: sortedMetrics.length <= 14,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: theme.colorScheme.primary,
                      strokeWidth: 2,
                      strokeColor: theme.colorScheme.onPrimary,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withAlpha(51),
                ),
              ),
              if (showReplies)
                LineChartBarData(
                  spots: replySpots,
                  isCurved: true,
                  color: theme.colorScheme.secondary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: sortedMetrics.length <= 14,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: theme.colorScheme.secondary,
                        strokeWidth: 2,
                        strokeColor: theme.colorScheme.onSecondary,
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: theme.colorScheme.secondary.withAlpha(51),
                  ),
                ),
            ],
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => isDark ? Colors.grey[800]! : Colors.grey[200]!,
                tooltipRoundedRadius: 8,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final isComment = spot.barIndex == 0;
                    return LineTooltipItem(
                      '${isComment ? 'Comments' : 'Replies'}: ${spot.y.toInt()}',
                      TextStyle(
                        color: isComment 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
