import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/provider.dart';
import '../../../domain/entities/provider_portal.dart';
import '../../state/chat_state.dart';
import '../../state/provider_post_state.dart';
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

  @override
  void initState() {
    super.initState();
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: _PostSearchBar(
                      controller: _controller,
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                ],
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
              child: ValueListenableBuilder<List<ProviderPostItem>>(
                valueListenable: ProviderPostState.posts,
                builder: (context, posts, _) {
                  final filtered = posts.where((post) {
                    final matchesQuery =
                        query.isEmpty ||
                        post.providerName.toLowerCase().contains(query) ||
                        post.service.toLowerCase().contains(query) ||
                        post.category.toLowerCase().contains(query) ||
                        post.area.toLowerCase().contains(query) ||
                        post.details.toLowerCase().contains(query);
                    final matchesCategory =
                        _selectedCategory == null ||
                        post.category == _selectedCategory;
                    return matchesQuery && matchesCategory;
                  }).toList();

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    children: [
                      Row(
                        children: [
                          Text(
                            'All provider posts',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Spacer(),
                          Text(
                            '${filtered.length}',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (filtered.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Text(
                            _query.trim().isEmpty
                                ? 'No provider posts available yet.'
                                : 'No provider posts match "${_query.trim()}".',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ...filtered.map(
                        (post) => _ProviderPostCard(
                          post: post,
                          onTap: () => _openProviderPostProfile(post),
                          onChatTap: () => _openProviderPostChat(post),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
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
    return ProviderItem(
      uid: post.providerUid.trim(),
      name: post.providerName.trim().isEmpty
          ? 'Service Provider'
          : post.providerName.trim(),
      role: role,
      rating: 4.8,
      imagePath: imagePath,
      accentColor: _accentFromCategory(role),
      services: <String>[post.service.trim()],
    );
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
