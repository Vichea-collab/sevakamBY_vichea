import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/support_ticket_options.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/profile_settings.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';
import 'help_support_chat_page.dart';

class HelpSupportPage extends StatefulWidget {
  static const String routeName = '/profile/help';

  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  Timer? _pollTimer;
  int _activePage = 1;
  bool _paging = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTickets
        : ProfileSettingsState.finderHelpTickets;
    final loadingListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketsLoading
        : ProfileSettingsState.finderHelpTicketsLoading;
    final paginationListenable = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketsPagination
        : ProfileSettingsState.finderHelpTicketsPagination;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FBFF), Color(0xFFF1F5FC)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -70,
              right: -40,
              child: _BackgroundGlow(
                size: 200,
                color: const Color(0x332563EB),
              ),
            ),
            Positioned(
              top: 260,
              left: -50,
              child: _BackgroundGlow(
                size: 150,
                color: const Color(0x1A14B8A6),
              ),
            ),
            SafeArea(
              child: ValueListenableBuilder<List<HelpSupportTicket>>(
                valueListenable: ticketListenable,
                builder: (context, tickets, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: loadingListenable,
                    builder: (context, loading, _) {
                      return ValueListenableBuilder<PaginationMeta>(
                        valueListenable: paginationListenable,
                        builder: (context, pagination, _) {
                          return RefreshIndicator(
                            onRefresh: () =>
                                ProfileSettingsState.refreshCurrentHelpTickets(
                                  page: _activePage,
                                ),
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.lg,
                                10,
                                AppSpacing.lg,
                                AppSpacing.xl,
                              ),
                              children: [
                                const AppTopBar(
                                  title: 'Help & support',
                                  actions: [],
                                ),
                                const SizedBox(height: 14),
                                _buildHeroCard(context),
                                const SizedBox(height: 18),
                                _buildCreateRequestCard(context),
                                const SizedBox(height: 18),
                                _buildInboxSection(
                                  context,
                                  tickets: tickets,
                                  loading: loading,
                                  pagination: pagination,
                                ),
                              ],
                            ),
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

  Widget _buildHeroCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5BD4), Color(0xFF4F8EFF), Color(0xFF9BC3FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2563EB),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            ),
            child: const Text(
              'Support center',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Professional support, clearly organized',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCreateRequestCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE4F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Request form'),
          const SizedBox(height: 10),
          Text(
            'Create a support request',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Keep the main screen focused. Open the request form only when you need it.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFDCE6F7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Open support request dialog',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose a topic, complete the guided form, and submit without taking over the whole page.',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.45,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openCreateRequestDialog,
                  icon: const Icon(Icons.add_comment_rounded),
                  label: const Text('Create support request'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInboxSection(
    BuildContext context, {
    required List<HelpSupportTicket> tickets,
    required bool loading,
    required PaginationMeta pagination,
  }) {
    Widget content;
    if (loading && tickets.isEmpty) {
      content = const SizedBox(
        height: 320,
        child: Center(
          child: AppStatePanel.loading(title: 'Loading support tickets'),
        ),
      );
    } else if (tickets.isEmpty) {
      content = const AppStatePanel.empty(
        title: 'No support tickets yet',
        message: 'Your submitted support requests will appear here.',
      );
    } else {
      content = Column(
        children: [
          for (var index = 0; index < tickets.length; index++) ...[
            _buildTicketCard(tickets[index]),
            if (index < tickets.length - 1) const SizedBox(height: 12),
          ],
          if (pagination.totalPages > 1)
            Padding(
              padding: const EdgeInsets.only(top: 14),
              child: PaginationBar(
                currentPage: _normalizedPage(pagination.page),
                totalPages: pagination.totalPages,
                loading: _paging,
                onPageSelected: _goToPage,
              ),
            ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFDCE4F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Your tickets'),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your support inbox',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Continue any ticket below to chat directly with admin support.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: content),
        ],
      ),
    );
  }

  Future<void> _openCreateRequestDialog() async {
    final created = await showDialog<HelpSupportTicket>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => const _CreateSupportRequestDialog(),
    );
    if (created == null || !mounted) return;
    _activePage = 1;
    await ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage);
    if (!mounted) return;
    AppToast.success(context, 'Your request has been saved.');
    await _openChat(created);
  }

  Future<void> _goToPage(int page) async {
    final targetPage = _normalizedPage(page);
    final currentPage = ProfileSettingsState.isProvider
        ? ProfileSettingsState.providerHelpTicketsPagination.value.page
        : ProfileSettingsState.finderHelpTicketsPagination.value.page;
    if (_paging || targetPage == currentPage) return;
    setState(() => _paging = true);
    try {
      _activePage = targetPage;
      await ProfileSettingsState.refreshCurrentHelpTickets(page: targetPage);
    } finally {
      if (mounted) {
        setState(() => _paging = false);
      }
    }
  }

  int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  Widget _buildTicketCard(HelpSupportTicket ticket) {
    final normalized = ticket.status.toLowerCase();
    final statusColor = switch (normalized) {
      'resolved' => AppColors.success,
      'closed' => AppColors.textSecondary,
      'waiting_on_user' => const Color(0xFF7C3AED),
      _ => const Color(0xFFF59E0B),
    };
    final latestText = ticket.lastMessageText.isEmpty
        ? ticket.message
        : ticket.lastMessageText;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _openChat(ticket),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF9FBFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD7E1F2)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A0F172A),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    normalized == 'waiting_on_user'
                        ? Icons.mark_chat_unread_rounded
                        : Icons.chat_bubble_outline_rounded,
                    color: statusColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _ticketMetaPill(
                            supportTicketCategoryLabel(ticket.category),
                            const Color(0xFF2563EB),
                          ),
                          _ticketMetaPill(
                            _prettyPriority(ticket.priority),
                            _priorityColor(ticket.priority),
                          ),
                          _ticketMetaPill(
                            _prettySupportStatus(normalized),
                            statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      if (ticket.subcategory.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          supportTicketSubcategoryLabel(
                            categoryId: ticket.category,
                            subcategoryId: ticket.subcategory,
                          ),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE1E8F4)),
              ),
              child: Text(
                latestText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Last activity ${_formatDate(ticket.lastMessageAt ?? ticket.createdAt)}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _openChat(ticket),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Open thread'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChat(HelpSupportTicket ticket) async {
    if (ticket.id.isEmpty) {
      AppToast.info(
        context,
        'Ticket is syncing. Pull to refresh then open chat.',
      );
      return;
    }
    await Navigator.of(
      context,
    ).push(slideFadeRoute(HelpSupportChatPage(ticket: ticket)));
    if (!mounted) return;
    unawaited(
      ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage),
    );
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) async {
      if (!mounted || _paging) return;
      final isLoading = ProfileSettingsState.isProvider
          ? ProfileSettingsState.providerHelpTicketsLoading.value
          : ProfileSettingsState.finderHelpTicketsLoading.value;
      if (isLoading) return;
      try {
        await ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage);
      } catch (_) {
        // Background refresh failure should not interrupt typing.
      }
    });
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }

  Widget _ticketMetaPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _prettyPriority(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'High priority';
      case 'low':
        return 'Low priority';
      default:
        return 'Normal priority';
    }
  }

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'low':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0EA5E9);
    }
  }

  String _prettySupportStatus(String value) {
    switch (value.toLowerCase()) {
      case 'waiting_on_admin':
        return 'Waiting for admin';
      case 'waiting_on_user':
        return 'Waiting for your reply';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }
}

class _GuidedSupportField {
  final String label;
  final String hint;
  final TextInputType? keyboardType;

  const _GuidedSupportField({
    required this.label,
    required this.hint,
    this.keyboardType,
  });
}

class _CreateSupportRequestDialog extends StatefulWidget {
  const _CreateSupportRequestDialog();

  @override
  State<_CreateSupportRequestDialog> createState() =>
      _CreateSupportRequestDialogState();
}

class _CreateSupportRequestDialogState extends State<_CreateSupportRequestDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _detailOneController = TextEditingController();
  final TextEditingController _detailTwoController = TextEditingController();
  bool _sending = false;
  late String _selectedCategoryId;
  late String _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = supportTicketCategories.first.id;
    _selectedSubcategoryId =
        supportTicketCategories.first.subcategories.first.id;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _detailOneController.dispose();
    _detailTwoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = supportTicketCategoryById(_selectedCategoryId);
    final subcategory = supportTicketSubcategoryById(
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
    );
    final guidedFields = _guidedFieldsForSelection();

    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920, maxHeight: 760),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFDCE4F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF1FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'New request',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Create support request',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose the issue type and send a complete request.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _sending ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 840;
                      final selector = _buildTopicPanel(
                        context,
                        category: category,
                        subcategory: subcategory,
                      );
                      final form = _buildFormPanel(
                        context,
                        category: category,
                        subcategory: subcategory,
                        guidedFields: guidedFields,
                      );

                      if (compact) {
                        return Column(
                          children: [
                            selector,
                            const SizedBox(height: 14),
                            form,
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 300, child: selector),
                          const SizedBox(width: 14),
                          Expanded(child: form),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopicPanel(
    BuildContext context, {
    required SupportTicketCategoryOption category,
    required SupportTicketSubcategoryOption subcategory,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCE6F7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(category.icon, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  category.label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            category.description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _buildSelectField(
            context,
            label: 'Category',
            value: _selectedCategoryId,
            items: supportTicketCategories
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              final next = supportTicketCategoryById(value);
              setState(() {
                _selectedCategoryId = value;
                _selectedSubcategoryId = next.subcategories.first.id;
                _detailOneController.clear();
                _detailTwoController.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildSelectField(
            context,
            label: 'Subcategory',
            value: _selectedSubcategoryId,
            items: category.subcategories
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.id,
                    child: Text(item.label),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedSubcategoryId = value;
                _detailOneController.clear();
                _detailTwoController.clear();
              });
            },
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD9E6FA)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instant guidance',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subcategory.autoReply,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormPanel(
    BuildContext context, {
    required SupportTicketCategoryOption category,
    required SupportTicketSubcategoryOption subcategory,
    required List<_GuidedSupportField> guidedFields,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E9F5)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _metaPill(category.label, const Color(0xFF2563EB)),
                _metaPill(subcategory.label, const Color(0xFF0EA5E9)),
                _metaPill(
                  _prettyPriority(subcategory.priority),
                  _priorityColor(subcategory.priority),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Subject',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              hint: 'Briefly describe the issue',
              controller: _titleController,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Subject is required';
                }
                return null;
              },
            ),
            if (guidedFields.isNotEmpty) ...[
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final fields = List.generate(guidedFields.length, (index) {
                    return _buildGuidedInput(
                      context,
                      field: guidedFields[index],
                      controller: index == 0
                          ? _detailOneController
                          : _detailTwoController,
                    );
                  });

                  if (compact || fields.length == 1) {
                    return Column(
                      children: [
                        for (var index = 0; index < fields.length; index++) ...[
                          fields[index],
                          if (index < fields.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: fields[0]),
                      const SizedBox(width: 12),
                      Expanded(child: fields[1]),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 14),
            Text(
              'Describe the issue',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AppTextField(
              hint: 'Explain what happened, what you expected, and what you need from support.',
              controller: _messageController,
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Message is required';
                }
                return null;
              },
              minLines: 5,
              maxLines: 6,
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAF8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFCFE6D9)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.tips_and_updates_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tip: include booking IDs, payment references, screenshots, or exact screen names to reduce back-and-forth.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: _sending ? 'Sending...' : 'Send support request',
              onPressed: _sending ? null : _sendTicket,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuidedInput(
    BuildContext context, {
    required _GuidedSupportField field,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          field.label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        AppTextField(
          hint: field.hint,
          controller: controller,
          keyboardType: field.keyboardType,
        ),
      ],
    );
  }

  Widget _buildSelectField(
    BuildContext context, {
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('dialog_select_${label}_$value'),
          initialValue: value,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(
            suffixIcon: Icon(Icons.keyboard_arrow_down_rounded),
          ),
        ),
      ],
    );
  }

  Future<void> _sendTicket() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    final guidedFields = _guidedFieldsForSelection();
    final guidedControllers = [_detailOneController, _detailTwoController];
    for (var index = 0; index < guidedFields.length; index++) {
      if (guidedControllers[index].text.trim().isEmpty) {
        AppToast.error(context, '${guidedFields[index].label} is required.');
        return;
      }
    }

    setState(() => _sending = true);
    final detailLines = <String>[];
    for (var index = 0; index < guidedFields.length; index++) {
      final value = guidedControllers[index].text.trim();
      if (value.isEmpty) continue;
      detailLines.add('${guidedFields[index].label}: $value');
    }
    final message = _messageController.text.trim();
    final enhancedMessage = detailLines.isEmpty
        ? message
        : '$message\n\nSupport details:\n${detailLines.map((item) => '- $item').join('\n')}';

    try {
      final created = await ProfileSettingsState.addCurrentHelpTicket(
        HelpSupportTicket(
          title: _titleController.text.trim(),
          message: enhancedMessage,
          category: _selectedCategoryId,
          subcategory: _selectedSubcategoryId,
          priority: supportTicketPriority(
            categoryId: _selectedCategoryId,
            subcategoryId: _selectedSubcategoryId,
          ),
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  List<_GuidedSupportField> _guidedFieldsForSelection() {
    switch (_selectedCategoryId) {
      case 'payment_charge':
        return const [
          _GuidedSupportField(
            label: 'Booking or payment ID',
            hint: 'Enter the booking ID or payment reference',
          ),
          _GuidedSupportField(
            label: 'Charged amount',
            hint: 'Enter the amount charged or expected',
            keyboardType: TextInputType.numberWithOptions(decimal: true),
          ),
        ];
      case 'provider_issue':
        return const [
          _GuidedSupportField(
            label: 'Booking ID',
            hint: 'Enter the related booking ID',
          ),
          _GuidedSupportField(
            label: 'Provider name',
            hint: 'Enter the provider name',
          ),
        ];
      case 'finder_issue':
        return const [
          _GuidedSupportField(
            label: 'Booking ID',
            hint: 'Enter the related booking ID',
          ),
          _GuidedSupportField(
            label: 'Finder name',
            hint: 'Enter the finder name',
          ),
        ];
      case 'booking_problem':
        return const [
          _GuidedSupportField(
            label: 'Booking ID',
            hint: 'Enter the booking ID if available',
          ),
          _GuidedSupportField(
            label: 'Screen or action',
            hint: 'Which screen or action caused the issue?',
          ),
        ];
      case 'subscription_upgrade':
        return const [
          _GuidedSupportField(
            label: 'Plan name',
            hint: 'Basic, Plus, or Pro',
          ),
          _GuidedSupportField(
            label: 'Payment reference or email',
            hint: 'Enter payment reference or account email',
          ),
        ];
      case 'account_verification':
        return const [
          _GuidedSupportField(
            label: 'Account email',
            hint: 'Enter the email used in this account',
          ),
          _GuidedSupportField(
            label: 'Current status or error',
            hint: 'What status or error is shown?',
          ),
        ];
      case 'app_bug':
        return const [
          _GuidedSupportField(
            label: 'Screen name',
            hint: 'Which screen has the issue?',
          ),
          _GuidedSupportField(
            label: 'Device or steps',
            hint: 'What device or steps reproduce the issue?',
          ),
        ];
      default:
        return const [
          _GuidedSupportField(
            label: 'Reference ID',
            hint: 'Booking, payment, or account reference if any',
          ),
        ];
    }
  }

  Widget _metaPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  String _prettyPriority(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return 'High priority';
      case 'low':
        return 'Low priority';
      default:
        return 'Normal priority';
    }
  }

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return const Color(0xFFDC2626);
      case 'low':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0EA5E9);
    }
  }
}

class _BackgroundGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _BackgroundGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}
