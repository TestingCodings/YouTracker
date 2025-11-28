import 'package:flutter/material.dart';

import '../src/design_tokens.dart';
import '../src/motion_spec.dart';

/// An animated button wrapper that adds scale and elevation animations on press.
/// Wraps ElevatedButton, FilledButton, or any child widget with micro-interactions.
class AnimatedButton extends StatefulWidget {
  /// The child widget to wrap with animations.
  final Widget child;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// Scale factor when pressed (default: 0.95).
  final double pressedScale;

  /// Elevation when idle.
  final double elevation;

  /// Elevation when pressed.
  final double pressedElevation;

  const AnimatedButton({
    super.key,
    required this.child,
    this.onPressed,
    this.pressedScale = 0.95,
    this.elevation = Elevations.medium,
    this.pressedElevation = Elevations.low,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.short,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.standard),
    );
    _elevationAnimation = Tween<double>(
      begin: widget.elevation,
      end: widget.pressedElevation,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.standard),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    if (!_isPressed) {
      setState(() => _isPressed = true);
      if (!MotionSpec.shouldReduceMotion(context)) {
        _controller.forward();
      }
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _releaseButton();
  }

  void _handleTapCancel() {
    _releaseButton();
  }

  void _releaseButton() {
    if (_isPressed) {
      setState(() => _isPressed = false);
      if (!MotionSpec.shouldReduceMotion(context)) {
        _controller.reverse();
      }
    }
  }

  void _handleTap() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    if (reduceMotion) {
      // Return plain child without animations for reduced motion
      return GestureDetector(
        onTap: widget.onPressed,
        child: widget.child,
      );
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Material(
              color: Colors.transparent,
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(Radii.lg),
              child: child,
            ),
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// An animated elevated button with built-in press animations.
class AnimatedElevatedButton extends StatelessWidget {
  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// The label text for the button.
  final String label;

  /// Optional icon to display before the label.
  final IconData? icon;

  const AnimatedElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          )
        : ElevatedButton(
            onPressed: onPressed,
            child: Text(label),
          );

    return AnimatedButton(
      onPressed: onPressed,
      child: IgnorePointer(child: button),
    );
  }
}

/// An animated icon button with rotation and scale effects.
class AnimatedIconButton extends StatefulWidget {
  /// The icon to display.
  final IconData icon;

  /// Alternate icon to display when toggled (optional).
  final IconData? alternateIcon;

  /// Whether the button is in the toggled state.
  final bool isToggled;

  /// Called when the button is pressed.
  final VoidCallback? onPressed;

  /// The color of the icon.
  final Color? color;

  /// The size of the icon.
  final double size;

  /// Whether to animate rotation on toggle.
  final bool animateRotation;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.alternateIcon,
    this.isToggled = false,
    this.onPressed,
    this.color,
    this.size = 24.0,
    this.animateRotation = false,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.medium,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.emphasized),
    );

    if (widget.isToggled) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isToggled != oldWidget.isToggled) {
      if (!MotionSpec.shouldReduceMotion(context)) {
        if (widget.isToggled) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      } else {
        _controller.value = widget.isToggled ? 1.0 : 0.0;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIcon = widget.isToggled && widget.alternateIcon != null
        ? widget.alternateIcon!
        : widget.icon;

    Widget iconWidget = Icon(
      currentIcon,
      color: widget.color,
      size: widget.size,
    );

    // Wrap with AnimatedSwitcher for smooth icon transitions
    iconWidget = AnimatedSwitcher(
      duration: MotionSpec.getDuration(context, MotionDurations.short),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: Icon(
        currentIcon,
        key: ValueKey(currentIcon),
        color: widget.color,
        size: widget.size,
      ),
    );

    // Add rotation animation if enabled
    if (widget.animateRotation) {
      iconWidget = AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return RotationTransition(
            turns: _rotationAnimation,
            child: child,
          );
        },
        child: iconWidget,
      );
    }

    return IconButton(
      onPressed: widget.onPressed,
      icon: iconWidget,
    );
  }
}
