import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// A chart showing sentiment distribution across comments.
class SentimentDistributionChart extends StatelessWidget {
  final int positiveCount;
  final int neutralCount;
  final int negativeCount;
  final int questionsCount;
  final int toxicCount;

  const SentimentDistributionChart({
    super.key,
    required this.positiveCount,
    required this.neutralCount,
    required this.negativeCount,
    this.questionsCount = 0,
    this.toxicCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = positiveCount + neutralCount + negativeCount + questionsCount;
    
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sentiment_neutral,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              'No sentiment data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final sections = <PieChartSectionData>[];

    if (positiveCount > 0) {
      sections.add(_buildSection(
        context,
        value: positiveCount.toDouble(),
        color: Colors.green,
        title: 'Positive',
        total: total,
      ));
    }
    if (neutralCount > 0) {
      sections.add(_buildSection(
        context,
        value: neutralCount.toDouble(),
        color: Colors.grey,
        title: 'Neutral',
        total: total,
      ));
    }
    if (negativeCount > 0) {
      sections.add(_buildSection(
        context,
        value: negativeCount.toDouble(),
        color: Colors.red,
        title: 'Negative',
        total: total,
      ));
    }
    if (questionsCount > 0) {
      sections.add(_buildSection(
        context,
        value: questionsCount.toDouble(),
        color: Colors.blue,
        title: 'Questions',
        total: total,
      ));
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildLegend(context, total),
        if (toxicCount > 0) ...[
          const SizedBox(height: 12),
          _buildToxicWarning(context),
        ],
      ],
    );
  }

  PieChartSectionData _buildSection(
    BuildContext context, {
    required double value,
    required Color color,
    required String title,
    required int total,
  }) {
    final percentage = (value / total * 100).round();
    
    return PieChartSectionData(
      value: value,
      color: color,
      radius: 60,
      title: '$percentage%',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );
  }

  Widget _buildLegend(BuildContext context, int total) {
    final theme = Theme.of(context);
    
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        if (positiveCount > 0)
          _LegendItem(
            color: Colors.green,
            label: 'Positive ($positiveCount)',
          ),
        if (neutralCount > 0)
          _LegendItem(
            color: Colors.grey,
            label: 'Neutral ($neutralCount)',
          ),
        if (negativeCount > 0)
          _LegendItem(
            color: Colors.red,
            label: 'Negative ($negativeCount)',
          ),
        if (questionsCount > 0)
          _LegendItem(
            color: Colors.blue,
            label: 'Questions ($questionsCount)',
          ),
      ],
    );
  }

  Widget _buildToxicWarning(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Text(
            '$toxicCount toxic comment${toxicCount > 1 ? 's' : ''} detected',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
