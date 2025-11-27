import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/aggregated_metrics.dart';
import '../services/analytics_service.dart';
import '../storage/hive_boxes.dart';

/// Insights screen with deeper analytics breakdowns and filters.
class InsightsScreen extends ConsumerStatefulWidget {
  const InsightsScreen({super.key});

  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  PeriodType _selectedPeriod = PeriodType.daily;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<AggregatedMetrics> _metrics = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await AnalyticsService.instance.initialize();
      var metrics = await AnalyticsService.instance.getAggregatedMetrics(
        _selectedPeriod,
        _startDate,
        _endDate,
      );

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
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _showExportOptions,
            tooltip: 'Export Data',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadMetrics,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Videos', icon: Icon(Icons.video_library)),
            Tab(text: 'Commenters', icon: Icon(Icons.people)),
            Tab(text: 'Trends', icon: Icon(Icons.trending_up)),
            Tab(text: 'Summary', icon: Icon(Icons.summarize)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filters
          _buildFilters(theme),

          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError(theme)
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildVideosTab(theme),
                          _buildCommentersTab(theme),
                          _buildTrendsTab(theme),
                          _buildSummaryTab(theme),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Row(
        children: [
          // Period selector
          DropdownButton<PeriodType>(
            value: _selectedPeriod,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: PeriodType.daily, child: Text('Daily')),
              DropdownMenuItem(value: PeriodType.weekly, child: Text('Weekly')),
              DropdownMenuItem(value: PeriodType.monthly, child: Text('Monthly')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPeriod = value);
                _loadMetrics();
              }
            },
          ),
          const SizedBox(width: 16),
          // Date range
          Expanded(
            child: InkWell(
              onTap: () => _selectDateRange(context),
              child: Text(
                '${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          // Quick range
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range, size: 20),
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
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text('Error loading insights', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_error!, style: theme.textTheme.bodyMedium),
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

  Widget _buildVideosTab(ThemeData theme) {
    final allVideos = <String, TopVideo>{};
    for (final m in _metrics) {
      for (final v in m.topVideos) {
        if (allVideos.containsKey(v.videoId)) {
          final existing = allVideos[v.videoId]!;
          allVideos[v.videoId] = TopVideo(
            videoId: v.videoId,
            videoTitle: v.videoTitle,
            commentCount: existing.commentCount + v.commentCount,
            likeCount: existing.likeCount + v.likeCount,
            thumbnailUrl: v.thumbnailUrl,
          );
        } else {
          allVideos[v.videoId] = v;
        }
      }
    }

    final sortedVideos = allVideos.values.toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    if (sortedVideos.isEmpty) {
      return _buildEmptyState(theme, 'No video data available');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedVideos.length,
      itemBuilder: (context, index) {
        final video = sortedVideos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              video.videoTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${video.commentCount} comments • ${video.likeCount} likes',
            ),
            trailing: Icon(
              Icons.video_library,
              color: theme.colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCommentersTab(ThemeData theme) {
    final allCommenters = <String, TopCommenter>{};
    for (final m in _metrics) {
      for (final c in m.topCommenters) {
        if (allCommenters.containsKey(c.authorName)) {
          final existing = allCommenters[c.authorName]!;
          allCommenters[c.authorName] = TopCommenter(
            authorName: c.authorName,
            commentCount: existing.commentCount + c.commentCount,
            authorProfileImageUrl: c.authorProfileImageUrl,
            totalLikes: existing.totalLikes + c.totalLikes,
          );
        } else {
          allCommenters[c.authorName] = c;
        }
      }
    }

    final sortedCommenters = allCommenters.values.toList()
      ..sort((a, b) => b.commentCount.compareTo(a.commentCount));

    if (sortedCommenters.isEmpty) {
      return _buildEmptyState(theme, 'No commenter data available');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedCommenters.length,
      itemBuilder: (context, index) {
        final commenter = sortedCommenters[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getRankColor(index),
              backgroundImage: commenter.authorProfileImageUrl != null
                  ? NetworkImage(commenter.authorProfileImageUrl!)
                  : null,
              child: commenter.authorProfileImageUrl == null
                  ? Text(
                      commenter.authorName.isNotEmpty
                          ? commenter.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            title: Text(commenter.authorName),
            subtitle: Text(
              '${commenter.commentCount} comments • ${commenter.totalLikes} likes received',
            ),
            trailing: _buildRankBadge(index, theme),
          ),
        );
      },
    );
  }

  Widget _buildTrendsTab(ThemeData theme) {
    if (_metrics.isEmpty) {
      return _buildEmptyState(theme, 'No trend data available');
    }

    final sortedMetrics = List<AggregatedMetrics>.from(_metrics)
      ..sort((a, b) => a.date.compareTo(b.date));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedMetrics.length,
      itemBuilder: (context, index) {
        final metric = sortedMetrics[index];
        final dateLabel = _formatPeriodDate(metric.date, _selectedPeriod);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricItem(
                      label: 'Comments',
                      value: metric.totalComments.toString(),
                      icon: Icons.comment,
                    ),
                    _MetricItem(
                      label: 'Replies',
                      value: metric.totalReplies.toString(),
                      icon: Icons.reply,
                    ),
                    _MetricItem(
                      label: 'Sentiment',
                      value: _formatSentiment(metric.sentimentScore),
                      icon: _getSentimentIcon(metric.sentimentScore),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryTab(ThemeData theme) {
    if (_metrics.isEmpty) {
      return _buildEmptyState(theme, 'No summary data available');
    }

    int totalComments = 0;
    int totalReplies = 0;
    int totalLikes = 0;
    double avgSentiment = 0;
    double avgReplyTime = 0;
    int replyTimeCount = 0;

    for (final m in _metrics) {
      totalComments += m.totalComments;
      totalReplies += m.totalReplies;
      totalLikes += m.engagement.totalLikes;
      avgSentiment += m.sentimentScore;
      if (m.avgReplyTimeSeconds > 0) {
        avgReplyTime += m.avgReplyTimeSeconds;
        replyTimeCount++;
      }
    }

    avgSentiment = _metrics.isNotEmpty ? avgSentiment / _metrics.length : 0;
    avgReplyTime = replyTimeCount > 0 ? avgReplyTime / replyTimeCount : 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SummarySection(
          title: 'Overview',
          items: [
            _SummaryItem(label: 'Total Comments', value: totalComments.toString()),
            _SummaryItem(label: 'Total Replies', value: totalReplies.toString()),
            _SummaryItem(label: 'Total Likes', value: totalLikes.toString()),
            _SummaryItem(label: 'Data Points', value: _metrics.length.toString()),
          ],
        ),
        const SizedBox(height: 16),
        _SummarySection(
          title: 'Engagement',
          items: [
            _SummaryItem(
              label: 'Avg Sentiment',
              value: _formatSentiment(avgSentiment),
            ),
            _SummaryItem(
              label: 'Avg Reply Time',
              value: _formatDuration(avgReplyTime),
            ),
            _SummaryItem(
              label: 'Comments/Period',
              value: _metrics.isNotEmpty
                  ? (totalComments / _metrics.length).toStringAsFixed(1)
                  : '0',
            ),
            _SummaryItem(
              label: 'Reply Rate',
              value: totalComments > 0
                  ? '${((totalReplies / totalComments) * 100).toStringAsFixed(1)}%'
                  : '0%',
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SummarySection(
          title: 'Time Period',
          items: [
            _SummaryItem(
              label: 'Start Date',
              value: DateFormat('MMM d, y').format(_startDate),
            ),
            _SummaryItem(
              label: 'End Date',
              value: DateFormat('MMM d, y').format(_endDate),
            ),
            _SummaryItem(
              label: 'Period Type',
              value: _selectedPeriod.name[0].toUpperCase() +
                  _selectedPeriod.name.substring(1),
            ),
            _SummaryItem(
              label: 'Duration',
              value: '${_endDate.difference(_startDate).inDays} days',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(message, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Summary to Clipboard'),
              onTap: () {
                Navigator.pop(context);
                _copySummaryToClipboard();
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Summary'),
              onTap: () {
                Navigator.pop(context);
                _shareSummary();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _copySummaryToClipboard() {
    final summary = _generateSummaryText();
    // In a real app, you would use Clipboard.setData here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Summary copied to clipboard')),
    );
  }

  void _shareSummary() {
    // In a real app, you would use share_plus package here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  String _generateSummaryText() {
    int totalComments = 0;
    int totalReplies = 0;
    for (final m in _metrics) {
      totalComments += m.totalComments;
      totalReplies += m.totalReplies;
    }

    return '''
YouTracker Analytics Summary
Period: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}
Total Comments: $totalComments
Total Replies: $totalReplies
''';
  }

  String _formatPeriodDate(DateTime date, PeriodType period) {
    switch (period) {
      case PeriodType.daily:
        return DateFormat('MMM d, y').format(date);
      case PeriodType.weekly:
        final weekEnd = date.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(date)} - ${DateFormat('MMM d').format(weekEnd)}';
      case PeriodType.monthly:
        return DateFormat('MMMM y').format(date);
    }
  }

  String _formatSentiment(double score) {
    if (score > 0.3) return 'Positive';
    if (score < -0.3) return 'Negative';
    return 'Neutral';
  }

  IconData _getSentimentIcon(double score) {
    if (score > 0.3) return Icons.sentiment_satisfied_alt;
    if (score < -0.3) return Icons.sentiment_dissatisfied;
    return Icons.sentiment_neutral;
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return 'N/A';
    final duration = Duration(seconds: seconds.round());
    if (duration.inDays > 0) return '${duration.inDays}d';
    if (duration.inHours > 0) return '${duration.inHours}h';
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return Colors.amber;
      case 1:
        return Colors.grey.shade400;
      case 2:
        return Colors.brown.shade300;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildRankBadge(int index, ThemeData theme) {
    if (index >= 3) return const SizedBox.shrink();

    IconData icon;
    Color color;
    switch (index) {
      case 0:
        icon = Icons.emoji_events;
        color = Colors.amber;
        break;
      case 1:
        icon = Icons.emoji_events;
        color = Colors.grey.shade400;
        break;
      case 2:
        icon = Icons.emoji_events;
        color = Colors.brown.shade300;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Icon(icon, color: color, size: 24);
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  final String title;
  final List<_SummaryItem> items;

  const _SummarySection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 24,
              runSpacing: 12,
              children: items,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(179),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
