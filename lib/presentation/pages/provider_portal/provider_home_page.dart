import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/chat_state.dart';
import '../../state/finder_post_state.dart';
import '../../state/profile_image_state.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_conversation_page.dart';
import '../chat/chat_list_page.dart';
import 'provider_finder_search_page.dart';

class ProviderPortalHomePage extends StatefulWidget {
  static const String routeName = '/provider/home';

  const ProviderPortalHomePage({super.key});

  @override
  State<ProviderPortalHomePage> createState() => _ProviderPortalHomePageState();
}

class _ProviderPortalHomePageState extends State<ProviderPortalHomePage> {
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(FinderPostState.refresh(page: 1));
    });
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
                final currentPage = _normalizedPage(pagination.page);
                final listBody = isLoading && posts.isEmpty
                    ? const AppStatePanel.loading(
                        title: 'Loading finder requests',
                      )
                    : posts.isEmpty
                    ? const AppStatePanel.empty(
                        title: 'No finder requests yet',
                        message: 'New requests will appear here.',
                      )
                    : Column(
                        key: ValueKey<String>(
                          'provider_home_posts_${posts.length}_${pagination.page}',
                        ),
                        children: posts
                            .map((post) => _FinderPostTile(post: post))
                            .toList(growable: false),
                      );

                return Scaffold(
                  body: SafeArea(
                    child: CustomScrollView(
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
                                onTap: () => Navigator.push(
                                  context,
                                  slideFadeRoute(
                                    const ProviderFinderSearchPage(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                children: [
                                  Text(
                                    'Finder Requests',
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
                                    '${pagination.totalItems} results',
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
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 12),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 220),
                                child: listBody,
                              ),
                              if (pagination.totalPages > 1) ...[
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
                  bottomNavigationBar: const AppBottomNav(
                    current: AppBottomTab.home,
                  ),
                );
              },
            );
          },
        );
      },
    );
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

class _ProviderTopHeader extends StatelessWidget {
  const _ProviderTopHeader();

  @override
  Widget build(BuildContext context) {
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
                          backgroundColor: const Color(0xFFEAF1FF),
                          backgroundImage: image,
                          child: image == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 18,
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
                          'Welcome back',
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
                    onTap: () => Navigator.push(
                      context,
                      slideFadeRoute(const ChatListPage()),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context,
                        slideFadeRoute(const ChatListPage()),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
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
  final VoidCallback onTap;

  const _ProviderSearchBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              child: Text(
                'Search name, service, location',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
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
      ),
    );
  }
}

class _FinderPostTile extends StatelessWidget {
  final FinderPostItem post;

  const _FinderPostTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () => _openChat(context),
      child: InkWell(
        onTap: () => _openChat(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C0F172A),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 23,
                backgroundImage: AssetImage(post.avatarPath),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            post.clientName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 13,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 3),
                              Text(post.timeLabel),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      post.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
        ),
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
