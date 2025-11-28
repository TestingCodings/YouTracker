import 'package:flutter/material.dart';

import 'models/comment.dart';
import 'src/design_tokens.dart';
import 'src/motion_spec.dart';
import 'widgets/animated_button.dart';
import 'widgets/comment_card.dart';
import 'widgets/search_bar.dart';

/// Demo page showcasing all UI/UX enhancements.
/// Available only in debug mode at route '/ui-demo'.
class UiDemoPage extends StatefulWidget {
  const UiDemoPage({super.key});

  @override
  State<UiDemoPage> createState() => _UiDemoPageState();
}

class _UiDemoPageState extends State<UiDemoPage> {
  bool _isToggled = false;
  bool _isBookmarked = false;
  String _searchQuery = '';
  int _selectedCommentIndex = -1;

  // Mock comments for demo
  final List<Comment> _mockComments = [
    Comment(
      id: 'demo-1',
      videoId: 'v1',
      videoTitle: 'How to Build Amazing Flutter Apps',
      videoThumbnailUrl: '',
      channelId: 'ch1',
      channelName: 'Flutter Dev Channel',
      text:
          'This is such an amazing tutorial! I learned so much from this video. The explanations are clear and the examples are practical.',
      publishedAt: DateTime.now().subtract(const Duration(hours: 2)),
      likeCount: 42,
      replyCount: 5,
      isReply: false,
      authorName: 'Happy Viewer',
      isBookmarked: false,
      sentimentLabel: 'positive',
      sentimentScore: 0.85,
    ),
    Comment(
      id: 'demo-2',
      videoId: 'v2',
      videoTitle: 'Material 3 Design System Deep Dive',
      videoThumbnailUrl: '',
      channelId: 'ch1',
      channelName: 'Flutter Dev Channel',
      text:
          'Could you please explain the color scheme generation in more detail? I\'m not sure I understand how the seed color works.',
      publishedAt: DateTime.now().subtract(const Duration(days: 1)),
      likeCount: 12,
      replyCount: 3,
      isReply: false,
      authorName: 'Curious Developer',
      isBookmarked: true,
      sentimentLabel: 'question',
      sentimentScore: 0.7,
      needsReply: true,
    ),
    Comment(
      id: 'demo-3',
      videoId: 'v3',
      videoTitle: 'Animation Best Practices in Flutter',
      videoThumbnailUrl: '',
      channelId: 'ch1',
      channelName: 'Flutter Dev Channel',
      text: 'The animations are too slow and the app feels sluggish.',
      publishedAt: DateTime.now().subtract(const Duration(days: 3)),
      likeCount: 3,
      replyCount: 1,
      isReply: false,
      authorName: 'Critical Viewer',
      isBookmarked: false,
      sentimentLabel: 'negative',
      sentimentScore: -0.6,
      isToxic: false,
    ),
  ];

  final List<String> _searchSuggestions = [
    'flutter animations',
    'material design',
    'hero transitions',
    'sliver widgets',
    'micro-interactions',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Sliver App Bar Demo
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('UI/UX Demo'),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
                StretchMode.fadeTitle,
              ],
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary.withValues(alpha: 0.3),
                      theme.colorScheme.tertiary.withValues(alpha: 0.3),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.auto_awesome,
                    size: 80,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          // Section: Theme & Typography
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              'Theme & Typography',
              Icons.palette,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Material 3 Theme',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'This app uses Material 3 with Inter typography.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      _buildColorChip(
                          context, 'Primary', theme.colorScheme.primary),
                      _buildColorChip(
                          context, 'Secondary', theme.colorScheme.secondary),
                      _buildColorChip(
                          context, 'Tertiary', theme.colorScheme.tertiary),
                      _buildColorChip(
                          context, 'Surface', theme.colorScheme.surface),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section: Animated Buttons
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              'Animated Buttons',
              Icons.touch_app,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buttons with scale and elevation animations',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Wrap(
                    spacing: Spacing.md,
                    runSpacing: Spacing.md,
                    children: [
                      AnimatedElevatedButton(
                        onPressed: () => _showSnackBar('Elevated pressed!'),
                        label: 'Animated Elevated',
                        icon: Icons.star,
                      ),
                      ElevatedButton(
                        onPressed: () => _showSnackBar('Standard pressed!'),
                        child: const Text('Standard Button'),
                      ),
                      FilledButton(
                        onPressed: () => _showSnackBar('Filled pressed!'),
                        child: const Text('Filled Button'),
                      ),
                      OutlinedButton(
                        onPressed: () => _showSnackBar('Outlined pressed!'),
                        child: const Text('Outlined'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),
                  Row(
                    children: [
                      const Text('Toggle Icon: '),
                      AnimatedIconButton(
                        icon: Icons.favorite_border,
                        alternateIcon: Icons.favorite,
                        isToggled: _isToggled,
                        onPressed: () => setState(() => _isToggled = !_isToggled),
                        color: _isToggled ? Colors.red : null,
                        animateRotation: true,
                      ),
                      const SizedBox(width: Spacing.lg),
                      const Text('Bookmark: '),
                      AnimatedIconButton(
                        icon: Icons.bookmark_border,
                        alternateIcon: Icons.bookmark,
                        isToggled: _isBookmarked,
                        onPressed: () =>
                            setState(() => _isBookmarked = !_isBookmarked),
                        color: _isBookmarked
                            ? theme.colorScheme.primary
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Section: Animated Search Bar
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              'Animated Search Bar',
              Icons.search,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expanding search bar with suggestions',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.lg),
                  AnimatedSearchBar(
                    hintText: 'Search demo...',
                    suggestions: _searchSuggestions,
                    onSearch: (query) {
                      setState(() => _searchQuery = query);
                      _showSnackBar('Searching: $query');
                    },
                    onChanged: (query) {
                      setState(() => _searchQuery = query);
                    },
                    onClear: () {
                      setState(() => _searchQuery = '');
                    },
                  ),
                  if (_searchQuery.isNotEmpty) ...[
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Current query: $_searchQuery',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Section: Hero Transitions
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              'Hero Transitions',
              Icons.animation,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Comment cards with Hero animations',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(
                    'Tap a card to see the Hero transition',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comments list with Hero
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final comment = _mockComments[index];
                  return AnimatedContainer(
                    duration: MotionDurations.short,
                    curve: MotionCurves.standard,
                    decoration: BoxDecoration(
                      color: _selectedCommentIndex == index
                          ? theme.colorScheme.primary.withValues(alpha: 0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(Radii.lg),
                    ),
                    child: CommentCard(
                      comment: comment,
                      onTap: () {
                        setState(() => _selectedCommentIndex = index);
                        _showCommentDetail(context, comment);
                      },
                      onBookmarkTap: () {
                        _showSnackBar('Bookmark toggled for: ${comment.id}');
                      },
                    ),
                  );
                },
                childCount: _mockComments.length,
              ),
            ),
          ),

          // Section: Motion & Accessibility
          SliverToBoxAdapter(
            child: _buildSection(
              context,
              'Motion & Accessibility',
              Icons.accessibility_new,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respects reduced motion settings',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: Spacing.md),
                  Builder(
                    builder: (context) {
                      final reduceMotion =
                          MotionSpec.shouldReduceMotion(context);
                      return Row(
                        children: [
                          Icon(
                            reduceMotion
                                ? Icons.motion_photos_off
                                : Icons.motion_photos_on,
                            color: reduceMotion
                                ? theme.colorScheme.error
                                : theme.colorScheme.primary,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Text(
                            reduceMotion
                                ? 'Reduced motion is ON'
                                : 'Animations are enabled',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  Text(
                    'Design Tokens',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Wrap(
                    spacing: Spacing.sm,
                    runSpacing: Spacing.sm,
                    children: [
                      _buildTokenChip('Spacing.sm', '${Spacing.sm}'),
                      _buildTokenChip('Spacing.md', '${Spacing.md}'),
                      _buildTokenChip('Spacing.lg', '${Spacing.lg}'),
                      _buildTokenChip('Spacing.xl', '${Spacing.xl}'),
                      _buildTokenChip('Radii.lg', '${Radii.lg}'),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom padding
          const SliverPadding(
            padding: EdgeInsets.only(bottom: Spacing.xxxl),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget content,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: Spacing.sm),
              Text(
                title,
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: Spacing.lg),
          content,
        ],
      ),
    );
  }

  Widget _buildColorChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Radii.md),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
              ? Colors.white
              : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTokenChip(String name, String value) {
    return Chip(
      label: Text('$name: $value'),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCommentDetail(BuildContext context, Comment comment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _DemoCommentDetailPage(comment: comment),
      ),
    );
  }
}

/// Demo comment detail page for Hero transition demo.
class _DemoCommentDetailPage extends StatelessWidget {
  final Comment comment;

  const _DemoCommentDetailPage({required this.comment});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Comment Detail'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero comment card
            Hero(
              tag: 'comment-${comment.id}',
              child: Material(
                type: MaterialType.transparency,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(Spacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: 'avatar-${comment.id}',
                              child: CircleAvatar(
                                radius: 24,
                                backgroundColor: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                child: Text(
                                  comment.authorName[0].toUpperCase(),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    comment.authorName,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    comment.videoTitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.secondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: Spacing.lg),
                        const Divider(),
                        const SizedBox(height: Spacing.lg),
                        Text(
                          comment.text,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: Spacing.lg),
                        Row(
                          children: [
                            Icon(
                              Icons.thumb_up_outlined,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              '${comment.likeCount} likes',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: Spacing.lg),
                            Icon(
                              Icons.comment_outlined,
                              size: 16,
                              color: theme.colorScheme.secondary,
                            ),
                            const SizedBox(width: Spacing.xs),
                            Text(
                              '${comment.replyCount} replies',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'This page demonstrates Hero transitions.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'The card and avatar smoothly animate between the list and detail views.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
