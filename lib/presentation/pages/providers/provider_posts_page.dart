import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../core/utils/category_utils.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/chat_state.dart';
import '../../state/provider_post_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../chat/chat_conversation_page.dart';
import 'provider_detail_page.dart';

class ProviderPostsPage extends StatefulWidget {
  static const String routeName = '/provider/posts/all';
  final String? initialQuery;
  final String? initialCategory;

  const ProviderPostsPage({super.key, this.initialQuery, this.initialCategory});

  @override
  State<ProviderPostsPage> createState() => _ProviderPostsPageState();
}

class _ProviderPostsPageState extends State<ProviderPostsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String? _category;
  bool _isPaging = false;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _category = widget.initialCategory;
    _searchController.text = _query;
    unawaited(ProviderPostState.refresh(page: 1));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ProviderPostItem>>(
      valueListenable: ProviderPostState.posts,
      builder: (context, posts, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: ProviderPostState.loading,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<PaginationMeta?>(
              valueListenable: ProviderPostState.pagination,
              builder: (context, pagination, _) {
                final query = _query.trim().toLowerCase();
                final filtered = posts.where((post) {
                  final matchesQuery = query.isEmpty ||
                      post.providerName.toLowerCase().contains(query) ||
                      post.category.toLowerCase().contains(query) ||
                      post.serviceList.any(
                        (s) => s.toLowerCase().contains(query),
                      );
                  final matchesCategory =
                      _category == null || post.category == _category;
                  return matchesQuery && matchesCategory;
                }).toList();

                return Scaffold(
                  body: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      child: Column(
                        children: [
                          const AppTopBar(title: 'Service Offers'),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _searchController,
                            onChanged: (val) => setState(() => _query = val),
                            decoration: InputDecoration(
                              hintText: 'Search providers or services',
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: isLoading && posts.isEmpty
                                ? const Center(
                                    child: AppStatePanel.loading(
                                      title: 'Fetching offers',
                                    ),
                                  )
                                : filtered.isEmpty
                                    ? Center(
                                        child: AppStatePanel.empty(
                                          title: 'No offers found',
                                          message:
                                              'Try adjusting your search or category filter.',
                                        ),
                                      )
                                    : RefreshIndicator(
                                        onRefresh: () =>
                                            ProviderPostState.refresh(page: 1),
                                        child: ListView.separated(
                                          padding: const EdgeInsets.only(
                                            bottom: 24,
                                          ),
                                          itemCount: filtered.length,
                                          separatorBuilder: (context, index) =>
                                              const SizedBox(height: 16),
                                          itemBuilder: (context, index) {
                                            return _PostOfferCard(
                                              post: filtered[index],
                                              onTap: () => _openProvider(
                                                filtered[index],
                                              ),
                                              onChat: () => _openChat(
                                                filtered[index],
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                          ),
                          if (pagination != null &&
                              pagination.totalPages > 1 &&
                              _query.isEmpty &&
                              _category == null)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: PaginationBar(
                                currentPage: pagination.page,
                                totalPages: pagination.totalPages,
                                loading: _isPaging,
                                onPageSelected: _goToPage,
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

  Future<void> _goToPage(int page) async {
    if (_isPaging) return;
    setState(() => _isPaging = true);
    try {
      await ProviderPostState.refresh(page: page);
    } finally {
      if (mounted) setState(() => _isPaging = false);
    }
  }

  void _openProvider(ProviderPostItem post) {
    Navigator.push(
      context,
      slideFadeRoute(ProviderDetailPage(provider: _providerFromPost(post))),
    );
  }

  Future<void> _openChat(ProviderPostItem post) async {
    final uid = post.providerUid.trim();
    if (uid.isEmpty) return;
    try {
      final thread = await ChatState.openDirectThread(
        peerUid: uid,
        peerName: post.providerName,
        peerIsProvider: true,
      );
      if (!mounted) return;
      Navigator.push(
        context,
        slideFadeRoute(ChatConversationPage(thread: thread)),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Unable to start chat.');
    }
  }

  ProviderItem _providerFromPost(ProviderPostItem post) {
    final role = post.category.trim().isEmpty ? 'Cleaner' : post.category;
    final services = _servicesForProvider(post);
    return ProviderItem(
      uid: post.providerUid.trim(),
      name: post.providerName.trim().isEmpty
          ? 'Service Provider'
          : post.providerName.trim(),
      role: role,
      rating: post.rating,
      imagePath: post.avatarPath,
      accentColor: accentForCategory(role),
      services: services,
      providerType: post.providerType,
      companyName: post.providerCompanyName.trim(),
      maxWorkers: post.providerMaxWorkers < 1 ? 1 : post.providerMaxWorkers,
      blockedDates: post.blockedDates,
    );
  }

  List<String> _servicesForProvider(ProviderPostItem seed) {
    final allPosts = ProviderPostState.allPosts.value;
    final lookupPosts =
        allPosts.isNotEmpty ? allPosts : ProviderPostState.posts.value;
    final seedUid = seed.providerUid.trim().toLowerCase();
    final seedName = seed.providerName.trim().toLowerCase();

    final values = <String>{};
    for (final item in lookupPosts) {
      final sameProvider = seedUid.isNotEmpty
          ? item.providerUid.trim().toLowerCase() == seedUid
          : item.providerName.trim().toLowerCase() == seedName;
      if (!sameProvider) continue;
      for (final service in item.serviceList) {
        final normalized = service.trim();
        if (normalized.isNotEmpty) values.add(normalized);
      }
    }

    if (values.isEmpty) {
      values.addAll(seed.serviceList);
    }
    return values.toList(growable: false)..sort();
  }
}

class _PostOfferCard extends StatelessWidget {
  final ProviderPostItem post;
  final VoidCallback onTap;
  final VoidCallback onChat;

  const _PostOfferCard({
    required this.post,
    required this.onTap,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundImage: safeImageProvider(post.avatarPath),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    post.providerName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '\$${post.ratePerHour.toStringAsFixed(0)}/hr',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              post.serviceLabel,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              post.details,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: 4),
                Text(
                  post.area,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Text(
                  post.timeLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onChat,
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: const Text('Chat'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('View Profile'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
