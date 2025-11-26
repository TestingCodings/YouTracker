import 'package:flutter/material.dart';

/// A pagination control widget.
class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool hasNextPage;
  final bool hasPreviousPage;
  final VoidCallback? onNextPage;
  final VoidCallback? onPreviousPage;
  final bool isLoading;

  const PaginationControls({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.hasNextPage,
    required this.hasPreviousPage,
    this.onNextPage,
    this.onPreviousPage,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: hasPreviousPage && !isLoading ? onPreviousPage : null,
            tooltip: 'Previous page',
          ),
          const SizedBox(width: 16),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              'Page $currentPage of $totalPages',
              style: theme.textTheme.bodyMedium,
            ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: hasNextPage && !isLoading ? onNextPage : null,
            tooltip: 'Next page',
          ),
        ],
      ),
    );
  }
}
