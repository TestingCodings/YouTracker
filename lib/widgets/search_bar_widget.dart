import 'package:flutter/material.dart';

import '../theme/motion_spec.dart';

/// A search bar widget for the dashboard with animated expansion.
class SearchBarWidget extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onSearch;
  final VoidCallback? onClear;
  final String hintText;
  final bool expandable;

  const SearchBarWidget({
    super.key,
    this.initialValue,
    required this.onSearch,
    this.onClear,
    this.hintText = 'Search comments...',
    this.expandable = true,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _hasText = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    
    _animationController = AnimationController(
      vsync: this,
      duration: MotionSpec.durationMedium,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: MotionSpec.curveStandard,
    );
    
    // Initialize expanded state based on initial value
    if (widget.initialValue?.isNotEmpty == true) {
      _isExpanded = true;
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && widget.expandable) {
      _expand();
    }
  }

  void _expand() {
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
      _animationController.forward();
    }
  }

  void _collapse() {
    if (_isExpanded && !_hasText) {
      setState(() => _isExpanded = false);
      _animationController.reverse();
      _focusNode.unfocus();
    }
  }

  void _handleSubmit(String value) {
    widget.onSearch(value);
    if (value.isEmpty) {
      _collapse();
    }
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    _collapse();
  }

  void _handleTap() {
    if (widget.expandable && !_isExpanded) {
      _expand();
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.df,
        vertical: AppSpacing.sm,
      ),
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : MotionSpec.durationMedium,
          curve: MotionSpec.curveStandard,
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ?? theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppSpacing.buttonBorderRadius),
            boxShadow: _isExpanded
                ? [
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Search icon with animation
              AnimatedContainer(
                duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
                padding: EdgeInsets.only(
                  left: AppSpacing.df,
                  right: AppSpacing.sm,
                ),
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
                  child: Icon(
                    Icons.search,
                    key: ValueKey(_isExpanded),
                    color: _isExpanded
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              // Text field
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 14,
                    ),
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    isDense: true,
                  ),
                  style: theme.textTheme.bodyMedium,
                  onSubmitted: _handleSubmit,
                  textInputAction: TextInputAction.search,
                ),
              ),
              // Clear button with animated visibility
              AnimatedSwitcher(
                duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation,
                      child: child,
                    ),
                  );
                },
                child: _hasText
                    ? IconButton(
                        key: const ValueKey('clear'),
                        icon: AnimatedRotation(
                          turns: _hasText ? 0.25 : 0,
                          duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
                          child: const Icon(Icons.close),
                        ),
                        onPressed: _handleClear,
                        iconSize: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      )
                    : const SizedBox(
                        key: ValueKey('empty'),
                        width: 48,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
