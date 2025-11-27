import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/aggregated_metrics.dart';

/// A bar chart showing top videos by comment count.
class TopVideosBarChart extends StatelessWidget {
  final List<TopVideo> topVideos;
  final int maxItems;

  const TopVideosBarChart({
    super.key,
    required this.topVideos,
    this.maxItems = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (topVideos.isEmpty) {
      return const Center(child: Text('No video data available'));
    }

    final displayVideos = topVideos.take(maxItems).toList();
    final maxValue = displayVideos.fold<int>(0, (max, v) => v.commentCount > max ? v.commentCount : max);

    return AspectRatio(
      aspectRatio: 1.4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxValue * 1.2,
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => isDark ? Colors.grey[800]! : Colors.grey[200]!,
                tooltipRoundedRadius: 8,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final video = displayVideos[group.x];
                  return BarTooltipItem(
                    '${video.videoTitle}\n${video.commentCount} comments',
                    TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < displayVideos.length) {
                      final title = displayVideos[index].videoTitle;
                      return SideTitleWidget(
                        meta: meta,
                        child: SizedBox(
                          width: 60,
                          child: Text(
                            title.length > 12 ? '${title.substring(0, 12)}...' : title,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontSize: 9,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 35,
                  interval: maxValue > 5 ? maxValue / 5 : 1,
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxValue > 5 ? maxValue / 5 : 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: isDark ? Colors.white24 : Colors.black12,
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(displayVideos.length, (index) {
              final video = displayVideos[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: video.commentCount.toDouble(),
                    color: _getBarColor(index, theme),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxValue * 1.2,
                      color: isDark ? Colors.white10 : Colors.black.withAlpha(13),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Color _getBarColor(int index, ThemeData theme) {
    final colors = [
      theme.colorScheme.primary,
      theme.colorScheme.secondary,
      theme.colorScheme.tertiary,
      Colors.orange,
      Colors.purple,
    ];
    return colors[index % colors.length];
  }
}
