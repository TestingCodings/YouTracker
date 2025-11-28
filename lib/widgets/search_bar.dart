import 'package:flutter/material.dart';

import '../src/design_tokens.dart';
import '../src/motion_spec.dart';

/// An expanding search bar with animations for width, opacity, and icons.
/// Autofocuses when opened and shows suggestions with AnimatedOpacity.
class AnimatedSearchBar extends StatefulWidget {
  /// Callback when search is submitted.
  final ValueChanged<String>? onSearch;

  /// Callback when search is cleared.
  final VoidCallback? onClear;

  /// Callback when search text changes.
  final ValueChanged<String>? onChanged;

  /// The hint text to display.
  final String hintText;

  /// List of search suggestions to display.
  final List<String> suggestions;

  /// Callback when a suggestion is selected.
  final ValueChanged<String>? onSuggestionSelected;

  /// Initial value for the search field.
  final String? initialValue;

  /// Whether to auto-focus when expanded.
  final bool autoFocus;

  /// Collapsed width (icon-only state).
  final double collapsedWidth;

  /// Expanded width.
  final double expandedWidth;

  const AnimatedSearchBar({
    super.key,
    this.onSearch,
    this.onClear,
    this.onChanged,
    this.hintText = 'Search...',
    this.suggestions = const [],
    this.onSuggestionSelected,
    this.initialValue,
    this.autoFocus = true,
    this.collapsedWidth = 48.0,
    this.expandedWidth = 300.0,
  });

  @override
  State<AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<AnimatedSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  late Animation<double> _opacityAnimation;

  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();

  bool _isExpanded = false;
  bool _showSuggestions = false;
  List<String> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionDurations.medium,
    );

    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.expandedWidth,
    ).animate(
      CurvedAnimation(parent: _controller, curve: MotionCurves.emphasized),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: MotionCurves.decelerate),
      ),
    );

    _textController = TextEditingController(text: widget.initialValue);
    _textController.addListener(_onTextChanged);

    _focusNode.addListener(_onFocusChanged);

    // Auto-expand if there's initial value
    if (widget.initialValue?.isNotEmpty == true) {
      _expand();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    widget.onChanged?.call(_textController.text);
    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && !_isExpanded) {
      _expand();
    }
    _updateSuggestions();
  }

  void _updateSuggestions() {
    final query = _textController.text.toLowerCase();
    if (query.isEmpty || !_focusNode.hasFocus) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _filteredSuggestions = widget.suggestions
          .where((s) => s.toLowerCase().contains(query))
          .take(5)
          .toList();
      _showSuggestions = _filteredSuggestions.isNotEmpty;
    });
  }

  void _expand() {
    setState(() => _isExpanded = true);
    if (!MotionSpec.shouldReduceMotion(context)) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }

    if (widget.autoFocus) {
      Future.delayed(MotionDurations.short, () {
        _focusNode.requestFocus();
      });
    }
  }

  void _collapse() {
    _focusNode.unfocus();
    if (_textController.text.isEmpty) {
      setState(() => _isExpanded = false);
      if (!MotionSpec.shouldReduceMotion(context)) {
        _controller.reverse();
      } else {
        _controller.value = 0.0;
      }
    }
    setState(() => _showSuggestions = false);
  }

  void _handleClear() {
    _textController.clear();
    widget.onClear?.call();
    setState(() {
      _filteredSuggestions = [];
      _showSuggestions = false;
    });
  }

  void _handleSubmit(String value) {
    widget.onSearch?.call(value);
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  void _handleSuggestionSelected(String suggestion) {
    _textController.text = suggestion;
    widget.onSuggestionSelected?.call(suggestion);
    widget.onSearch?.call(suggestion);
    _focusNode.unfocus();
    setState(() => _showSuggestions = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final width =
                reduceMotion && _isExpanded ? widget.expandedWidth : (reduceMotion ? widget.collapsedWidth : _widthAnimation.value);

            return Container(
              width: width,
              height: 48,
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor ??
                    theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(Radii.xl),
                boxShadow: [
                  if (_isExpanded)
                    BoxShadow(
                      color: theme.shadowColor.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Search icon / button
                  IconButton(
                    onPressed: _isExpanded ? null : _expand,
                    icon: Icon(
                      Icons.search,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),

                  // Text field (animated opacity)
                  if (_isExpanded || !reduceMotion && _controller.value > 0.3)
                    Expanded(
                      child: Opacity(
                        opacity: reduceMotion
                            ? (_isExpanded ? 1.0 : 0.0)
                            : _opacityAnimation.value,
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: _handleSubmit,
                          textInputAction: TextInputAction.search,
                        ),
                      ),
                    ),

                  // Clear/Close button (animated)
                  if (_isExpanded)
                    AnimatedOpacity(
                      duration: MotionSpec.getDuration(
                        context,
                        MotionDurations.short,
                      ),
                      opacity:
                          _textController.text.isNotEmpty || _focusNode.hasFocus
                              ? 1.0
                              : 0.5,
                      child: IconButton(
                        onPressed: _textController.text.isNotEmpty
                            ? _handleClear
                            : _collapse,
                        icon: AnimatedSwitcher(
                          duration: MotionSpec.getDuration(
                            context,
                            MotionDurations.short,
                          ),
                          transitionBuilder: (child, animation) {
                            return RotationTransition(
                              turns: Tween(begin: 0.25, end: 0.0)
                                  .animate(animation),
                              child: ScaleTransition(
                                scale: animation,
                                child: child,
                              ),
                            );
                          },
                          child: Icon(
                            _textController.text.isNotEmpty
                                ? Icons.clear
                                : Icons.close,
                            key: ValueKey(_textController.text.isNotEmpty),
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),

        // Suggestions dropdown
        AnimatedOpacity(
          duration: MotionSpec.getDuration(context, MotionDurations.short),
          opacity: _showSuggestions ? 1.0 : 0.0,
          child: AnimatedContainer(
            duration: MotionSpec.getDuration(context, MotionDurations.short),
            curve: MotionCurves.standard,
            height: _showSuggestions
                ? (_filteredSuggestions.length * 48.0).clamp(0.0, 240.0)
                : 0.0,
            width: widget.expandedWidth,
            margin: const EdgeInsets.only(top: Spacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(Radii.lg),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Radii.lg),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(suggestion),
                    leading: Icon(
                      Icons.history,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onTap: () => _handleSuggestionSelected(suggestion),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
