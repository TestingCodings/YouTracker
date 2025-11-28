import 'package:flutter/material.dart';

import '../theme/motion_spec.dart';

/// A settings tile widget with subtle hover/press animation.
class SettingsTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return AnimatedContainer(
      duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
      curve: MotionSpec.curveStandard,
      color: _isPressed 
          ? theme.colorScheme.primary.withValues(alpha: 0.05)
          : Colors.transparent,
      child: ListTile(
        leading: AnimatedContainer(
          duration: reduceMotion ? Duration.zero : MotionSpec.durationShort,
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: _isPressed
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.sm),
          ),
          child: Icon(
            widget.icon,
            color: theme.colorScheme.primary,
            size: AppSpacing.iconSizeMedium - 2,
          ),
        ),
        title: Text(widget.title),
        subtitle: widget.subtitle != null 
            ? Padding(
                padding: EdgeInsets.only(top: AppSpacing.xs / 2),
                child: Text(widget.subtitle!),
              )
            : null,
        trailing: widget.trailing,
        onTap: widget.onTap != null
            ? () {
                setState(() => _isPressed = true);
                Future.delayed(MotionSpec.durationShort, () {
                  if (mounted) {
                    setState(() => _isPressed = false);
                  }
                });
                widget.onTap?.call();
              }
            : null,
      ),
    );
  }
}

/// A settings section widget with animated appearance.
class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.df,
            AppSpacing.df,
            AppSpacing.df,
            AppSpacing.sm,
          ),
          child: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Card(
          margin: EdgeInsets.symmetric(horizontal: AppSpacing.df),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}
