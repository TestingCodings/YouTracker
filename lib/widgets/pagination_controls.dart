import 'package:flutter/material.dart';

import '../theme/motion_spec.dart';

/// A pagination control widget with subtle animations.
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
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.df,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _AnimatedPaginationButton(
            icon: Icons.chevron_left,
            onPressed: hasPreviousPage && !isLoading ? onPreviousPage : null,
            tooltip: 'Previous page',
            reduceMotion: reduceMotion,
          ),
          SizedBox(width: AppSpacing.df),
          AnimatedSwitcher(
            duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: isLoading
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Text(
                    'Page $currentPage of $totalPages',
                    key: ValueKey('page-$currentPage'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
          SizedBox(width: AppSpacing.df),
          _AnimatedPaginationButton(
            icon: Icons.chevron_right,
            onPressed: hasNextPage && !isLoading ? onNextPage : null,
            tooltip: 'Next page',
            reduceMotion: reduceMotion,
          ),
        ],
      ),
    );
  }
}

class _AnimatedPaginationButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final bool reduceMotion;

  const _AnimatedPaginationButton({
    required this.icon,
    this.onPressed,
    required this.tooltip,
    required this.reduceMotion,
  });

  @override
  State<_AnimatedPaginationButton> createState() => _AnimatedPaginationButtonState();
}

class _AnimatedPaginationButtonState extends State<_AnimatedPaginationButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.durationShort,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionSpec.curveStandard,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEnabled = widget.onPressed != null;

    Widget button = AnimatedOpacity(
      duration: widget.reduceMotion ? Duration.zero : MotionSpec.durationShort,
      opacity: isEnabled ? 1.0 : 0.4,
      child: Container(
        decoration: BoxDecoration(
          color: isEnabled 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: IconButton(
          icon: Icon(widget.icon),
          onPressed: widget.onPressed != null
              ? () {
                  if (!widget.reduceMotion) {
                    _controller.forward().then((_) => _controller.reverse());
                  }
                  widget.onPressed?.call();
                }
              : null,
          tooltip: widget.tooltip,
          color: theme.colorScheme.primary,
        ),
      ),
    );

    if (widget.reduceMotion) {
      return button;
    }

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: button,
    );
  }
}
