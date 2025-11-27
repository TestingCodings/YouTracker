import 'package:flutter/material.dart';

/// A widget showing average reply time with visual indicator.
class AvgReplyTimeChart extends StatelessWidget {
  /// Average reply time in seconds.
  final double avgReplyTimeSeconds;

  const AvgReplyTimeChart({
    super.key,
    required this.avgReplyTimeSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final formattedTime = _formatDuration(avgReplyTimeSeconds);
    final rating = _getRating(avgReplyTimeSeconds);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Circular progress indicator
              SizedBox(
                width: 100,
                height: 100,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: rating.progress,
                        strokeWidth: 10,
                        backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(rating.color),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          rating.icon,
                          color: rating.color,
                          size: 28,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                formattedTime,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: rating.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Average Reply Time',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  rating.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: rating.color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return 'N/A';

    final duration = Duration(seconds: seconds.round());
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  _ReplyTimeRating _getRating(double seconds) {
    if (seconds <= 0) {
      return _ReplyTimeRating(
        label: 'No Data',
        color: Colors.grey,
        icon: Icons.hourglass_empty,
        progress: 0,
      );
    }

    // Under 5 minutes - Excellent
    if (seconds < 300) {
      return _ReplyTimeRating(
        label: 'Excellent',
        color: Colors.green,
        icon: Icons.flash_on,
        progress: 1.0,
      );
    }

    // Under 30 minutes - Great
    if (seconds < 1800) {
      return _ReplyTimeRating(
        label: 'Great',
        color: Colors.lightGreen,
        icon: Icons.speed,
        progress: 0.8,
      );
    }

    // Under 2 hours - Good
    if (seconds < 7200) {
      return _ReplyTimeRating(
        label: 'Good',
        color: Colors.amber,
        icon: Icons.timer,
        progress: 0.6,
      );
    }

    // Under 1 day - Average
    if (seconds < 86400) {
      return _ReplyTimeRating(
        label: 'Average',
        color: Colors.orange,
        icon: Icons.schedule,
        progress: 0.4,
      );
    }

    // Over 1 day - Slow
    return _ReplyTimeRating(
      label: 'Slow',
      color: Colors.red,
      icon: Icons.hourglass_full,
      progress: 0.2,
    );
  }
}

class _ReplyTimeRating {
  final String label;
  final Color color;
  final IconData icon;
  final double progress;

  _ReplyTimeRating({
    required this.label,
    required this.color,
    required this.icon,
    required this.progress,
  });
}
