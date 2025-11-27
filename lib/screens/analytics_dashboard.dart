import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/aggregated_metrics.dart';
import '../services/analytics_service.dart';
import '../storage/hive_boxes.dart';
import '../widgets/charts/charts.dart';

/// Analytics Dashboard screen showing various metrics and charts.
class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  PeriodType _selectedPeriod = PeriodType.daily;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<AggregatedMetrics> _metrics = [];
  String? _error;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AnalyticsService.instance.initialize();

      // First try to get cached metrics
      var metrics = await AnalyticsService.instance.getAggregatedMetrics(
        _selectedPeriod,
        _startDate,
        _endDate,
      );

      // If no cached metrics, aggregate from comments
      if (metrics.isEmpty) {
        metrics = await AnalyticsService.instance.aggregateForRange(
          _startDate,
          _endDate,
          _selectedPeriod,
        );
      }

      setState(() {
        _metrics = metrics;
        _isLoading = false;
        _lastUpdated = metrics.isNotEmpty ? metrics.last.lastUpdated : null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AnalyticsService.instance.initialize();
      final metrics = await AnalyticsService.instance.aggregateForRange(
        _startDate,
        _endDate,
        _selectedPeriod,
      );

      setState(() {
        _metrics = metrics;
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  AggregatedMetrics? get _aggregatedMetrics {
    if (_metrics.isEmpty) return null;

    // Aggregate all metrics in range
    int totalComments = 0;
    int totalReplies = 0;
    double totalSentiment = 0;
    double totalReplyTime = 0;
    int replyTimeCount = 0;
    final videoStats = <String, TopVideo>{};
    final commenterStats = <String, TopCommenter>{};
    final hourlyPattern = <int, int>{};
    final weekdayPattern = <int, int>{};
    int totalLikes = 0;

    for (final m in _metrics) {
      totalComments += m.totalComments;
      totalReplies += m.totalReplies;
      totalSentiment += m.sentimentScore;
      if (m.avgReplyTimeSeconds > 0) {
        totalReplyTime += m.avgReplyTimeSeconds;
        replyTimeCount++;
      }
      totalLikes += m.engagement.totalLikes;

      for (final v in m.topVideos) {
        if (videoStats.containsKey(v.videoId)) {
          final existing = videoStats[v.videoId]!;
          videoStats[v.videoId] = TopVideo(
            videoId: v.videoId,
            videoTitle: v.videoTitle,
            commentCount: existing.commentCount + v.commentCount,
            likeCount: existing.likeCount + v.likeCount,
            thumbnailUrl: v.thumbnailUrl,
          );
        } else {
          videoStats[v.videoId] = v;
        }
      }

      for (final c in m.topCommenters) {
        if (commenterStats.containsKey(c.authorName)) {
          final existing = commenterStats[c.authorName]!;
          commenterStats[c.authorName] = TopCommenter(
            authorName: c.authorName,
            commentCount: existing.commentCount + c.commentCount,
            authorProfileImageUrl: c.authorProfileImageUrl,
            totalLikes: existing.totalLikes + c.totalLikes,
          );
        } else {
          commenterStats[c.authorName] = c;
        }
      }

      for (final entry in m.engagement.hourlyCommentPattern.entries) {
        hourlyPattern[entry.key] = (hourlyPattern[entry.key] ?? 0) + entry.value;
      }
      for (final entry in m.engagement.weekdayCommentPattern.entries) {
        weekdayPattern[entry.key] =
            (weekdayPattern[entry.key] ?? 0) + entry.value;
      }
    }

    final topVideos = videoStats.values.toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));
    final topCommenters = commenterStats.values.toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    return AggregatedMetrics(
      date: _startDate,
      periodType: _selectedPeriod,
      totalComments: totalComments,
      totalReplies: totalReplies,
      avgReplyTimeSeconds: replyTimeCount > 0 ? totalReplyTime / replyTimeCount : 0,
      sentimentScore: _metrics.isNotEmpty ? totalSentiment / _metrics.length : 0,
      topVideos: topVideos.take(10).toList(),
      topCommenters: topCommenters.take(10).toList(),
      engagement: EngagementDistribution(
        totalLikes: totalLikes,
        totalComments: totalComments,
        totalReplies: totalReplies,
        hourlyCommentPattern: hourlyPattern,
        weekdayCommentPattern: weekdayPattern,
      ),
      lastUpdated: _lastUpdated,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final aggregated = _aggregatedMetrics;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            onPressed: () => context.push('/insights'),
            tooltip: 'Detailed Insights',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshMetrics,
            tooltip: 'Refresh Data',
          ),
        ],
      ),
      body: Column(
        children: [
          // Period filter and date range
          _buildFilters(theme),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(theme)
                    : _metrics.isEmpty
                        ? _buildEmpty(theme)
                        : _buildContent(theme, aggregated!),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Period type selector
          Row(
            children: [
              _FilterChip(
                label: 'Daily',
                selected: _selectedPeriod == PeriodType.daily,
                onSelected: () {
                  setState(() => _selectedPeriod = PeriodType.daily);
                  _loadMetrics();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Weekly',
                selected: _selectedPeriod == PeriodType.weekly,
                onSelected: () {
                  setState(() => _selectedPeriod = PeriodType.weekly);
                  _loadMetrics();
                },
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Monthly',
                selected: _selectedPeriod == PeriodType.monthly,
                onSelected: () {
                  setState(() => _selectedPeriod = PeriodType.monthly);
                  _loadMetrics();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Date range picker
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectDateRange(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.dividerColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: theme.colorScheme.onSurface.withAlpha(179),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Quick range buttons
              PopupMenuButton<int>(
                icon: const Icon(Icons.date_range),
                tooltip: 'Quick Range',
                onSelected: (days) {
                  setState(() {
                    _endDate = DateTime.now();
                    _startDate = _endDate.subtract(Duration(days: days));
                  });
                  _loadMetrics();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 7, child: Text('Last 7 days')),
                  const PopupMenuItem(value: 14, child: Text('Last 14 days')),
                  const PopupMenuItem(value: 30, child: Text('Last 30 days')),
                  const PopupMenuItem(value: 90, child: Text('Last 90 days')),
                ],
              ),
            ],
          ),
          if (_lastUpdated != null) ...[
            const SizedBox(height: 4),
            Text(
              'Last updated: ${DateFormat('MMM d, y HH:mm').format(_lastUpdated!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadMetrics();
    }
  }

  Widget _buildError(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: theme.colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading analytics',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            onPressed: _loadMetrics,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No analytics data',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Analytics will appear once you have comments',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            onPressed: _refreshMetrics,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AggregatedMetrics aggregated) {
    return RefreshIndicator(
      onRefresh: _refreshMetrics,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Summary cards
          _buildSummaryCards(theme, aggregated),
          const SizedBox(height: 24),

          // Comment trends chart
          _buildChartCard(
            theme,
            title: 'Comment Trends',
            icon: Icons.show_chart,
            child: CommentTrendsChart(metrics: _metrics),
          ),
          const SizedBox(height: 16),

          // Two charts side by side on larger screens
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildChartCard(
                        theme,
                        title: 'Sentiment Analysis',
                        icon: Icons.sentiment_satisfied_alt,
                        child: SentimentPieChart(
                          sentimentScore: aggregated.sentimentScore,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildChartCard(
                        theme,
                        title: 'Response Time',
                        icon: Icons.timer,
                        child: AvgReplyTimeChart(
                          avgReplyTimeSeconds: aggregated.avgReplyTimeSeconds,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                children: [
                  _buildChartCard(
                    theme,
                    title: 'Sentiment Analysis',
                    icon: Icons.sentiment_satisfied_alt,
                    child: SentimentPieChart(
                      sentimentScore: aggregated.sentimentScore,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildChartCard(
                    theme,
                    title: 'Response Time',
                    icon: Icons.timer,
                    child: AvgReplyTimeChart(
                      avgReplyTimeSeconds: aggregated.avgReplyTimeSeconds,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Top videos chart
          if (aggregated.topVideos.isNotEmpty) ...[
            _buildChartCard(
              theme,
              title: 'Top Videos',
              icon: Icons.video_library,
              child: TopVideosBarChart(topVideos: aggregated.topVideos),
            ),
            const SizedBox(height: 16),
          ],

          // Top commenters chart
          if (aggregated.topCommenters.isNotEmpty) ...[
            _buildChartCard(
              theme,
              title: 'Frequent Commenters',
              icon: Icons.people,
              child: FrequentCommentersChart(
                topCommenters: aggregated.topCommenters,
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Engagement patterns
          _buildChartCard(
            theme,
            title: 'Engagement Patterns',
            icon: Icons.access_time,
            child: EngagementPatternChart(engagement: aggregated.engagement),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(ThemeData theme, AggregatedMetrics aggregated) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth > 600
            ? (constraints.maxWidth - 48) / 4
            : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _SummaryCard(
              title: 'Total Comments',
              value: aggregated.totalComments.toString(),
              icon: Icons.comment,
              color: theme.colorScheme.primary,
              width: cardWidth,
            ),
            _SummaryCard(
              title: 'Total Replies',
              value: aggregated.totalReplies.toString(),
              icon: Icons.reply,
              color: theme.colorScheme.secondary,
              width: cardWidth,
            ),
            _SummaryCard(
              title: 'Total Likes',
              value: aggregated.engagement.totalLikes.toString(),
              icon: Icons.thumb_up,
              color: Colors.orange,
              width: cardWidth,
            ),
            _SummaryCard(
              title: 'Data Points',
              value: _metrics.length.toString(),
              icon: Icons.data_usage,
              color: Colors.purple,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartCard(
    ThemeData theme, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: theme.colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: selected
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurface,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final double width;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color.withAlpha(31),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.trending_up, color: color, size: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(179),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
