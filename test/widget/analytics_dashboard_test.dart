import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:you_tracker/screens/analytics_dashboard.dart';
import 'package:you_tracker/storage/hive_boxes.dart';

void main() {
  group('AnalyticsDashboardScreen', () {
    testWidgets('should render with filter chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnalyticsDashboardScreen(),
          ),
        ),
      );

      // Wait for widget to build
      await tester.pumpAndSettle();

      // Verify the screen title is displayed
      expect(find.text('Analytics Dashboard'), findsOneWidget);

      // Verify filter chips are displayed
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
    });

    testWidgets('should have insights and refresh buttons in app bar',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnalyticsDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify action buttons exist
      expect(find.byIcon(Icons.insights), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('should have date range picker', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnalyticsDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify calendar icon is present for date picker
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('filter chips should be tappable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AnalyticsDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap the Weekly filter
      final weeklyChip = find.text('Weekly');
      expect(weeklyChip, findsOneWidget);
      await tester.tap(weeklyChip);
      await tester.pumpAndSettle();

      // The chip should still be visible after tap
      expect(find.text('Weekly'), findsOneWidget);
    });
  });

  group('PeriodType', () {
    test('should have correct enum values', () {
      expect(PeriodType.values.length, 3);
      expect(PeriodType.values, contains(PeriodType.daily));
      expect(PeriodType.values, contains(PeriodType.weekly));
      expect(PeriodType.values, contains(PeriodType.monthly));
    });
  });

  group('HiveBoxNames', () {
    test('should generate correct metrics keys', () {
      final date = DateTime(2025, 11, 27);

      expect(
        HiveBoxNames.metricsKey(PeriodType.daily, date),
        'metrics_daily_2025-11-27',
      );
      expect(
        HiveBoxNames.metricsKey(PeriodType.weekly, date),
        'metrics_weekly_2025-11-27',
      );
      expect(
        HiveBoxNames.metricsKey(PeriodType.monthly, date),
        'metrics_monthly_2025-11-27',
      );
    });

    test('should pad single digit months and days', () {
      final date = DateTime(2025, 1, 5);

      expect(
        HiveBoxNames.metricsKey(PeriodType.daily, date),
        'metrics_daily_2025-01-05',
      );
    });
  });
}
