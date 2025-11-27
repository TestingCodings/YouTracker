import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A pie chart showing sentiment distribution.
class SentimentPieChart extends StatelessWidget {
  /// Sentiment score from -1.0 to 1.0.
  final double sentimentScore;

  const SentimentPieChart({
    super.key,
    required this.sentimentScore,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Convert sentiment score to percentages
    // Score of 1.0 = 100% positive, -1.0 = 100% negative
    final normalizedScore = (sentimentScore + 1) / 2; // 0 to 1
    final positivePercent = (normalizedScore * 100).clamp(0, 100);
    final negativePercent = 100 - positivePercent;

    String sentimentLabel;
    Color sentimentColor;
    IconData sentimentIcon;

    if (sentimentScore > 0.3) {
      sentimentLabel = 'Positive';
      sentimentColor = Colors.green;
      sentimentIcon = Icons.sentiment_satisfied_alt;
    } else if (sentimentScore < -0.3) {
      sentimentLabel = 'Negative';
      sentimentColor = Colors.red;
      sentimentIcon = Icons.sentiment_dissatisfied;
    } else {
      sentimentLabel = 'Neutral';
      sentimentColor = Colors.amber;
      sentimentIcon = Icons.sentiment_neutral;
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: Column(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(
                    color: Colors.green.shade400,
                    value: positivePercent,
                    title: '${positivePercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: positivePercent > 15
                        ? const Icon(Icons.thumb_up, color: Colors.white, size: 16)
                        : null,
                    badgePositionPercentageOffset: 1.2,
                  ),
                  PieChartSectionData(
                    color: Colors.red.shade400,
                    value: negativePercent,
                    title: '${negativePercent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    badgeWidget: negativePercent > 15
                        ? const Icon(Icons.thumb_down, color: Colors.white, size: 16)
                        : null,
                    badgePositionPercentageOffset: 1.2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(sentimentIcon, color: sentimentColor, size: 24),
              const SizedBox(width: 8),
              Text(
                'Overall: $sentimentLabel',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: sentimentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(
                color: Colors.green.shade400,
                label: 'Positive',
                isDark: isDark,
              ),
              const SizedBox(width: 16),
              _LegendItem(
                color: Colors.red.shade400,
                label: 'Negative',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool isDark;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
