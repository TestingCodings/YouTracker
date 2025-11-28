import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/motion_spec.dart';

/// An animated button with subtle press animations.
/// Provides visual feedback through scale and opacity changes.
class AnimatedPressButton extends StatefulWidget {
  /// The child widget to display inside the button.
  final Widget child;
  
  /// Called when the button is tapped.
  final VoidCallback? onPressed;
  
  /// Called when the button is long pressed.
  final VoidCallback? onLongPress;
  
  /// The background color of the button.
  final Color? backgroundColor;
  
  /// The border radius of the button.
  final BorderRadius? borderRadius;
  
  /// The padding inside the button.
  final EdgeInsetsGeometry? padding;
  
  /// Whether to add haptic feedback on press.
  final bool hapticFeedback;
  
  /// The scale factor when pressed (default: 0.96).
  final double pressedScale;
  
  /// Custom decoration for the button.
  final BoxDecoration? decoration;

  const AnimatedPressButton({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.hapticFeedback = true,
    this.pressedScale = 0.96,
    this.decoration,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.durationShort,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.pressedScale,
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = true);
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    if (widget.hapticFeedback) {
      HapticFeedback.lightImpact();
    }
    widget.onPressed?.call();
  }

  void _handleLongPress() {
    if (widget.onLongPress == null) return;
    if (widget.hapticFeedback) {
      HapticFeedback.mediumImpact();
    }
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    
    Widget buttonContent = Container(
      padding: widget.padding,
      decoration: widget.decoration ?? BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: widget.borderRadius ?? BorderRadius.circular(AppSpacing.buttonBorderRadius),
      ),
      child: widget.child,
    );
    
    if (reduceMotion) {
      return Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: GestureDetector(
          onTap: _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          child: buttonContent,
        ),
      );
    }
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : (_isPressed ? 0.9 : 1.0),
        duration: MotionSpec.durationShort,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          onLongPress: widget.onLongPress != null ? _handleLongPress : null,
          child: buttonContent,
        ),
      ),
    );
  }
}

/// An animated icon button with press feedback.
class AnimatedIconButton extends StatefulWidget {
  /// The icon to display.
  final IconData icon;
  
  /// Called when the button is tapped.
  final VoidCallback? onPressed;
  
  /// The size of the icon.
  final double? size;
  
  /// The color of the icon.
  final Color? color;
  
  /// Optional tooltip message.
  final String? tooltip;
  
  /// Whether the icon is in a selected/active state.
  final bool isActive;
  
  /// The color when active.
  final Color? activeColor;

  const AnimatedIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.color,
    this.tooltip,
    this.isActive = false,
    this.activeColor,
  });

  @override
  State<AnimatedIconButton> createState() => _AnimatedIconButtonState();
}

class _AnimatedIconButtonState extends State<AnimatedIconButton>
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
      end: 0.85,
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

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed == null) return;
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    HapticFeedback.lightImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    
    final iconColor = widget.isActive 
        ? (widget.activeColor ?? theme.colorScheme.primary)
        : (widget.color ?? theme.iconTheme.color);
    
    Widget iconWidget = Icon(
      widget.icon,
      size: widget.size ?? 24,
      color: iconColor,
    );
    
    if (!reduceMotion) {
      iconWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }
    
    Widget button = GestureDetector(
      onTapDown: reduceMotion ? null : _handleTapDown,
      onTapUp: reduceMotion ? null : _handleTapUp,
      onTapCancel: reduceMotion ? null : _handleTapCancel,
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: iconWidget,
      ),
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}

/// An animated toggle icon button (like bookmark, favorite, etc.)
class AnimatedToggleIconButton extends StatefulWidget {
  /// The icon when inactive.
  final IconData inactiveIcon;
  
  /// The icon when active.
  final IconData activeIcon;
  
  /// Whether the toggle is currently active.
  final bool isActive;
  
  /// Called when the toggle state changes.
  final ValueChanged<bool>? onChanged;
  
  /// The size of the icon.
  final double? size;
  
  /// The color when inactive.
  final Color? inactiveColor;
  
  /// The color when active.
  final Color? activeColor;
  
  /// Optional tooltip message.
  final String? tooltip;

  const AnimatedToggleIconButton({
    super.key,
    required this.inactiveIcon,
    required this.activeIcon,
    required this.isActive,
    this.onChanged,
    this.size,
    this.inactiveColor,
    this.activeColor,
    this.tooltip,
  });

  @override
  State<AnimatedToggleIconButton> createState() => _AnimatedToggleIconButtonState();
}

class _AnimatedToggleIconButtonState extends State<AnimatedToggleIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.durationMedium,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.3),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: MotionSpec.curveEmphasized,
    ));
  }

  @override
  void didUpdateWidget(AnimatedToggleIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.onChanged == null) return;
    HapticFeedback.lightImpact();
    widget.onChanged?.call(!widget.isActive);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);
    
    final icon = widget.isActive ? widget.activeIcon : widget.inactiveIcon;
    final color = widget.isActive 
        ? (widget.activeColor ?? theme.colorScheme.primary)
        : (widget.inactiveColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.6));
    
    Widget iconWidget = AnimatedSwitcher(
      duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Icon(
        icon,
        key: ValueKey(widget.isActive),
        size: widget.size ?? 24,
        color: color,
      ),
    );
    
    if (!reduceMotion) {
      iconWidget = AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: iconWidget,
      );
    }
    
    Widget button = GestureDetector(
      onTap: _handleTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: iconWidget,
      ),
    );
    
    if (widget.tooltip != null) {
      button = Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    
    return button;
  }
}
