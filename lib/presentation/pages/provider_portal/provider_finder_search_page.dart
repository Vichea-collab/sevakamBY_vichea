import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/chat_state.dart';
import '../../state/finder_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_conversation_page.dart';

class ProviderFinderSearchPage extends StatefulWidget {
  static const String routeName = '/provider/search';

  final String initialQuery;

  const ProviderFinderSearchPage({super.key, this.initialQuery = ''});

  @override
  State<ProviderFinderSearchPage> createState() =>
      _ProviderFinderSearchPageState();
}

class _ProviderFinderSearchPageState extends State<ProviderFinderSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    unawaited(_primeFinderRequests());
    _query = widget.initialQuery.trim();
    if (_query.isNotEmpty) {
      _searchController.text = _query;
      _searchController.selection = TextSelection.collapsed(
        offset: _query.length,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: AppTopBar(
                title: 'Finder Requests',
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
              child: _SearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: FinderPostState.loading,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<FinderPostItem>>(
                    valueListenable: FinderPostState.allPosts,
                    builder: (context, allPosts, _) {
                      return ValueListenableBuilder<List<FinderPostItem>>(
                        valueListenable: FinderPostState.posts,
                        builder: (context, pagedPosts, _) {
                          return ValueListenableBuilder<PaginationMeta>(
                            valueListenable: FinderPostState.pagination,
                            builder: (context, pagination, _) {
                              final normalized = _query.trim().toLowerCase();
                              final lookupPosts = allPosts.isNotEmpty
                                  ? allPosts
                                  : pagedPosts;
                              final source = normalized.isEmpty
                                  ? pagedPosts
                                  : lookupPosts;
                              final posts = normalized.isEmpty
                                  ? source
                                  : source.where((post) {
                                      return post.clientName
                                              .toLowerCase()
                                              .contains(normalized) ||
                                          post.serviceList.any(
                                            (service) => service
                                                .toLowerCase()
                                                .contains(normalized),
                                          ) ||
                                          post.location.toLowerCase().contains(
                                            normalized,
                                          ) ||
                                          post.category.toLowerCase().contains(
                                            normalized,
                                          ) ||
                                          post.message.toLowerCase().contains(
                                            normalized,
                                          );
                                    }).toList();
                              final currentPage = _normalizedPage(
                                pagination.page,
                              );
                              final resultCount = normalized.isEmpty
                                  ? pagination.totalItems
                                  : posts.length;

                              final Widget body;
                              if (isLoading && pagedPosts.isEmpty) {
                                body = const AppStatePanel.loading(
                                  title: 'Loading finder requests',
                                );
                              } else if (posts.isEmpty) {
                                body = AppStatePanel.empty(
                                  title: 'No finder requests found',
                                  message: _query.trim().isEmpty
                                      ? 'New requests will appear here.'
                                      : 'Try another keyword.',
                                );
                              } else {
                                body = Column(
                                  key: ValueKey<String>(
                                    'finder_posts_${posts.length}_${currentPage}_$normalized',
                                  ),
                                  children: posts
                                      .map(
                                        (post) => _FinderPostTile(post: post),
                                      )
                                      .toList(growable: false),
                                );
                              }

                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  6,
                                  20,
                                  20,
                                ),
                                children: [
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
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEAF1FF),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          '$resultCount',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Search by client name, service, or location',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    child: body,
                                  ),
                                  if (pagination.totalPages > 1 &&
                                      normalized.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: PaginationBar(
                                        currentPage: currentPage,
                                        totalPages: pagination.totalPages,
                                        loading: _isPaging,
                                        onPageSelected: _goToPage,
                                      ),
                                    ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _primeFinderRequests() async {
    try {
      await FinderPostState.refresh(page: 1);
      await FinderPostState.refreshAllForLookup();
    } catch (_) {
      // Keep page usable with paged data when lookup refresh fails.
    }
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _onFocusChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.divider,
          width: focused ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              focusNode: _focusNode,
              controller: widget.controller,
              onChanged: widget.onChanged,
              autofocus: true,
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                hintText: 'Search name, service, location',
              ),
            ),
          ),
          if (widget.controller.text.trim().isNotEmpty)
            GestureDetector(
              onTap: () {
                widget.controller.clear();
                widget.onChanged('');
                setState(() {});
              },
              child: const Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
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
