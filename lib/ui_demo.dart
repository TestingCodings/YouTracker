import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/models.dart';
import 'theme/motion_spec.dart';
import 'widgets/widgets.dart';

/// Extension to format color as hex string.
extension ColorHex on Color {
  /// Returns the color as a hex string (e.g., '#FF0000').
  String toHexString() {
    return '#${value.toRadixString(16).substring(2).toUpperCase()}';
  }
}

/// Demo page showcasing the new UI/UX improvements.
/// This page is optional and does not change app entry points.
/// 
/// To access this demo, add a route in app_router.dart:
/// ```dart
/// GoRoute(
///   path: '/ui-demo',
///   name: 'uiDemo',
///   builder: (context, state) => const UIDemoPage(),
/// ),
/// ```
class UIDemoPage extends ConsumerStatefulWidget {
  const UIDemoPage({super.key});

  @override
  ConsumerState<UIDemoPage> createState() => _UIDemoPageState();
}

class _UIDemoPageState extends ConsumerState<UIDemoPage>
    with TickerProviderStateMixin {
  bool _isBookmarked = false;
  bool _isExpanded = false;
  String _searchQuery = '';
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          // Sliver App Bar Demo
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            stretch: true,
            backgroundColor: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              centerTitle: false,
              titlePadding: EdgeInsets.only(
                left: AppSpacing.df,
                bottom: AppSpacing.df,
              ),
              title: Text(
                'UI/UX Demo',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.15),
                          theme.colorScheme.tertiary.withValues(alpha: 0.1),
                          theme.colorScheme.surface,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: AppSpacing.lg,
                    bottom: 60,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: reduceMotion ? 1.0 : _pulseAnimation.value,
                          child: child,
                        );
                      },
                      child: Icon(
                        Icons.auto_awesome,
                        size: 80,
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: AppSpacing.screenPadding,
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionTitle('Material 3 Theme'),
                _buildThemeShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Typography Scale'),
                _buildTypographyShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Animated Search Bar'),
                SearchBarWidget(
                  initialValue: _searchQuery,
                  onSearch: (query) {
                    setState(() => _searchQuery = query);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Searched: $query')),
                    );
                  },
                  onClear: () {
                    setState(() => _searchQuery = '');
                  },
                ),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Animated Buttons'),
                _buildButtonShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Animated Toggle Icons'),
                _buildToggleIconShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Comment Card with Hero'),
                _buildCommentCardDemo(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Motion & Spacing Tokens'),
                _buildMotionTokensShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Selection Chips'),
                _buildChipShowcase(theme),
                SizedBox(height: AppSpacing.xl),

                _buildSectionTitle('Accessibility'),
                _buildAccessibilityInfo(theme),
                SizedBox(height: AppSpacing.xxl),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Scheme',
              style: theme.textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildColorChip('Primary', theme.colorScheme.primary),
                _buildColorChip('Secondary', theme.colorScheme.secondary),
                _buildColorChip('Tertiary', theme.colorScheme.tertiary),
                _buildColorChip('Surface', theme.colorScheme.surface),
                _buildColorChip('Error', theme.colorScheme.error),
              ],
            ),
            SizedBox(height: AppSpacing.df),
            Text(
              'Surface Containers',
              style: theme.textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildColorChip('Container Low', 
                    theme.colorScheme.surfaceContainerLow),
                _buildColorChip('Container', 
                    theme.colorScheme.surfaceContainer),
                _buildColorChip('Container High', 
                    theme.colorScheme.surfaceContainerHigh),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorChip(String label, Color color) {
    return Tooltip(
      message: color.toHexString(),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTypographyShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Headline Large', style: theme.textTheme.headlineLarge),
            SizedBox(height: AppSpacing.sm),
            Text('Headline Medium', style: theme.textTheme.headlineMedium),
            SizedBox(height: AppSpacing.sm),
            Text('Headline Small', style: theme.textTheme.headlineSmall),
            SizedBox(height: AppSpacing.md),
            Text('Title Large', style: theme.textTheme.titleLarge),
            SizedBox(height: AppSpacing.sm),
            Text('Title Medium', style: theme.textTheme.titleMedium),
            SizedBox(height: AppSpacing.sm),
            Text('Title Small', style: theme.textTheme.titleSmall),
            SizedBox(height: AppSpacing.md),
            Text('Body Large', style: theme.textTheme.bodyLarge),
            SizedBox(height: AppSpacing.sm),
            Text('Body Medium', style: theme.textTheme.bodyMedium),
            SizedBox(height: AppSpacing.sm),
            Text('Body Small', style: theme.textTheme.bodySmall),
            SizedBox(height: AppSpacing.md),
            Text('Label Large', style: theme.textTheme.labelLarge),
            SizedBox(height: AppSpacing.sm),
            Text('Label Medium', style: theme.textTheme.labelMedium),
            SizedBox(height: AppSpacing.sm),
            Text('Label Small', style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }

  Widget _buildButtonShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Press buttons to see scale animation',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Elevated Button Pressed')),
                      );
                    },
                    child: const Text('Elevated'),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Filled Button Pressed')),
                      );
                    },
                    child: const Text('Filled'),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Outlined Button Pressed')),
                      );
                    },
                    child: const Text('Outlined'),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Text Button Pressed')),
                      );
                    },
                    child: const Text('Text'),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.df),
            Text(
              'Custom AnimatedPressButton',
              style: theme.textTheme.titleSmall,
            ),
            SizedBox(height: AppSpacing.sm),
            AnimatedPressButton(
              backgroundColor: theme.colorScheme.primaryContainer,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.df,
                vertical: AppSpacing.md,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom Press Button!')),
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, color: theme.colorScheme.primary),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    'Tap me for press animation',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleIconShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Toggle icons animate with bounce effect',
              style: theme.textTheme.bodySmall,
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    AnimatedToggleIconButton(
                      inactiveIcon: Icons.bookmark_border,
                      activeIcon: Icons.bookmark,
                      isActive: _isBookmarked,
                      activeColor: theme.colorScheme.primary,
                      tooltip: 'Bookmark',
                      onChanged: (value) {
                        setState(() => _isBookmarked = value);
                      },
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Bookmark', style: theme.textTheme.labelSmall),
                  ],
                ),
                Column(
                  children: [
                    AnimatedToggleIconButton(
                      inactiveIcon: Icons.favorite_border,
                      activeIcon: Icons.favorite,
                      isActive: _isExpanded,
                      activeColor: Colors.red,
                      tooltip: 'Like',
                      onChanged: (value) {
                        setState(() => _isExpanded = value);
                      },
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Like', style: theme.textTheme.labelSmall),
                  ],
                ),
                Column(
                  children: [
                    AnimatedIconButton(
                      icon: Icons.share,
                      tooltip: 'Share',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share pressed')),
                        );
                      },
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text('Share', style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentCardDemo(ThemeData theme) {
    // Create a sample comment for demo
    final demoComment = Comment(
      id: 'demo-1',
      videoId: 'abc123',
      videoTitle: 'Flutter UI/UX Best Practices - Full Tutorial',
      videoThumbnailUrl: '',
      channelId: 'channel-1',
      channelName: 'Flutter Dev Channel',
      text: 'This is a demo comment to showcase the Hero animation and '
          'press feedback. Tap the card to see the scale animation!',
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      likeCount: 42,
      replyCount: 7,
      isReply: false,
      authorName: 'Demo User',
      isBookmarked: _isBookmarked,
      sentimentLabel: 'positive',
      sentimentScore: 0.85,
    );

    return CommentCard(
      comment: demoComment,
      enableHeroAnimation: false, // Disable for demo since we don't navigate
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('In real app, this navigates with Hero animation'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      },
      onBookmarkTap: () {
        setState(() => _isBookmarked = !_isBookmarked);
      },
    );
  }

  Widget _buildMotionTokensShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration Constants', style: theme.textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm),
            _buildTokenRow('durationShort', '150ms'),
            _buildTokenRow('durationMedium', '250ms'),
            _buildTokenRow('durationLong', '350ms'),
            _buildTokenRow('durationExtraLong', '500ms'),
            SizedBox(height: AppSpacing.df),
            Text('Spacing Tokens', style: theme.textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm),
            _buildTokenRow('xs', '4pt'),
            _buildTokenRow('sm', '8pt'),
            _buildTokenRow('md', '12pt'),
            _buildTokenRow('df', '16pt'),
            _buildTokenRow('lg', '24pt'),
            _buildTokenRow('xl', '32pt'),
            SizedBox(height: AppSpacing.df),
            Text('Easing Curves', style: theme.textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm),
            _buildTokenRow('curveStandard', 'easeInOutCubicEmphasized'),
            _buildTokenRow('curveDecelerate', 'easeOutCubic'),
            _buildTokenRow('curveAccelerate', 'easeInCubic'),
          ],
        ),
      ),
    );
  }

  Widget _buildTokenRow(String name, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipShowcase(ThemeData theme) {
    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (int i = 0; i < 4; i++)
                  ChoiceChip(
                    label: Text('Option ${i + 1}'),
                    selected: _selectedIndex == i,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedIndex = i);
                      }
                    },
                  ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                Chip(label: const Text('Default Chip')),
                ActionChip(
                  label: const Text('Action Chip'),
                  onPressed: () {},
                ),
                InputChip(
                  label: const Text('Input Chip'),
                  onDeleted: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibilityInfo(ThemeData theme) {
    final reduceMotion = MotionSpec.shouldReduceMotion(context);

    return Card(
      child: Padding(
        padding: AppSpacing.paddingDf,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  reduceMotion ? Icons.motion_photos_off : Icons.motion_photos_on,
                  color: reduceMotion 
                      ? theme.colorScheme.error 
                      : theme.colorScheme.primary,
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    reduceMotion
                        ? 'Reduced motion is enabled - animations are minimized'
                        : 'Animations are active',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'All animations in this app respect the platform\'s '
              '"Reduce Motion" accessibility setting. When enabled, '
              'animations are either disabled or significantly reduced '
              'to prevent motion sickness and improve accessibility.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
