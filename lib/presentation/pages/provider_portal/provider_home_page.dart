import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:servicefinder/core/constants/app_colors.dart';
import 'package:servicefinder/core/constants/app_spacing.dart';
import 'package:servicefinder/core/utils/app_toast.dart';
import 'package:servicefinder/core/utils/page_transition.dart';
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
import 'package:servicefinder/presentation/pages/chat/chat_conversation_page.dart';
import 'package:servicefinder/presentation/pages/chat/chat_list_page.dart';

class ProviderPortalHomePage extends StatefulWidget {
  static const String routeName = '/provider/home';

  const ProviderPortalHomePage({super.key});

  @override
  State<ProviderPortalHomePage> createState() => _ProviderPortalHomePageState();
}

class _ProviderPortalHomePageState extends State<ProviderPortalHomePage> {
  static const Duration _doublePullWindow = Duration(seconds: 2);
  DateTime? _lastPullAt;
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
                  body: SafeArea(
                    child: RefreshIndicator(
                      onRefresh: _handleRefresh,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverToBoxAdapter(child: const _ProviderTopHeader()),
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.lg,
                              AppSpacing.xl,
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
                                const SizedBox(height: 18),
                                Row(
                                  children: [
                                    Text(
                                      _searchQuery.isEmpty ? 'Finder Requests' : 'Search Results',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_searchQuery.isEmpty ? pagination.totalItems : filteredPosts.length} results',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Search by client name, service, or location',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                                const SizedBox(height: 12),
                                AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 220),
                                  child: isLoading && posts.isEmpty
                                      ? const SizedBox(
                                          height: 320,
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
                                              shrinkWrap: true,
                                              physics: const NeverScrollableScrollPhysics(),
                                              itemCount: filteredPosts.length,
                                              cacheExtent: 1000,
                                              itemBuilder: (context, index) => _FinderPostTile(post: filteredPosts[index]),
                                            ),
                                ),
                                if (pagination.totalPages > 1 && _searchQuery.isEmpty) ...[
                                  const SizedBox(height: 12),
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
    final now = DateTime.now();
    final last = _lastPullAt;
    final isSecondPull =
        last != null && now.difference(last) <= _doublePullWindow;
    if (!isSecondPull) {
      _lastPullAt = now;
      return;
    }
    _lastPullAt = null;
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ChatState.refreshUnreadCount());
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

  @override
  Widget build(BuildContext context) {
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
        return Container(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.splashStart, AppColors.splashEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 235),
                      shape: BoxShape.circle,
                    ),
                    child: ValueListenableBuilder(
                      valueListenable: ProfileImageState.listenableForRole(
                        isProvider: true,
                      ),
                      builder: (context, value, child) {
                        final image = ProfileImageState.avatarProvider(
                          isProvider: true,
                        );
                        return CircleAvatar(
                          radius: 19,
                          backgroundColor: AppColors.background,
                          backgroundImage: image,
                          child: image == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Provider',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                        Text(
                          displayName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  PressableScale(
                    onTap: openChats,
                    child: InkWell(
                      onTap: openChats,
                      borderRadius: BorderRadius.circular(10),
                      child: ValueListenableBuilder<int>(
                        valueListenable: ChatState.unreadCount,
                        builder: (context, unreadThreads, _) {
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x20000000),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.message_outlined,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              if (unreadThreads > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 1.2,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      unreadThreads > 99
                                          ? '99+'
                                          : '$unreadThreads',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
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
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: 'Search client name, service, location',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(width: 8),
          Container(
            height: 34,
            width: 34,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
  }
}

class _FinderPostTile extends StatelessWidget {
  final FinderPostItem post;

  const _FinderPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: post.avatarPath.trim().isEmpty
                    ? const Icon(
                        Icons.person_rounded,
                        size: 40,
                        color: AppColors.primary,
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SafeImage(
                          isAvatar: true,
                          source: post.avatarPath,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.clientName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        Text(
                          post.timeLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      post.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
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
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1.2, color: AppColors.divider),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              PressableScale(
                onTap: () => _openChat(context),
                child: InkWell(
                  onTap: () => _openChat(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
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
