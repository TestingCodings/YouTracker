import 'package:flutter/material.dart';

import '../src/motion_spec.dart';

/// Animated bookmark button with scale and icon transition.
/// A shared widget extracted from comment_card.dart and comment_detail_screen.dart.
class AnimatedBookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final VoidCallback? onPressed;
  final Color primaryColor;

  const AnimatedBookmarkButton({
    super.key,
    required this.isBookmarked,
    this.onPressed,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: AnimatedSwitcher(
        duration: MotionSpec.getDuration(context, MotionDurations.medium),
        transitionBuilder: (child, animation) {
          return ScaleTransition(
            scale: animation,
            child: child,
          );
        },
        child: Icon(
          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
          key: ValueKey(isBookmarked),
          color: isBookmarked ? primaryColor : null,
        ),
      ),
    );
  }
}
