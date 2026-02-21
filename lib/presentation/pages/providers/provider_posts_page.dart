import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/chat_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/pressable_scale.dart';
import '../chat/chat_conversation_page.dart';
import 'provider_detail_page.dart';

class ProviderPostsPage extends StatefulWidget {
  static const String routeName = '/provider-posts';

  final String initialQuery;
  final String? initialCategory;

  const ProviderPostsPage({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
  });

  @override
  State<ProviderPostsPage> createState() => _ProviderPostsPageState();
}

class _ProviderPostsPageState extends State<ProviderPostsPage> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    unawaited(_primeProviderPosts());
    _query = widget.initialQuery.trim();
    _selectedCategory = widget.initialCategory;
    if (_query.isNotEmpty) {
      _controller.text = _query;
      _controller.selection = TextSelection.collapsed(offset: _query.length);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim().toLowerCase();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
              child: AppTopBar(
                title: 'Provider Posts',
                onBack: () => Navigator.maybePop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: _PostSearchBar(
                controller: _controller,
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            if (_selectedCategory != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary),
                          color: const Color(0xFFEAF1FF),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedCategory!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedCategory = null),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: ProviderPostState.loading,
                builder: (context, isLoading, _) {
                  return ValueListenableBuilder<List<ProviderPostItem>>(
                    valueListenable: ProviderPostState.allPosts,
                    builder: (context, allPosts, _) {
                      return ValueListenableBuilder<List<ProviderPostItem>>(
                        valueListenable: ProviderPostState.posts,
                        builder: (context, pagedPosts, _) {
                          return ValueListenableBuilder<PaginationMeta>(
                            valueListenable: ProviderPostState.pagination,
                            builder: (context, pagination, _) {
                              final lookupPosts = allPosts.isNotEmpty
                                  ? allPosts
                                  : pagedPosts;
                              final source =
                                  query.isEmpty && _selectedCategory == null
                                  ? pagedPosts
                                  : lookupPosts;
                              final filtered = source.where((post) {
                                final matchesQuery =
                                    query.isEmpty ||
                                    post.providerName.toLowerCase().contains(
                                      query,
                                    ) ||
                                    post.service.toLowerCase().contains(
                                      query,
                                    ) ||
                                    post.category.toLowerCase().contains(
                                      query,
                                    ) ||
                                    post.area.toLowerCase().contains(query) ||
                                    post.details.toLowerCase().contains(query);
                                final matchesCategory =
                                    _selectedCategory == null ||
                                    post.category == _selectedCategory;
                                return matchesQuery && matchesCategory;
                              }).toList();
                              final currentPage = _normalizedPage(
                                pagination.page,
                              );
                              final resultCount =
                                  query.isEmpty && _selectedCategory == null
                                  ? pagination.totalItems
                                  : filtered.length;

                              final Widget body;
                              if (isLoading && pagedPosts.isEmpty) {
                                body = const AppStatePanel.loading(
                                  title: 'Loading provider posts',
                                );
                              } else if (filtered.isEmpty) {
                                body = AppStatePanel.empty(
                                  title: _query.trim().isEmpty
                                      ? 'No provider posts available yet'
                                      : 'No matches found',
                                  message: _query.trim().isEmpty
                                      ? 'Create a provider post to appear in this list.'
                                      : 'Try a different keyword or clear filters.',
                                );
                              } else {
                                body = Column(
                                  key: ValueKey<String>(
                                    'provider_posts_${filtered.length}_${currentPage}_${query}_${_selectedCategory ?? ''}',
                                  ),
                                  children: filtered
                                      .map(
                                        (post) => _ProviderPostCard(
                                          post: post,
                                          onTap: () =>
                                              _openProviderPostProfile(post),
                                          onChatTap: () =>
                                              _openProviderPostChat(post),
                                        ),
                                      )
                                      .toList(growable: false),
                                );
                              }

                              return ListView(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  8,
                                  20,
                                  24,
                                ),
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'All provider posts',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleLarge,
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
                                  const SizedBox(height: 12),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 220),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: body,
                                  ),
                                  if (pagination.totalPages > 1 &&
                                      query.isEmpty &&
                                      _selectedCategory == null)
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

  Future<void> _primeProviderPosts() async {
    try {
      await ProviderPostState.refresh(page: 1);
      await ProviderPostState.refreshAllForLookup();
    } catch (_) {
      // Keep page usable with paged data when lookup refresh fails.
    }
  }

  Future<void> _openProviderPostChat(ProviderPostItem post) async {
    if (post.providerUid.trim().isEmpty) {
      AppToast.warning(context, 'Provider account unavailable for chat.');
      return;
    }
    final currentUid = FirebaseAuth.instance.currentUser?.uid.trim() ?? '';
    if (currentUid.isNotEmpty && currentUid == post.providerUid.trim()) {
      AppToast.info(
        context,
        'Switch to a finder account to chat with this provider post.',
      );
      return;
    }
    try {
      final thread = await ChatState.openDirectThread(
        peerUid: post.providerUid,
        peerName: post.providerName,
        peerIsProvider: true,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      );
    } catch (_) {
      if (!mounted) return;
      AppToast.error(context, 'Unable to open live chat.');
    }
  }

  void _openProviderPostProfile(ProviderPostItem post) {
    Navigator.push(
      context,
      slideFadeRoute(ProviderDetailPage(provider: _providerFromPost(post))),
    );
  }

  ProviderItem _providerFromPost(ProviderPostItem post) {
    final role = post.category.trim().isEmpty ? 'Cleaner' : post.category;
    final imagePath = post.avatarPath.startsWith('assets/')
        ? post.avatarPath
        : 'assets/images/profile.jpg';
    final services = _servicesForProvider(post);
    return ProviderItem(
      uid: post.providerUid.trim(),
      name: post.providerName.trim().isEmpty
          ? 'Service Provider'
          : post.providerName.trim(),
      role: role,
      rating: 4.8,
      imagePath: imagePath,
      accentColor: _accentFromCategory(role),
      services: services,
      providerType: post.providerType,
      companyName: post.providerCompanyName.trim(),
      maxWorkers: post.providerMaxWorkers < 1 ? 1 : post.providerMaxWorkers,
    );
  }

  List<String> _servicesForProvider(ProviderPostItem seed) {
    final allPosts = ProviderPostState.allPosts.value;
    final lookupPosts = allPosts.isNotEmpty
        ? allPosts
        : ProviderPostState.posts.value;
    final seedUid = seed.providerUid.trim().toLowerCase();
    final seedName = seed.providerName.trim().toLowerCase();
    final seedCategory = seed.category.trim().toLowerCase();

    final values = <String>{};
    for (final post in lookupPosts) {
      final sameProvider = seedUid.isNotEmpty
          ? post.providerUid.trim().toLowerCase() == seedUid
          : post.providerName.trim().toLowerCase() == seedName;
      if (!sameProvider) continue;
      if (seedCategory.isNotEmpty &&
          post.category.trim().toLowerCase() != seedCategory) {
        continue;
      }
      final service = post.service.trim();
      if (service.isNotEmpty) values.add(service);
    }

    if (values.isEmpty && seed.service.trim().isNotEmpty) {
      values.add(seed.service.trim());
    }

    final services = values.toList(growable: false)..sort();
    return services;
  }

  Color _accentFromCategory(String category) {
    switch (category.trim().toLowerCase()) {
      case 'plumber':
        return const Color(0xFF0E8AD6);
      case 'electrician':
        return const Color(0xFFF59E0B);
      case 'cleaner':
        return const Color(0xFF10B981);
      case 'home appliance':
      case 'appliance':
        return const Color(0xFF6366F1);
      default:
        return AppColors.primary;
    }
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    if (_isPaging || targetPage == ProviderPostState.pagination.value.page) {
      return;
    }
    setState(() => _isPaging = true);
    try {
      await ProviderPostState.refresh(page: targetPage);
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

class _PostSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _PostSearchBar({required this.controller, required this.onChanged});

  @override
  State<_PostSearchBar> createState() => _PostSearchBarState();
}

class _PostSearchBarState extends State<_PostSearchBar> {
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
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                hintText: 'Search provider, service, or location',
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

class _ProviderPostCard extends StatelessWidget {
  final ProviderPostItem post;
  final VoidCallback onTap;
  final VoidCallback onChatTap;

  const _ProviderPostCard({
    required this.post,
    required this.onTap,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundImage: AssetImage(post.avatarPath),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      post.providerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '\$${post.ratePerHour.toStringAsFixed(0)}/hr',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${post.service} • ${post.timeLabel}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(post.details, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PostPill(text: post.category),
                  _PostPill(text: post.area),
                  if (post.availableNow) const _PostPill(text: 'Available now'),
                ],
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onChatTap,
                  child: const Text('Chat'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PostPill extends StatelessWidget {
  final String text;

  const _PostPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
