# Analytics Module

The YouTracker Analytics module provides comprehensive insights into comment engagement, trends, and user behavior.

## Overview

The analytics system aggregates raw comment data into meaningful metrics that can be visualized through charts and dashboards. Data is stored locally using Hive for offline access and fast UI rendering.

## Architecture

### Components

1. **AggregatedMetrics Model** (`lib/models/aggregated_metrics.dart`)
   - Core data structure for storing aggregated analytics
   - Includes: TopVideo, TopCommenter, EngagementDistribution
   - Hive-annotated for local persistence

2. **AnalyticsService** (`lib/services/analytics_service.dart`)
   - Aggregation logic for computing metrics
   - Sentiment analysis with weighted wordlists
   - Average reply time calculations
   - Storage and retrieval from Hive

3. **Chart Widgets** (`lib/widgets/charts/`)
   - CommentTrendsChart: Line chart for comment trends over time
   - TopVideosBarChart: Bar chart for most commented videos
   - FrequentCommentersChart: Bar chart for active commenters
   - SentimentPieChart: Pie chart for positive/negative sentiment
   - AvgReplyTimeChart: Circular gauge for response time
   - EngagementPatternChart: Heatmap-style charts for time patterns

4. **Screens**
   - AnalyticsDashboard: Main analytics overview
   - InsightsScreen: Detailed breakdowns with filters

### Data Flow

```
Comments (Hive) → AnalyticsService.aggregateForRange() → AggregatedMetrics → Charts
```

## Period Types

Metrics can be aggregated by three period types:

- **Daily**: One data point per day
- **Weekly**: One data point per week (7-day periods)
- **Monthly**: One data point per month

## Aggregation Process

The aggregation process computes the following metrics from raw comments:

1. **Total Comments/Replies**: Count of comments and replies
2. **Sentiment Score**: Weighted wordlist analysis (-1.0 to 1.0)
3. **Average Reply Time**: Mean time between parent comment and replies
4. **Top Videos**: Videos ranked by comment count
5. **Top Commenters**: Users ranked by activity
6. **Engagement Patterns**: 
   - Hourly distribution (0-23 hours)
   - Weekday distribution (Monday-Sunday)

## Sentiment Analysis

The built-in sentiment analyzer uses a weighted wordlist approach:

```dart
// Positive words (0.4 to 1.0 weight)
'great', 'awesome', 'amazing', 'love', 'good', 'nice', 'helpful', 'thanks'...

// Negative words (-0.4 to -1.0 weight)
'bad', 'terrible', 'awful', 'hate', 'boring', 'disappointing', 'waste'...
```

Negation modifiers (not, n't, never, no) flip and dampen the score.

The final score is normalized to the range [-1.0, 1.0]:
- **Positive** (> 0.3): Green indicator
- **Neutral** (-0.3 to 0.3): Yellow indicator
- **Negative** (< -0.3): Red indicator

## Re-running Aggregation

To recompute all metrics for a date range:

```dart
// Clear and recompute metrics
await AnalyticsService.instance.recomputeMetrics(
  DateTime(2025, 1, 1),  // start
  DateTime(2025, 11, 27), // end
);
```

To clear metrics for a specific period type:

```dart
await AnalyticsService.instance.clearMetricsForPeriod(PeriodType.daily);
```

To clear all metrics:

```dart
await AnalyticsService.instance.clearMetrics();
```

## Storage

Metrics are stored in a Hive box named `aggregated_metrics` with keys in the format:

```
metrics_{periodType}_{date}
```

Examples:
- `metrics_daily_2025-11-27`
- `metrics_weekly_2025-11-24`
- `metrics_monthly_2025-11-01`

## Hive Type IDs

The analytics module uses the following Hive type IDs:

| Type ID | Class |
|---------|-------|
| 10 | TopVideo |
| 11 | TopCommenter |
| 12 | EngagementDistribution |
| 13 | AggregatedMetrics |
| 14 | PeriodType |

## UI Routes

- `/analytics` - Analytics Dashboard screen
- `/insights` - Detailed Insights screen

## Usage

### Accessing from Dashboard

The Analytics Dashboard is accessible from the main dashboard via the chart icon in the app bar.

### Date Range Selection

Both screens support:
- Custom date range picker
- Quick range buttons (7, 14, 30, 90 days)

### Filter Selection

Period type (Daily/Weekly/Monthly) can be changed using the filter chips at the top of each screen.

## Charts

### CommentTrendsChart

A line chart showing comment and reply trends over time. Supports:
- Dual lines (comments and replies)
- Touch tooltips
- Responsive grid intervals

### TopVideosBarChart

A vertical bar chart showing the top N videos by comment count. Default is 5 videos.

### FrequentCommentersChart

A vertical bar chart showing the top N commenters by activity.

### SentimentPieChart

A pie chart showing positive vs negative sentiment distribution with a summary label.

### AvgReplyTimeChart

A circular gauge showing average reply time with ratings:
- Excellent: < 5 minutes
- Great: 5-30 minutes
- Good: 30 minutes - 2 hours
- Average: 2-24 hours
- Slow: > 24 hours

### EngagementPatternChart

Two bar charts showing:
1. Comments by hour of day (0-23)
2. Comments by day of week (Mon-Sun)

## Extensibility

### Custom Sentiment Analyzer

Replace the built-in sentiment analysis:

```dart
class CustomSentimentAnalyzer {
  double analyze(String text) {
    // Your implementation
    return score;
  }
}

// Override in AnalyticsService
```

### Additional Metrics

To add new metrics:

1. Update `AggregatedMetrics` model
2. Update aggregation logic in `_computeMetrics()`
3. Create new chart widget
4. Add to dashboard layout

## Performance Considerations

- Aggregation is performed incrementally (per day/week/month)
- Cached metrics are loaded first; aggregation only runs when cache is empty
- Charts use fixed aspect ratios for consistent rendering
- Large datasets may benefit from pagination in the Insights screen
