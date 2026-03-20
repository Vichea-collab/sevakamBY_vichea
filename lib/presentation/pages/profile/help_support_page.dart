import 'dart:async';

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/support_ticket_options.dart';
import '../../../core/utils/app_toast.dart';
import '../../../core/utils/page_transition.dart';
import '../../../domain/entities/pagination.dart';
import '../../../domain/entities/profile_settings.dart';
import 'help_support_chat_page.dart';
import '../../state/profile_settings_state.dart';
import '../../widgets/app_state_panel.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/app_top_bar.dart';
import '../../widgets/pagination_bar.dart';
import '../../widgets/primary_button.dart';

class HelpSupportPage extends StatefulWidget {
  static const String routeName = '/profile/help';

  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _detailOneController = TextEditingController();
  final TextEditingController _detailTwoController = TextEditingController();
  Timer? _pollTimer;
  int _activePage = 1;
  bool _sending = false;
  bool _paging = false;
  late String _selectedCategoryId;
  late String _selectedSubcategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = supportTicketCategories.first.id;
    _selectedSubcategoryId =
        supportTicketCategories.first.subcategories.first.id;
    _activePage = 1;
    unawaited(
      ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage),
    );
    _startPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
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

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            10,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTopBar(title: 'Help & support', actions: const []),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  height: 112,
                  width: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FF),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 62,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Hello, how can we assist you?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFD8E4F6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a support topic first',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This helps admin route your ticket faster and sends an instant support guide.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSelectField(
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
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD9E6FA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                category.icon,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  category.label,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              _priorityPill(subcategory.priority),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            category.description,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Auto reply preview',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subcategory.autoReply,
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
              ),
              const SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subject',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                    const SizedBox(height: 12),
                    for (
                      var index = 0;
                      index < guidedFields.length;
                      index++
                    ) ...[
                      Text(
                        guidedFields[index].label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 6),
                      AppTextField(
                        hint: guidedFields[index].hint,
                        controller: index == 0
                            ? _detailOneController
                            : _detailTwoController,
                        keyboardType: guidedFields[index].keyboardType,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      'Write in below box',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    AppTextField(
                      hint: 'Write here..',
                      controller: _messageController,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                      minLines: 4,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: _sending ? 'Sending...' : 'Send',
                onPressed: _sending ? null : _sendTicket,
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFD5DFF0)),
                ),
                child: const Text(
                  'Open any ticket below to chat directly with admin support.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<HelpSupportTicket>>(
                valueListenable: ProfileSettingsState.isProvider
                    ? ProfileSettingsState.providerHelpTickets
                    : ProfileSettingsState.finderHelpTickets,
                builder: (context, tickets, _) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: ProfileSettingsState.isProvider
                        ? ProfileSettingsState.providerHelpTicketsLoading
                        : ProfileSettingsState.finderHelpTicketsLoading,
                    builder: (context, loading, _) {
                      return ValueListenableBuilder<PaginationMeta>(
                        valueListenable: ProfileSettingsState.isProvider
                            ? ProfileSettingsState.providerHelpTicketsPagination
                            : ProfileSettingsState.finderHelpTicketsPagination,
                        builder: (context, pagination, _) {
                          final Widget ticketBody;
                          if (loading && tickets.isEmpty) {
                            ticketBody = const SizedBox(
                              height: 320,
                              child: Center(
                                child: AppStatePanel.loading(
                                  title: 'Loading support tickets',
                                ),
                              ),
                            );
                          } else if (tickets.isEmpty) {
                            ticketBody = const AppStatePanel.empty(
                              title: 'No support tickets yet',
                              message:
                                  'Your submitted support requests will appear here.',
                            );
                          } else {
                            ticketBody = Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.divider),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Support tickets (${pagination.totalItems})',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...tickets.map(_buildTicketCard),
                                  if (pagination.totalPages > 1)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: PaginationBar(
                                        currentPage: _normalizedPage(
                                          pagination.page,
                                        ),
                                        totalPages: pagination.totalPages,
                                        loading: _paging,
                                        onPageSelected: _goToPage,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: ticketBody,
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
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
    _activePage = 1;
    await ProfileSettingsState.refreshCurrentHelpTickets(page: _activePage);
    if (!mounted) return;
    setState(() => _sending = false);
    _titleController.clear();
    _messageController.clear();
    _detailOneController.clear();
    _detailTwoController.clear();
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
      'waiting_on_user' => AppColors.primary,
      _ => AppColors.warning,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _openChat(ticket),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FBFF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD7E1F2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _ticketMetaPill(
                    supportTicketCategoryLabel(ticket.category),
                    const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  _ticketMetaPill(
                    _prettyPriority(ticket.priority),
                    _priorityColor(ticket.priority),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _prettySupportStatus(normalized),
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ticket.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
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
              const SizedBox(height: 6),
              Text(
                ticket.lastMessageText.isEmpty
                    ? ticket.message
                    : ticket.lastMessageText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatDate(ticket.lastMessageAt ?? ticket.createdAt),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _openChat(ticket),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Open chat'),
                  ),
                ],
              ),
            ],
          ),
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
      if (!mounted || _sending || _paging) return;
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
            hint: 'Basic, Professional, or Elite',
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

  Widget _buildSelectField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey<String>('support_select_${label}_$value'),
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

  Widget _priorityPill(String priority) {
    return _ticketMetaPill(_prettyPriority(priority), _priorityColor(priority));
  }

  Widget _ticketMetaPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
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
