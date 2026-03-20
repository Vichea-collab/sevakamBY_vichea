import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/core/utils/page_transition.dart';
import 'package:servicefinder/core/utils/responsive.dart';
import 'package:servicefinder/core/utils/safe_image_provider.dart';
import 'package:servicefinder/domain/entities/pagination.dart';
import 'package:servicefinder/domain/entities/profile_settings.dart';
import 'package:servicefinder/domain/entities/provider_portal.dart';
import 'package:servicefinder/presentation/state/chat_state.dart';
import 'package:servicefinder/presentation/state/finder_post_state.dart';
import 'package:servicefinder/presentation/state/profile_image_state.dart';
import 'package:servicefinder/presentation/state/profile_settings_state.dart';
import 'package:servicefinder/presentation/widgets/app_state_panel.dart';
import 'package:servicefinder/presentation/widgets/pagination_bar.dart';
import 'package:servicefinder/presentation/widgets/pressable_scale.dart';
import 'package:servicefinder/presentation/widgets/shimmer_loading.dart';
import 'package:servicefinder/presentation/pages/chat/chat_conversation_page.dart';
import 'package:servicefinder/presentation/pages/chat/chat_list_page.dart';

class ProviderPortalHomePage extends StatefulWidget {
  static const String routeName = '/provider/home';

  const ProviderPortalHomePage({super.key});

  @override
  State<ProviderPortalHomePage> createState() => _ProviderPortalHomePageState();
}

class _ProviderPortalHomePageState extends State<ProviderPortalHomePage> {
  bool _refreshInProgress = false;
  bool _isPaging = false;

  late final TextEditingController _searchController;
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(FinderPostState.refresh(page: 1));
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.trim().toLowerCase();
        });
      }
    });
  }

  List<FinderPostItem> _filterPosts(List<FinderPostItem> posts) {
    if (_searchQuery.isEmpty) return posts;
    return posts.where((post) {
      final name = post.clientName.toLowerCase();
      final msg = post.message.toLowerCase();
      final cat = post.category.toLowerCase();
      final loc = post.location.toLowerCase();
      final srv = post.serviceLabel.toLowerCase();
      return name.contains(_searchQuery) ||
          msg.contains(_searchQuery) ||
          cat.contains(_searchQuery) ||
          loc.contains(_searchQuery) ||
          srv.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return ValueListenableBuilder<List<FinderPostItem>>(
      valueListenable: FinderPostState.posts,
      builder: (context, posts, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: FinderPostState.loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<PaginationMeta>(
              valueListenable: FinderPostState.pagination,
              builder: (context, pagination, _) {
                final filteredPosts = _filterPosts(posts);
                final currentPage = _normalizedPage(pagination.page);

                return Scaffold(
                  body: RefreshIndicator(
                    onRefresh: _handleRefresh,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(child: const _ProviderTopHeader()),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            rs.space(AppSpacing.lg),
                            rs.space(AppSpacing.lg),
                            rs.space(AppSpacing.lg),
                            rs.space(AppSpacing.xl),
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _ProviderSearchBar(
                                controller: _searchController,
                                onChanged: _onSearchChanged,
                                onClear: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              ),
                              SizedBox(height: rs.space(22)),
                              Row(
                                children: [
                                  Text(
                                    _searchQuery.isEmpty
                                        ? 'Open requests'
                                        : 'Search results',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const Spacer(),
                                  _ResultsCountPill(
                                    count: _searchQuery.isEmpty
                                        ? pagination.totalItems
                                        : filteredPosts.length,
                                  ),
                                ],
                              ),
                              SizedBox(height: rs.space(12)),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: isLoading && posts.isEmpty
                                    ? SizedBox(
                                        height: rs.dimension(320),
                                        child: Center(
                                          child: AppStatePanel.loading(
                                            title: 'Loading finder requests',
                                          ),
                                        ),
                                      )
                                    : filteredPosts.isEmpty
                                    ? AppStatePanel.empty(
                                        title: _searchQuery.isEmpty
                                            ? 'No finder requests yet'
                                            : 'No results found',
                                        message: _searchQuery.isEmpty
                                            ? 'New requests will appear here.'
                                            : 'Try searching for something else.',
                                      )
                                    : ListView.builder(
                                        key: ValueKey<String>(
                                          'provider_home_posts_${filteredPosts.length}_${pagination.page}_$_searchQuery',
                                        ),
                                        padding: EdgeInsets.zero,
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: filteredPosts.length,
                                        cacheExtent: 1000,
                                        itemBuilder: (context, index) =>
                                            _FinderPostTile(
                                              post: filteredPosts[index],
                                            ),
                                      ),
                              ),
                              if (pagination.totalPages > 1 &&
                                  _searchQuery.isEmpty) ...[
                                SizedBox(height: rs.space(12)),
                                PaginationBar(
                                  currentPage: currentPage,
                                  totalPages: pagination.totalPages,
                                  loading: _isPaging,
                                  onPageSelected: _goToPage,
                                ),
                              ],
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleRefresh() async {
    if (_refreshInProgress) return;
    _refreshInProgress = true;
    try {
      await Future.wait<void>([
        FinderPostState.refresh(page: 1),
        FinderPostState.refreshAllForLookup(maxPages: 3),
        ChatState.refreshUnreadCount(),
      ]);
    } catch (_) {
      // Keep current data when refresh fails.
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    if (_isPaging || targetPage == FinderPostState.pagination.value.page) {
      return;
    }
    setState(() => _isPaging = true);
    try {
      await FinderPostState.refresh(page: targetPage);
    } finally {
      if (mounted) {
        setState(() => _isPaging = false);
      }
    }
  }

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }
}

class _PreferredDatePill extends StatelessWidget {
  final DateTime preferredDate;

  const _PreferredDatePill({required this.preferredDate});

  @override
  Widget build(BuildContext context) {
    final label = MaterialLocalizations.of(
      context,
    ).formatMediumDate(preferredDate);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Preferred: $label',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderTopHeader extends StatefulWidget {
  const _ProviderTopHeader();

  @override
  State<_ProviderTopHeader> createState() => _ProviderTopHeaderState();
}

class _ProviderTopHeaderState extends State<_ProviderTopHeader> {
  Timer? _chatRefreshTimer;
  bool _syncingProfile = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
      unawaited(_syncProfile());
    });
    _chatRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
    });
  }

  @override
  void dispose() {
    _chatRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _syncProfile() async {
    if (mounted) {
      setState(() => _syncingProfile = true);
    }
    await ProfileSettingsState.syncRoleProfileFromBackend(isProvider: true);
    if (mounted) {
      setState(() => _syncingProfile = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    Future<void> openChats() async {
      await Navigator.push(context, slideFadeRoute(const ChatListPage()));
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
    }

    return ValueListenableBuilder<ProfileFormData>(
      valueListenable: ProfileSettingsState.providerProfile,
      builder: (context, profile, _) {
        final displayName = profile.name.trim().isEmpty
            ? 'Service Provider'
            : profile.name.trim();
        final city = profile.city.trim().isEmpty
            ? 'Phnom Penh'
            : profile.city.trim();
        final hasProfileContent =
            profile.name.trim().isNotEmpty || profile.city.trim().isNotEmpty;
        return Container(
          padding: rs.only(left: 20, top: 14, right: 20, bottom: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.splashStart, AppColors.splashEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(rs.radius(20)),
              bottomRight: Radius.circular(rs.radius(20)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 28),
                blurRadius: rs.space(18),
                offset: Offset(0, rs.space(8)),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: _syncingProfile && !hasProfileContent
                ? const _ProviderHeaderLoading()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: rs.all(3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 235),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 64),
                              ),
                            ),
                            child: ValueListenableBuilder(
                              valueListenable:
                                  ProfileImageState.listenableForRole(
                                    isProvider: true,
                                  ),
                              builder: (context, value, child) {
                                final image = ProfileImageState.avatarProvider(
                                  isProvider: true,
                                );
                                return CircleAvatar(
                                  radius: rs.dimension(22),
                                  backgroundColor: AppColors.background,
                                  backgroundImage: image,
                                  child: image == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          color: AppColors.primary,
                                          size: rs.icon(22),
                                        )
                                      : null,
                                );
                              },
                            ),
                          ),
                          rs.gapW(12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Provider',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 220,
                                        ),
                                      ),
                                ),
                                rs.gapH(2),
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                rs.gapH(8),
                                _ProviderHeaderLocationPill(city: city),
                              ],
                            ),
                          ),
                          rs.gapW(12),
                          ValueListenableBuilder<int>(
                            valueListenable: ChatState.unreadCount,
                            builder: (context, unreadThreads, _) {
                              return _ProviderHeaderActionButton(
                                icon: Icons.message_outlined,
                                onTap: openChats,
                                badgeText: unreadThreads > 0
                                    ? (unreadThreads > 99
                                          ? '99+'
                                          : '$unreadThreads')
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _ProviderSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _ProviderSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: rs.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(rs.radius(16)),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: rs.space(12),
            offset: Offset(0, rs.space(4)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: rs.dimension(36),
            width: rs.dimension(36),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 20),
              borderRadius: BorderRadius.circular(rs.radius(12)),
            ),
            child: Icon(Icons.search, color: Colors.white, size: rs.icon(20)),
          ),
          rs.gapW(10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: 'Search client, service, or location',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodyMedium?.color,
                  fontSize: rs.text(14),
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Icon(
                Icons.close_rounded,
                size: rs.icon(20),
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
          rs.gapW(8),
          Container(
            height: rs.dimension(34),
            width: rs.dimension(34),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 20),
              borderRadius: BorderRadius.circular(rs.radius(10)),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 40),
              ),
            ),
            child: Icon(Icons.tune, color: Colors.white, size: rs.icon(18)),
          ),
        ],
      ),
    );
  }
}

class _ResultsCountPill extends StatelessWidget {
  final int count;

  const _ResultsCountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: rs.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF162133) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        '$count results',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: theme.textTheme.bodyMedium?.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProviderHeaderLoading extends StatelessWidget {
  const _ProviderHeaderLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ShimmerPlaceholder.circular(size: 50),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerPlaceholder(width: 120, height: 14, borderRadius: 999),
              SizedBox(height: 8),
              ShimmerPlaceholder(width: 170, height: 22, borderRadius: 999),
              SizedBox(height: 10),
              ShimmerPlaceholder(width: 120, height: 28, borderRadius: 999),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const ShimmerPlaceholder(width: 40, height: 40, borderRadius: 12),
      ],
    );
  }
}

class _ProviderHeaderLocationPill extends StatelessWidget {
  final String city;

  const _ProviderHeaderLocationPill({required this.city});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFFEEF4FF).withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 230),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: 16,
            color: AppColors.primaryDark,
          ),
          const SizedBox(width: 6),
          Text(
            city,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white : AppColors.primaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProviderHeaderActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String? badgeText;

  const _ProviderHeaderActionButton({
    required this.icon,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 36),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.16)
                      : Colors.white.withValues(alpha: 52),
                ),
              ),
              child: Icon(
                icon,
                color: isDark ? Colors.white : AppColors.primaryDark,
                size: 20,
              ),
            ),
            if (badgeText != null)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    badgeText!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FinderPostTile extends StatelessWidget {
  final FinderPostItem post;

  const _FinderPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    return Container(
      margin: EdgeInsets.only(bottom: rs.space(12)),
      padding: rs.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(rs.radius(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: rs.space(10),
            offset: Offset(0, rs.space(4)),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: rs.dimension(80),
                height: rs.dimension(80),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(rs.radius(12)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: post.avatarPath.trim().isEmpty
                    ? Icon(
                        Icons.person_rounded,
                        size: rs.icon(40),
                        color: AppColors.primary,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(rs.radius(12)),
                        child: SafeImage(
                          isAvatar: true,
                          source: post.avatarPath,
                          width: rs.dimension(80),
                          height: rs.dimension(80),
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              rs.gapW(14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.clientName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        Text(
                          post.timeLabel,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    rs.gapH(6),
                    Text(
                      post.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.3,
                      ),
                    ),
                    rs.gapH(10),
                    Wrap(
                      spacing: rs.space(6),
                      runSpacing: rs.space(6),
                      children: [
                        _MetaPill(text: post.category),
                        _MetaPill(text: post.serviceLabel),
                        _MetaPill(text: post.location),
                        if (post.preferredDate != null)
                          _PreferredDatePill(
                            preferredDate: post.preferredDate!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          rs.gapH(16),
          const Divider(height: 1, thickness: 1.2, color: AppColors.divider),
          rs.gapH(12),
          Row(
            children: [
              const Spacer(),
              PressableScale(
                onTap: () => _openChat(context),
                child: InkWell(
                  onTap: () => _openChat(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Chat Now',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openChat(BuildContext context) async {
    if (post.finderUid.trim().isEmpty) {
      AppToast.warning(context, 'Finder account unavailable for chat.');
      return;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (currentUid.isNotEmpty && currentUid == post.finderUid.trim()) {
      AppToast.info(
        context,
        'This is your own request. Use another account to start a chat.',
      );
      return;
    }

    try {
      final thread = await ChatState.openDirectThread(
        peerUid: post.finderUid,
        peerName: post.clientName,
        peerIsProvider: false,
      );
      if (!context.mounted) return;
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppToast.error(context, 'Unable to open live chat.');
    }
  }
}

class _MetaPill extends StatelessWidget {
  final String text;

  const _MetaPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
