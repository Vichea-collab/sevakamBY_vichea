import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../app/admin_web_app.dart';
import '../../data/network/admin_api_client.dart';
import '../../domain/entities/admin_models.dart';
import '../state/admin_dashboard_state.dart';
part 'admin_dashboard_widgets.dart';

enum _AdminSection {
  overview,
  users,
  orders,
  posts,
  tickets,
  services,
  broadcasts,
}

extension _AdminSectionX on _AdminSection {
  String get label {
    switch (this) {
      case _AdminSection.overview:
        return 'Overview';
      case _AdminSection.users:
        return 'Users';
      case _AdminSection.orders:
        return 'Orders';
      case _AdminSection.posts:
        return 'Posts';
      case _AdminSection.tickets:
        return 'Tickets';
      case _AdminSection.services:
        return 'Services';
      case _AdminSection.broadcasts:
        return 'Broadcasts';
    }
  }

  String get subtitle {
    switch (this) {
      case _AdminSection.overview:
        return 'Platform performance and recent activity';
      case _AdminSection.users:
        return 'User identities and role distribution';
      case _AdminSection.orders:
        return 'Bookings, payment status, and revenue';
      case _AdminSection.posts:
        return 'Finder requests and provider offers';
      case _AdminSection.tickets:
        return 'Support workload and open incidents';
      case _AdminSection.services:
        return 'Service catalog and category coverage';
      case _AdminSection.broadcasts:
        return 'System announcements and promo-code campaigns';
    }
  }

  IconData get icon {
    switch (this) {
      case _AdminSection.overview:
        return Icons.dashboard_rounded;
      case _AdminSection.users:
        return Icons.group_rounded;
      case _AdminSection.orders:
        return Icons.receipt_long_rounded;
      case _AdminSection.posts:
        return Icons.campaign_rounded;
      case _AdminSection.tickets:
        return Icons.support_agent_rounded;
      case _AdminSection.services:
        return Icons.handyman_rounded;
      case _AdminSection.broadcasts:
        return Icons.campaign_rounded;
    }
  }
}

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _bootstrapping = true;
  _AdminSection _section = _AdminSection.overview;
  late final TextEditingController _searchController;

  String _searchQuery = '';
  String _userRoleFilter = 'all';
  String _orderStatusFilter = 'all';
  String _postTypeFilter = 'all';
  String _ticketStatusFilter = 'all';
  String _serviceStateFilter = 'all';
  String _broadcastTypeFilter = 'all';
  String _broadcastStatusFilter = 'all';
  String _broadcastRoleFilter = 'all';
  String _undoHistoryStateFilter = 'all';
  String _broadcastComposerType = 'system';
  String _broadcastComposerDiscountType = 'percent';
  bool _broadcastComposerFinder = true;
  bool _broadcastComposerProvider = true;
  bool _broadcastComposerActive = true;
  bool _broadcastComposerSaving = false;
  int _undoHistoryPage = 1;
  late final TextEditingController _broadcastTitleController;
  late final TextEditingController _broadcastMessageController;
  late final TextEditingController _broadcastPromoCodeController;
  late final TextEditingController _broadcastDiscountValueController;
  late final TextEditingController _broadcastMinSubtotalController;
  late final TextEditingController _broadcastMaxDiscountController;
  late final TextEditingController _broadcastUsageLimitController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _broadcastTitleController = TextEditingController();
    _broadcastMessageController = TextEditingController();
    _broadcastPromoCodeController = TextEditingController();
    _broadcastDiscountValueController = TextEditingController(text: '10');
    _broadcastMinSubtotalController = TextEditingController(text: '0');
    _broadcastMaxDiscountController = TextEditingController(text: '0');
    _broadcastUsageLimitController = TextEditingController(text: '0');
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
      AdminDashboardState.globalSearch.value =
          const AdminGlobalSearchResult.empty();
    });
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _broadcastTitleController.dispose();
    _broadcastMessageController.dispose();
    _broadcastPromoCodeController.dispose();
    _broadcastDiscountValueController.dispose();
    _broadcastMinSubtotalController.dispose();
    _broadcastMaxDiscountController.dispose();
    _broadcastUsageLimitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'admin@gmail.com';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF1F6FF), Color(0xFFE5EEFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -130,
              right: -80,
              child: _GlowBubble(
                diameter: 300,
                color: AppColors.primary.withValues(alpha: 0.10),
              ),
            ),
            Positioned(
              bottom: -170,
              left: -120,
              child: _GlowBubble(
                diameter: 360,
                color: const Color(0xFF14B8A6).withValues(alpha: 0.08),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (_bootstrapping) {
                    return const _BootstrappingView();
                  }
                  final desktop = constraints.maxWidth >= 1080;
                  if (desktop) {
                    return Row(
                      children: [
                        SizedBox(
                          width: 274,
                          child: _DashboardSidebar(
                            email: email,
                            section: _section,
                            onSectionChanged: _onSectionChanged,
                            onLogout: _logout,
                          ),
                        ),
                        Expanded(child: _buildMainContent(desktop: true)),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _MobileTopBar(email: email, onLogout: _logout),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                          scrollDirection: Axis.horizontal,
                          itemCount: _AdminSection.values.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final item = _AdminSection.values[index];
                            final selected = item == _section;
                            return ChoiceChip(
                              selected: selected,
                              label: Text(item.label),
                              avatar: Icon(item.icon, size: 20),
                              onSelected: (_) => _onSectionChanged(item),
                              selectedColor: AppColors.primary.withValues(
                                alpha: 0.16,
                              ),
                              side: BorderSide(
                                color: selected
                                    ? AppColors.primary
                                    : const Color(0xFFD7E1F3),
                              ),
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(child: _buildMainContent(desktop: false)),
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

  Future<void> _bootstrap() async {
    try {
      await _runAuthed(() async {
        final allowed = await AdminDashboardState.verifyAccess();
        if (!allowed) {
          throw const AdminApiException(
            'This account is not authorized as admin.',
            statusCode: 403,
          );
        }
        await _refreshAllData();
      });
    } catch (error) {
      if (error is AdminApiException && error.statusCode == 403) {
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, AdminWebApp.loginRoute);
        return;
      }
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _bootstrapping = false);
      }
    }
  }

  Future<T> _runAuthed<T>(Future<T> Function() action) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AdminWebApp.loginRoute);
      }
      throw const AdminApiException('Authentication required', statusCode: 401);
    }

    await _setBearerToken(user, forceRefresh: false);
    try {
      return await action();
    } on AdminApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _setBearerToken(user, forceRefresh: true);
      return action();
    }
  }

  Future<void> _setBearerToken(User user, {required bool forceRefresh}) async {
    final token = (await user.getIdToken(forceRefresh) ?? '').trim();
    if (token.isEmpty) {
      throw const AdminApiException(
        'Authentication token missing',
        statusCode: 401,
      );
    }
    AdminDashboardState.setBackendToken(token);
  }

  Future<void> _refreshAllData() async {
    final tasks = <Future<void>>[];
    if (_section == _AdminSection.overview) {
      tasks.add(AdminDashboardState.refreshOverview());
    }
    await Future.wait<void>(tasks);
    if (_section == _AdminSection.overview) {
      _undoHistoryPage = 1;
      await _reloadCurrentSection(page: _undoHistoryPage);
      return;
    }
    await _reloadCurrentSection(page: 1);
  }

  Future<void> _refreshAll() async {
    try {
      await _runAuthed(_refreshAllData);
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadUsers(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshUsers(
          page: page,
          query: _searchQuery,
          role: _userRoleFilter == 'all' ? '' : _userRoleFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadOrders(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshOrders(
          page: page,
          query: _searchQuery,
          status: _orderStatusFilter == 'all' ? '' : _orderStatusFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadPosts(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshPosts(
          page: page,
          query: _searchQuery,
          type: _postTypeFilter == 'all' ? '' : _postTypeFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadTickets(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshTickets(
          page: page,
          query: _searchQuery,
          status: _ticketStatusFilter == 'all' ? '' : _ticketStatusFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadServices(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshServices(
          page: page,
          query: _searchQuery,
          active: _serviceStateFilter == 'all'
              ? ''
              : (_serviceStateFilter == 'active' ? 'true' : 'false'),
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadBroadcasts(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshBroadcasts(
          page: page,
          query: _searchQuery,
          type: _broadcastTypeFilter == 'all' ? '' : _broadcastTypeFilter,
          status: _broadcastStatusFilter == 'all' ? '' : _broadcastStatusFilter,
          role: _broadcastRoleFilter == 'all' ? '' : _broadcastRoleFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _loadUndoHistory(int page) async {
    _undoHistoryPage = page < 1 ? 1 : page;
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshUndoHistory(
          page: _undoHistoryPage,
          query: _searchQuery,
          state: _undoHistoryStateFilter == 'all'
              ? ''
              : _undoHistoryStateFilter,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _reloadCurrentSection({int page = 1}) async {
    switch (_section) {
      case _AdminSection.overview:
        return _loadUndoHistory(page);
      case _AdminSection.users:
        return _loadUsers(page);
      case _AdminSection.orders:
        return _loadOrders(page);
      case _AdminSection.posts:
        return _loadPosts(page);
      case _AdminSection.tickets:
        return _loadTickets(page);
      case _AdminSection.services:
        return _loadServices(page);
      case _AdminSection.broadcasts:
        return _loadBroadcasts(page);
    }
  }

  Future<void> _submitSearch() async {
    final query = _searchController.text.trim();
    if (mounted) {
      setState(() => _searchQuery = query);
    }
    try {
      await _runAuthed(() async {
        if (query.length >= 3) {
          await AdminDashboardState.runGlobalSearch(query: query, limit: 4);
        } else {
          AdminDashboardState.globalSearch.value =
              const AdminGlobalSearchResult.empty();
        }
        await _reloadCurrentSection(page: 1);
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    if (mounted) {
      setState(() => _searchQuery = '');
    }
    AdminDashboardState.globalSearch.value =
        const AdminGlobalSearchResult.empty();
    try {
      await _runAuthed(() => _reloadCurrentSection(page: 1));
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    AdminDashboardState.setBackendToken('');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AdminWebApp.loginRoute);
  }

  void _onSectionChanged(_AdminSection section) {
    if (_section == section) return;
    _searchController.clear();
    AdminDashboardState.globalSearch.value =
        const AdminGlobalSearchResult.empty();
    setState(() {
      _section = section;
    });
    if (section == _AdminSection.overview) {
      unawaited(_refreshAllData());
      return;
    }
    unawaited(_reloadCurrentSection(page: 1));
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = switch (error) {
      AdminApiException() => error.message,
      _ => error.toString(),
    };
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  _AdminSection? _sectionFromKey(String value) {
    switch (value.trim().toLowerCase()) {
      case 'users':
        return _AdminSection.users;
      case 'orders':
        return _AdminSection.orders;
      case 'posts':
        return _AdminSection.posts;
      case 'tickets':
        return _AdminSection.tickets;
      case 'services':
        return _AdminSection.services;
      case 'broadcasts':
        return _AdminSection.broadcasts;
      case 'overview':
        return _AdminSection.overview;
      default:
        return null;
    }
  }

  Future<void> _jumpToSearchResult(AdminSearchItem item) async {
    final target = _sectionFromKey(item.section);
    if (target == null) return;
    if (_section != target) {
      setState(() => _section = target);
    }
    _searchController.text = item.title;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    if (target == _AdminSection.overview) {
      await _refreshAllData();
      return;
    }
    await _reloadCurrentSection(page: 1);
  }

  Future<String?> _askActionReason({
    required String title,
    required String actionLabel,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (context) =>
          _ActionReasonDialog(title: title, actionLabel: actionLabel),
    );
  }

  Future<void> _runSafeAction({
    required String dialogTitle,
    required String actionLabel,
    required Future<AdminActionResult> Function(String reason) run,
  }) async {
    final reason = await _askActionReason(
      title: dialogTitle,
      actionLabel: actionLabel,
    );
    if (reason == null || reason.trim().length < 3) return;
    try {
      final result = await _runAuthed(() async {
        final response = await run(reason.trim());
        await AdminDashboardState.refreshUndoHistory(
          page: 1,
          query: _searchQuery,
          state: _undoHistoryStateFilter == 'all'
              ? ''
              : _undoHistoryStateFilter,
        );
        _undoHistoryPage = 1;
        await _reloadCurrentSection(page: 1);
        return response;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action completed. Reason: ${result.reason}'),
          behavior: SnackBarBehavior.floating,
          action: result.undoToken.isEmpty
              ? null
              : SnackBarAction(
                  label: 'Undo',
                  onPressed: () async {
                    try {
                      await _runAuthed(() async {
                        await AdminDashboardState.undoAction(
                          undoToken: result.undoToken,
                        );
                        await AdminDashboardState.refreshUndoHistory(
                          page: _undoHistoryPage,
                          query: _searchQuery,
                          state: _undoHistoryStateFilter == 'all'
                              ? ''
                              : _undoHistoryStateFilter,
                        );
                      });
                      await _reloadCurrentSection(page: 1);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Action reverted.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } catch (error) {
                      _showError(error);
                    }
                  },
                ),
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _undoFromHistory(AdminUndoHistoryRow row) async {
    if (!row.canUndo) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Undo this action?'),
          content: Text(
            'This will restore ${row.targetLabel.isEmpty ? row.docPath : row.targetLabel} to its previous state.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Undo now'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    try {
      await _runAuthed(() async {
        await AdminDashboardState.undoAction(undoToken: row.undoToken);
        await AdminDashboardState.refreshUndoHistory(
          page: _undoHistoryPage,
          query: _searchQuery,
          state: _undoHistoryStateFilter == 'all'
              ? ''
              : _undoHistoryStateFilter,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action reverted from history.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _openTicketChat(AdminTicketRow ticket) async {
    final uid = ticket.userUid.trim();
    final ticketId = ticket.id.trim();
    if (uid.isEmpty || ticketId.isEmpty) {
      _showError(const AdminApiException('Invalid ticket target'));
      return;
    }

    final inputController = TextEditingController();
    var currentPage = 1;
    var paging = false;
    var sending = false;
    await _runAuthed(
      () => AdminDashboardState.refreshTicketMessages(
        userUid: uid,
        ticketId: ticketId,
        page: 1,
      ),
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 760,
                  maxHeight: 680,
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ticket.title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                (ticket.userEmail.isEmpty
                                        ? ticket.userName
                                        : '${ticket.userName} • ${ticket.userEmail}')
                                    .trim(),
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          text: _prettyStatus(ticket.status),
                          color: _statusColor(ticket.status),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE6F7)),
                        ),
                        child: ValueListenableBuilder<List<AdminTicketMessageRow>>(
                          valueListenable: AdminDashboardState.ticketMessages,
                          builder: (context, messages, _) {
                            return ValueListenableBuilder<AdminPagination>(
                              valueListenable:
                                  AdminDashboardState.ticketMessagesPagination,
                              builder: (context, pagination, _) {
                                return Column(
                                  children: [
                                    if (AdminDashboardState
                                        .loadingTicketMessages
                                        .value)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                      ),
                                    Expanded(
                                      child: messages.isEmpty
                                          ? const Center(
                                              child: Text(
                                                'No messages yet in this ticket.',
                                              ),
                                            )
                                          : ListView.separated(
                                              itemCount: messages.length,
                                              separatorBuilder: (_, _) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (context, index) {
                                                final message = messages[index];
                                                final fromAdmin =
                                                    message.senderRole
                                                        .toLowerCase() ==
                                                    'admin';
                                                return Align(
                                                  alignment: fromAdmin
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Container(
                                                    constraints:
                                                        const BoxConstraints(
                                                          maxWidth: 430,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.fromLTRB(
                                                          10,
                                                          8,
                                                          10,
                                                          8,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: fromAdmin
                                                          ? AppColors.primary
                                                                .withValues(
                                                                  alpha: 0.14,
                                                                )
                                                          : Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: fromAdmin
                                                            ? AppColors.primary
                                                                  .withValues(
                                                                    alpha: 0.28,
                                                                  )
                                                            : const Color(
                                                                0xFFD6DEED,
                                                              ),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          message.senderName,
                                                          style: TextStyle(
                                                            color: fromAdmin
                                                                ? AppColors
                                                                      .primaryDark
                                                                : AppColors
                                                                      .textSecondary,
                                                            fontSize: 12,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          message.text,
                                                          style: const TextStyle(
                                                            color: AppColors
                                                                .textPrimary,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          _formatDateTime(
                                                            message.createdAt,
                                                          ),
                                                          style: const TextStyle(
                                                            color: AppColors
                                                                .textSecondary,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                    if (pagination.totalPages > 1) ...[
                                      const SizedBox(height: 8),
                                      _CompactPager(
                                        page: pagination.page,
                                        totalPages: pagination.totalPages,
                                        loading: paging,
                                        onPageSelected: (page) async {
                                          if (paging) return;
                                          setDialogState(() {
                                            paging = true;
                                          });
                                          currentPage = page;
                                          try {
                                            await _runAuthed(
                                              () =>
                                                  AdminDashboardState.refreshTicketMessages(
                                                    userUid: uid,
                                                    ticketId: ticketId,
                                                    page: currentPage,
                                                  ),
                                            );
                                          } catch (error) {
                                            _showError(error);
                                          } finally {
                                            if (context.mounted) {
                                              setDialogState(() {
                                                paging = false;
                                              });
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: inputController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: _adminFieldDecoration(
                        hintText: 'Reply to this ticket...',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: sending
                                ? null
                                : () async {
                                    final text = inputController.text.trim();
                                    if (text.isEmpty) return;
                                    setDialogState(() => sending = true);
                                    try {
                                      await _runAuthed(() async {
                                        await AdminDashboardState.sendTicketMessage(
                                          userUid: uid,
                                          ticketId: ticketId,
                                          text: text,
                                        );
                                        await AdminDashboardState.refreshTicketMessages(
                                          userUid: uid,
                                          ticketId: ticketId,
                                          page: 1,
                                        );
                                        await _loadTickets(1);
                                      });
                                      inputController.clear();
                                      currentPage = 1;
                                    } catch (error) {
                                      _showError(error);
                                    } finally {
                                      if (context.mounted) {
                                        setDialogState(() => sending = false);
                                      }
                                    }
                                  },
                            icon: const Icon(Icons.send_rounded),
                            label: Text(sending ? 'Sending...' : 'Send'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent({required bool desktop}) {
    final activeFilters = _activeFilterLabels();
    return Column(
      children: [
        _DashboardToolbar(
          section: _section,
          searchController: _searchController,
          onRefresh: _refreshAll,
          onSubmitSearch: _submitSearch,
          onClearSearch: _clearSearch,
          activeFilters: activeFilters,
          onClearFilters: activeFilters.isEmpty ? null : _clearActiveFilters,
        ),
        ValueListenableBuilder<AdminGlobalSearchResult>(
          valueListenable: AdminDashboardState.globalSearch,
          builder: (context, result, _) {
            if (_searchQuery.trim().length < 3 || result.groups.isEmpty) {
              return const SizedBox.shrink();
            }
            return _GlobalSearchPanel(
              result: result,
              onTap: (item) => unawaited(_jumpToSearchResult(item)),
            );
          },
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                desktop ? 22 : 14,
                4,
                desktop ? 22 : 14,
                22,
              ),
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final slide = Tween<Offset>(
                      begin: const Offset(0, 0.02),
                      end: Offset.zero,
                    ).animate(animation);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(position: slide, child: child),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<String>(
                      '${_section.name}_${_searchQuery.trim()}-$_userRoleFilter-$_orderStatusFilter-$_postTypeFilter-$_ticketStatusFilter-$_serviceStateFilter-$_broadcastTypeFilter-$_broadcastStatusFilter-$_broadcastRoleFilter-$_undoHistoryStateFilter',
                    ),
                    child: _buildActiveSection(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<String> _activeFilterLabels() {
    final values = <String>[];
    final search = _searchQuery.trim();
    if (search.isNotEmpty) values.add('Search: "$search"');
    switch (_section) {
      case _AdminSection.overview:
        if (_undoHistoryStateFilter != 'all') {
          values.add('History: ${_prettyStatus(_undoHistoryStateFilter)}');
        }
        break;
      case _AdminSection.users:
        if (_userRoleFilter != 'all') {
          values.add('Role: ${_prettyRole(_userRoleFilter)}');
        }
        break;
      case _AdminSection.orders:
        if (_orderStatusFilter != 'all') {
          values.add('Status: ${_prettyStatus(_orderStatusFilter)}');
        }
        break;
      case _AdminSection.posts:
        if (_postTypeFilter != 'all') {
          values.add('Type: ${_prettyPostType(_postTypeFilter)}');
        }
        break;
      case _AdminSection.tickets:
        if (_ticketStatusFilter != 'all') {
          values.add('Status: ${_prettyStatus(_ticketStatusFilter)}');
        }
        break;
      case _AdminSection.services:
        if (_serviceStateFilter != 'all') {
          values.add(
            'State: ${_serviceStateFilter == 'active' ? 'Active' : 'Inactive'}',
          );
        }
        break;
      case _AdminSection.broadcasts:
        if (_broadcastTypeFilter != 'all') {
          values.add('Type: ${_prettyBroadcastType(_broadcastTypeFilter)}');
        }
        if (_broadcastStatusFilter != 'all') {
          values.add('Status: ${_prettyStatus(_broadcastStatusFilter)}');
        }
        if (_broadcastRoleFilter != 'all') {
          values.add('Audience: ${_prettyRole(_broadcastRoleFilter)}');
        }
        break;
    }
    return values;
  }

  void _clearActiveFilters() {
    _searchController.clear();
    AdminDashboardState.globalSearch.value =
        const AdminGlobalSearchResult.empty();
    setState(() {
      _searchQuery = '';
      _userRoleFilter = 'all';
      _orderStatusFilter = 'all';
      _postTypeFilter = 'all';
      _ticketStatusFilter = 'all';
      _serviceStateFilter = 'all';
      _broadcastTypeFilter = 'all';
      _broadcastStatusFilter = 'all';
      _broadcastRoleFilter = 'all';
      _undoHistoryStateFilter = 'all';
    });
    unawaited(_reloadCurrentSection(page: 1));
  }

  Widget _buildActiveSection() {
    switch (_section) {
      case _AdminSection.overview:
        return _buildOverviewSection();
      case _AdminSection.users:
        return _buildUsersSection();
      case _AdminSection.orders:
        return _buildOrdersSection();
      case _AdminSection.posts:
        return _buildPostsSection();
      case _AdminSection.tickets:
        return _buildTicketsSection();
      case _AdminSection.services:
        return _buildServicesSection();
      case _AdminSection.broadcasts:
        return _buildBroadcastsSection();
    }
  }

  Widget _buildOverviewSection() {
    final query = _searchQuery.trim().toLowerCase();
    return ValueListenableBuilder<bool>(
      valueListenable: AdminDashboardState.loadingOverview,
      builder: (context, loading, _) {
        return ValueListenableBuilder<AdminOverview>(
          valueListenable: AdminDashboardState.overview,
          builder: (context, row, _) {
            final kpis = row.kpis;
            final orderStatus = row.orderStatus;

            final recentOrders = row.recentOrders
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.serviceName} ${item.finderName} ${item.providerName} ${item.status}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);

            final recentUsers = row.recentUsers
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack = '${item.name} ${item.email} ${item.role}'
                      .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);

            final recentPosts = row.recentPosts
                .where((item) {
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.ownerName} ${item.type} ${item.category} ${item.service} ${item.status}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                _OverviewKpiGrid(kpis: kpis),
                const SizedBox(height: 14),
                _StatusBoard(status: orderStatus),
                const SizedBox(height: 14),
                ValueListenableBuilder<bool>(
                  valueListenable: AdminDashboardState.loadingUndoHistory,
                  builder: (context, historyLoading, _) {
                    return ValueListenableBuilder<List<AdminUndoHistoryRow>>(
                      valueListenable: AdminDashboardState.undoHistory,
                      builder: (context, historyItems, _) {
                        return ValueListenableBuilder<AdminPagination>(
                          valueListenable:
                              AdminDashboardState.undoHistoryPagination,
                          builder: (context, historyPagination, _) {
                            return _UndoHistoryCard(
                              loading: historyLoading,
                              items: historyItems,
                              pagination: historyPagination,
                              selectedState: _undoHistoryStateFilter,
                              onStateChanged: (value) {
                                setState(() => _undoHistoryStateFilter = value);
                                unawaited(_loadUndoHistory(1));
                              },
                              onPageSelected: _loadUndoHistory,
                              onUndo: _undoFromHistory,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 980;
                    if (!wide) {
                      return Column(
                        children: [
                          _ActivityCard(
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2563EB),
                            title: 'Recent Orders',
                            items: recentOrders
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.serviceName} • ${item.finderName} → ${item.providerName}',
                                    subtitle:
                                        '${_prettyStatus(item.status)} • ${_toMoney(item.total)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent orders for current filters.',
                          ),
                          const SizedBox(height: 12),
                          _ActivityCard(
                            icon: Icons.group_rounded,
                            color: const Color(0xFF14B8A6),
                            title: 'Recent Users',
                            items: recentUsers
                                .map(
                                  (item) => _ActivityItem(
                                    title: '${item.name} (${item.role})',
                                    subtitle: item.email.isEmpty
                                        ? 'No email'
                                        : item.email,
                                    trailing: _formatDateTime(
                                      item.updatedAt ?? item.createdAt,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent users for current filters.',
                          ),
                          const SizedBox(height: 12),
                          _ActivityCard(
                            icon: Icons.campaign_rounded,
                            color: const Color(0xFF7C3AED),
                            title: 'Recent Posts',
                            items: recentPosts
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.ownerName} • ${_prettyPostType(item.type)}',
                                    subtitle:
                                        '${item.service.isEmpty ? 'Service' : item.service} • ${_prettyStatus(item.status)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent posts for current filters.',
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.receipt_long_rounded,
                            color: const Color(0xFF2563EB),
                            title: 'Recent Orders',
                            items: recentOrders
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.serviceName} • ${item.finderName} → ${item.providerName}',
                                    subtitle:
                                        '${_prettyStatus(item.status)} • ${_toMoney(item.total)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent orders for current filters.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.group_rounded,
                            color: const Color(0xFF14B8A6),
                            title: 'Recent Users',
                            items: recentUsers
                                .map(
                                  (item) => _ActivityItem(
                                    title: '${item.name} (${item.role})',
                                    subtitle: item.email.isEmpty
                                        ? 'No email'
                                        : item.email,
                                    trailing: _formatDateTime(
                                      item.updatedAt ?? item.createdAt,
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent users for current filters.',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActivityCard(
                            icon: Icons.campaign_rounded,
                            color: const Color(0xFF7C3AED),
                            title: 'Recent Posts',
                            items: recentPosts
                                .map(
                                  (item) => _ActivityItem(
                                    title:
                                        '${item.ownerName} • ${_prettyPostType(item.type)}',
                                    subtitle:
                                        '${item.service.isEmpty ? 'Service' : item.service} • ${_prettyStatus(item.status)}',
                                    trailing: _formatDateTime(item.createdAt),
                                  ),
                                )
                                .toList(growable: false),
                            emptyText: 'No recent posts for current filters.',
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                Text(
                  row.generatedAt == null
                      ? 'Overview timestamp unavailable'
                      : 'Last synced: ${_formatDateTime(row.generatedAt)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUsersSection() {
    return _AdminTableCard<AdminUserRow>(
      title: 'User Management',
      subtitle: 'Audit account identities and role assignments.',
      loadingListenable: AdminDashboardState.loadingUsers,
      rowsListenable: AdminDashboardState.users,
      paginationListenable: AdminDashboardState.usersPagination,
      onPageSelected: _loadUsers,
      controls: [
        _DropdownFilter(
          label: 'Role',
          value: _userRoleFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All roles'),
            _DropdownOption(value: 'admin', label: 'Admin'),
            _DropdownOption(value: 'provider', label: 'Provider'),
            _DropdownOption(value: 'finder', label: 'Finder'),
            _DropdownOption(value: 'user', label: 'User'),
          ],
          onChanged: (value) {
            setState(() => _userRoleFilter = value);
            unawaited(_loadUsers(1));
          },
        ),
      ],
      columns: const ['Name', 'Email', 'Role', 'State', 'Updated', 'Action'],
      emptyText: 'No users found for this page.',
      summaryBuilder: (items) {
        final admins = items
            .where((item) => item.role.contains('admin'))
            .length;
        final providers = items
            .where((item) => item.role.contains('provider'))
            .length;
        final finders = items
            .where((item) => item.role.contains('finder'))
            .length;
        return [
          _MetricChipData(label: 'Page users', value: '${items.length}'),
          _MetricChipData(
            label: 'Admin',
            value: '$admins',
            color: const Color(0xFF7C3AED),
          ),
          _MetricChipData(
            label: 'Provider',
            value: '$providers',
            color: AppColors.primary,
          ),
          _MetricChipData(
            label: 'Finder',
            value: '$finders',
            color: const Color(0xFF14B8A6),
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final roleMatch =
                  _userRoleFilter == 'all' ||
                  item.role.toLowerCase().contains(_userRoleFilter);
              if (!roleMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.email} ${item.role} ${item.id}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.name, width: 170)),
          DataCell(
            _cellText(item.email.isEmpty ? '-' : item.email, width: 210),
          ),
          DataCell(_Pill(text: item.role, color: AppColors.primary)),
          DataCell(
            _Pill(
              text: item.active ? 'Active' : 'Suspended',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
          DataCell(
            _cellText(_formatDateTime(item.updatedAt ?? item.createdAt)),
          ),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: item.active ? 'Suspend' : 'Activate',
                  onTap: () => _runSafeAction(
                    dialogTitle:
                        '${item.active ? 'Suspend' : 'Activate'} user ${item.name}?',
                    actionLabel: item.active ? 'Suspend' : 'Activate',
                    run: (reason) => AdminDashboardState.updateUserStatus(
                      userId: item.id,
                      active: !item.active,
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildOrdersSection() {
    return _AdminTableCard<AdminOrderRow>(
      title: 'Order Operations',
      subtitle: 'Track booking lifecycle and payment state.',
      loadingListenable: AdminDashboardState.loadingOrders,
      rowsListenable: AdminDashboardState.orders,
      paginationListenable: AdminDashboardState.ordersPagination,
      onPageSelected: _loadOrders,
      controls: [
        _DropdownFilter(
          label: 'Status',
          value: _orderStatusFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All statuses'),
            _DropdownOption(value: 'booked', label: 'Booked'),
            _DropdownOption(value: 'on_the_way', label: 'On the way'),
            _DropdownOption(value: 'started', label: 'Started'),
            _DropdownOption(value: 'completed', label: 'Completed'),
            _DropdownOption(value: 'cancelled', label: 'Cancelled'),
            _DropdownOption(value: 'declined', label: 'Declined'),
          ],
          onChanged: (value) {
            setState(() => _orderStatusFilter = value);
            unawaited(_loadOrders(1));
          },
        ),
      ],
      columns: const [
        'Service',
        'Finder',
        'Provider',
        'Status',
        'Payment',
        'Total',
        'Created',
        'Action',
      ],
      emptyText: 'No orders found for this page.',
      summaryBuilder: (items) {
        final total = items.fold<double>(0, (sum, item) => sum + item.total);
        final completed = items
            .where((item) => item.status == 'completed')
            .length;
        final pending = items.where((item) => item.status == 'booked').length;
        return [
          _MetricChipData(label: 'Page orders', value: '${items.length}'),
          _MetricChipData(
            label: 'Page revenue',
            value: _toMoney(total),
            color: const Color(0xFF0284C7),
          ),
          _MetricChipData(
            label: 'Completed',
            value: '$completed',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Booked',
            value: '$pending',
            color: AppColors.warning,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final statusMatch =
                  _orderStatusFilter == 'all' ||
                  item.status.toLowerCase() == _orderStatusFilter;
              if (!statusMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.serviceName} ${item.finderName} ${item.providerName} ${item.status} ${item.paymentStatus}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.serviceName, width: 170)),
          DataCell(_cellText(item.finderName, width: 150)),
          DataCell(_cellText(item.providerName, width: 150)),
          DataCell(
            _Pill(
              text: _prettyStatus(item.status),
              color: _statusColor(item.status),
            ),
          ),
          DataCell(
            _cellText(
              '${item.paymentMethod.isEmpty ? '-' : item.paymentMethod} • ${item.paymentStatus.isEmpty ? '-' : item.paymentStatus}',
              width: 170,
            ),
          ),
          DataCell(_cellText(_toMoney(item.total))),
          DataCell(_cellText(_formatDateTime(item.createdAt))),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: 'Mark completed',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Mark order ${item.id} as completed?',
                    actionLabel: 'Complete',
                    run: (reason) => AdminDashboardState.updateOrderStatus(
                      orderId: item.id,
                      status: 'completed',
                      reason: reason,
                    ),
                  ),
                ),
                _ActionMenuItem(
                  label: 'Mark cancelled',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Mark order ${item.id} as cancelled?',
                    actionLabel: 'Cancel',
                    run: (reason) => AdminDashboardState.updateOrderStatus(
                      orderId: item.id,
                      status: 'cancelled',
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildPostsSection() {
    return _AdminTableCard<AdminPostRow>(
      title: 'Post Streams',
      subtitle: 'Moderate finder requests and provider offers in one place.',
      loadingListenable: AdminDashboardState.loadingPosts,
      rowsListenable: AdminDashboardState.posts,
      paginationListenable: AdminDashboardState.postsPagination,
      onPageSelected: _loadPosts,
      controls: [
        _DropdownFilter(
          label: 'Post type',
          value: _postTypeFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All types'),
            _DropdownOption(value: 'provider_offer', label: 'Provider offer'),
            _DropdownOption(value: 'finder_request', label: 'Finder request'),
          ],
          onChanged: (value) {
            setState(() => _postTypeFilter = value);
            unawaited(_loadPosts(1));
          },
        ),
      ],
      columns: const [
        'Type',
        'Owner',
        'Category/Service',
        'Location',
        'Status',
        'Created',
        'Action',
      ],
      emptyText: 'No posts found for this page.',
      summaryBuilder: (items) {
        final offers = items
            .where((item) => item.type == 'provider_offer')
            .length;
        final requests = items
            .where((item) => item.type == 'finder_request')
            .length;
        final open = items
            .where((item) => item.status.toLowerCase() == 'open')
            .length;
        return [
          _MetricChipData(label: 'Page posts', value: '${items.length}'),
          _MetricChipData(
            label: 'Offers',
            value: '$offers',
            color: AppColors.primary,
          ),
          _MetricChipData(
            label: 'Requests',
            value: '$requests',
            color: const Color(0xFF14B8A6),
          ),
          _MetricChipData(
            label: 'Open',
            value: '$open',
            color: AppColors.success,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final typeMatch =
                  _postTypeFilter == 'all' || item.type == _postTypeFilter;
              if (!typeMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.type} ${item.ownerName} ${item.category} ${item.service} ${item.location} ${item.status}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(
            _Pill(
              text: _prettyPostType(item.type),
              color: _postTypeColor(item.type),
            ),
          ),
          DataCell(_cellText(item.ownerName, width: 155)),
          DataCell(
            _cellText(
              '${item.category.isEmpty ? 'General' : item.category} / ${item.service.isEmpty ? 'Service' : item.service}',
              width: 210,
            ),
          ),
          DataCell(
            _cellText(item.location.isEmpty ? '-' : item.location, width: 170),
          ),
          DataCell(
            _Pill(
              text: _prettyStatus(item.status),
              color: _statusColor(item.status),
            ),
          ),
          DataCell(_cellText(_formatDateTime(item.createdAt))),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: 'Open',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Open this post again?',
                    actionLabel: 'Open',
                    run: (reason) => AdminDashboardState.updatePostStatus(
                      sourceCollection: item.sourceCollection,
                      postId: item.id,
                      status: 'open',
                      reason: reason,
                    ),
                  ),
                ),
                _ActionMenuItem(
                  label: 'Close',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Close this post?',
                    actionLabel: 'Close',
                    run: (reason) => AdminDashboardState.updatePostStatus(
                      sourceCollection: item.sourceCollection,
                      postId: item.id,
                      status: 'closed',
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildTicketsSection() {
    return _AdminTableCard<AdminTicketRow>(
      title: 'Help Tickets',
      subtitle: 'Monitor support backlog and resolution trends.',
      loadingListenable: AdminDashboardState.loadingTickets,
      rowsListenable: AdminDashboardState.tickets,
      paginationListenable: AdminDashboardState.ticketsPagination,
      onPageSelected: _loadTickets,
      controls: [
        _DropdownFilter(
          label: 'Ticket status',
          value: _ticketStatusFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All statuses'),
            _DropdownOption(value: 'open', label: 'Open'),
            _DropdownOption(value: 'resolved', label: 'Resolved'),
            _DropdownOption(value: 'closed', label: 'Closed'),
          ],
          onChanged: (value) {
            setState(() => _ticketStatusFilter = value);
            unawaited(_loadTickets(1));
          },
        ),
      ],
      columns: const [
        'Title',
        'Message',
        'Requester',
        'Status',
        'Created',
        'Action',
      ],
      emptyText: 'No tickets found for this page.',
      summaryBuilder: (items) {
        final open = items
            .where((item) => item.status.toLowerCase() == 'open')
            .length;
        final resolved = items
            .where((item) => item.status.toLowerCase() == 'resolved')
            .length;
        final closed = items
            .where((item) => item.status.toLowerCase() == 'closed')
            .length;
        return [
          _MetricChipData(label: 'Page tickets', value: '${items.length}'),
          _MetricChipData(
            label: 'Open',
            value: '$open',
            color: AppColors.warning,
          ),
          _MetricChipData(
            label: 'Resolved',
            value: '$resolved',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Closed',
            value: '$closed',
            color: const Color(0xFF64748B),
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final status = item.status.toLowerCase();
              final statusMatch =
                  _ticketStatusFilter == 'all' || status == _ticketStatusFilter;
              if (!statusMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.title} ${item.message} ${item.userUid} ${item.userName} ${item.userEmail} ${item.status}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.title, width: 170)),
          DataCell(
            _cellText(item.message.isEmpty ? '-' : item.message, width: 230),
          ),
          DataCell(
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.userEmail.isEmpty ? item.userUid : item.userEmail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          DataCell(
            _Pill(
              text: _prettyStatus(item.status),
              color: _statusColor(item.status),
            ),
          ),
          DataCell(_cellText(_formatDateTime(item.createdAt))),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: 'Chat',
                  onTap: () => _openTicketChat(item),
                ),
                _ActionMenuItem(
                  label: 'Resolve',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Resolve ticket ${item.id}?',
                    actionLabel: 'Resolve',
                    run: (reason) => AdminDashboardState.updateTicketStatus(
                      userUid: item.userUid,
                      ticketId: item.id,
                      status: 'resolved',
                      reason: reason,
                    ),
                  ),
                ),
                _ActionMenuItem(
                  label: 'Close',
                  onTap: () => _runSafeAction(
                    dialogTitle: 'Close ticket ${item.id}?',
                    actionLabel: 'Close',
                    run: (reason) => AdminDashboardState.updateTicketStatus(
                      userUid: item.userUid,
                      ticketId: item.id,
                      status: 'closed',
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildServicesSection() {
    return _AdminTableCard<AdminServiceRow>(
      title: 'Service Catalog',
      subtitle: 'Ensure service coverage and clean category mapping.',
      loadingListenable: AdminDashboardState.loadingServices,
      rowsListenable: AdminDashboardState.services,
      paginationListenable: AdminDashboardState.servicesPagination,
      onPageSelected: _loadServices,
      controls: [
        _DropdownFilter(
          label: 'Service state',
          value: _serviceStateFilter,
          options: const [
            _DropdownOption(value: 'all', label: 'All states'),
            _DropdownOption(value: 'active', label: 'Active'),
            _DropdownOption(value: 'inactive', label: 'Inactive'),
          ],
          onChanged: (value) {
            setState(() => _serviceStateFilter = value);
            unawaited(_loadServices(1));
          },
        ),
      ],
      columns: const ['Service', 'Category', 'State', 'Image', 'ID', 'Action'],
      emptyText: 'No services found for this page.',
      summaryBuilder: (items) {
        final active = items.where((item) => item.active).length;
        final inactive = items.length - active;
        return [
          _MetricChipData(label: 'Page services', value: '${items.length}'),
          _MetricChipData(
            label: 'Active',
            value: '$active',
            color: AppColors.success,
          ),
          _MetricChipData(
            label: 'Inactive',
            value: '$inactive',
            color: AppColors.warning,
          ),
        ];
      },
      filterRows: (items) {
        final query = _searchQuery.trim().toLowerCase();
        return items
            .where((item) {
              final stateMatch =
                  _serviceStateFilter == 'all' ||
                  (_serviceStateFilter == 'active' && item.active) ||
                  (_serviceStateFilter == 'inactive' && !item.active);
              if (!stateMatch) return false;
              if (query.isEmpty) return true;
              final haystack =
                  '${item.name} ${item.categoryName} ${item.id} ${item.categoryId}'
                      .toLowerCase();
              return haystack.contains(query);
            })
            .toList(growable: false);
      },
      rowCells: (item) {
        return [
          DataCell(_cellText(item.name, width: 180)),
          DataCell(_cellText(item.categoryName, width: 170)),
          DataCell(
            _Pill(
              text: item.active ? 'Active' : 'Inactive',
              color: item.active ? AppColors.success : AppColors.warning,
            ),
          ),
          DataCell(
            _cellText(item.imageUrl.isEmpty ? '-' : 'Available', width: 100),
          ),
          DataCell(_cellText(item.id, width: 180)),
          DataCell(
            _actionMenu(
              actions: [
                _ActionMenuItem(
                  label: item.active ? 'Deactivate' : 'Activate',
                  onTap: () => _runSafeAction(
                    dialogTitle:
                        '${item.active ? 'Deactivate' : 'Activate'} service ${item.name}?',
                    actionLabel: item.active ? 'Deactivate' : 'Activate',
                    run: (reason) => AdminDashboardState.updateServiceActive(
                      serviceId: item.id,
                      active: !item.active,
                      reason: reason,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Future<void> _submitBroadcastComposer() async {
    final title = _broadcastTitleController.text.trim();
    final message = _broadcastMessageController.text.trim();
    if (title.length < 3 || message.length < 3) {
      _showError(
        const AdminApiException(
          'Broadcast title and message must be at least 3 characters.',
        ),
      );
      return;
    }

    final targetRoles = <String>[
      if (_broadcastComposerFinder) 'finder',
      if (_broadcastComposerProvider) 'provider',
    ];
    if (targetRoles.isEmpty) {
      _showError(const AdminApiException('Select at least one audience role.'));
      return;
    }

    final isPromo = _broadcastComposerType == 'promotion';
    final promoCode = _broadcastPromoCodeController.text.trim().toUpperCase();
    final discountValue =
        double.tryParse(_broadcastDiscountValueController.text.trim()) ?? 0;
    final minSubtotal =
        double.tryParse(_broadcastMinSubtotalController.text.trim()) ?? 0;
    final maxDiscount =
        double.tryParse(_broadcastMaxDiscountController.text.trim()) ?? 0;
    final usageLimit =
        int.tryParse(_broadcastUsageLimitController.text.trim()) ?? 0;

    if (isPromo) {
      if (promoCode.isEmpty) {
        _showError(const AdminApiException('Promo code is required.'));
        return;
      }
      if (discountValue <= 0) {
        _showError(const AdminApiException('Discount value must be > 0.'));
        return;
      }
    }

    setState(() => _broadcastComposerSaving = true);
    try {
      await _runAuthed(
        () => AdminDashboardState.createBroadcast(
          type: _broadcastComposerType,
          title: title,
          message: message,
          targetRoles: targetRoles,
          active: _broadcastComposerActive,
          promoCode: isPromo ? promoCode : '',
          discountType: _broadcastComposerDiscountType,
          discountValue: isPromo ? discountValue : 0,
          minSubtotal: isPromo ? minSubtotal : 0,
          maxDiscount: isPromo ? maxDiscount : 0,
          usageLimit: isPromo ? usageLimit : 0,
        ),
      );

      _broadcastTitleController.clear();
      _broadcastMessageController.clear();
      _broadcastPromoCodeController.clear();
      _broadcastDiscountValueController.text = '10';
      _broadcastMinSubtotalController.text = '0';
      _broadcastMaxDiscountController.text = '0';
      _broadcastUsageLimitController.text = '0';
      _broadcastComposerType = 'system';
      _broadcastComposerDiscountType = 'percent';
      _broadcastComposerActive = true;
      _broadcastComposerFinder = true;
      _broadcastComposerProvider = true;

      await _loadBroadcasts(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast published successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) {
        setState(() => _broadcastComposerSaving = false);
      }
    }
  }

  Future<void> _toggleBroadcastActive(AdminBroadcastRow row) async {
    final nextActive = !row.active;
    try {
      await _runAuthed(
        () => AdminDashboardState.updateBroadcastActive(
          broadcastId: row.id,
          active: nextActive,
        ),
      );
      await _loadBroadcasts(1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nextActive
                ? 'Broadcast activated successfully.'
                : 'Broadcast deactivated successfully.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      _showError(error);
    }
  }

  Widget _buildBroadcastsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BroadcastComposerCard(
          type: _broadcastComposerType,
          discountType: _broadcastComposerDiscountType,
          finderSelected: _broadcastComposerFinder,
          providerSelected: _broadcastComposerProvider,
          active: _broadcastComposerActive,
          saving: _broadcastComposerSaving,
          titleController: _broadcastTitleController,
          messageController: _broadcastMessageController,
          promoCodeController: _broadcastPromoCodeController,
          discountValueController: _broadcastDiscountValueController,
          minSubtotalController: _broadcastMinSubtotalController,
          maxDiscountController: _broadcastMaxDiscountController,
          usageLimitController: _broadcastUsageLimitController,
          onTypeChanged: (value) =>
              setState(() => _broadcastComposerType = value),
          onDiscountTypeChanged: (value) =>
              setState(() => _broadcastComposerDiscountType = value),
          onFinderToggle: () => setState(
            () => _broadcastComposerFinder = !_broadcastComposerFinder,
          ),
          onProviderToggle: () => setState(
            () => _broadcastComposerProvider = !_broadcastComposerProvider,
          ),
          onActiveChanged: (value) =>
              setState(() => _broadcastComposerActive = value),
          onSubmit: _submitBroadcastComposer,
        ),
        const SizedBox(height: 12),
        _AdminTableCard<AdminBroadcastRow>(
          title: 'Broadcast Feed',
          subtitle: 'Monitor system notices and promo campaign lifecycle.',
          loadingListenable: AdminDashboardState.loadingBroadcasts,
          rowsListenable: AdminDashboardState.broadcasts,
          paginationListenable: AdminDashboardState.broadcastsPagination,
          onPageSelected: _loadBroadcasts,
          controls: [
            _DropdownFilter(
              label: 'Type',
              value: _broadcastTypeFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All types'),
                _DropdownOption(value: 'system', label: 'System'),
                _DropdownOption(value: 'promotion', label: 'Promotion'),
              ],
              onChanged: (value) {
                setState(() => _broadcastTypeFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
            _DropdownFilter(
              label: 'Lifecycle',
              value: _broadcastStatusFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All states'),
                _DropdownOption(value: 'active', label: 'Active'),
                _DropdownOption(value: 'scheduled', label: 'Scheduled'),
                _DropdownOption(value: 'expired', label: 'Expired'),
                _DropdownOption(value: 'inactive', label: 'Inactive'),
              ],
              onChanged: (value) {
                setState(() => _broadcastStatusFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
            _DropdownFilter(
              label: 'Audience',
              value: _broadcastRoleFilter,
              options: const [
                _DropdownOption(value: 'all', label: 'All audience'),
                _DropdownOption(value: 'finder', label: 'Finder'),
                _DropdownOption(value: 'provider', label: 'Provider'),
              ],
              onChanged: (value) {
                setState(() => _broadcastRoleFilter = value);
                unawaited(_loadBroadcasts(1));
              },
            ),
          ],
          columns: const [
            'Type',
            'Title',
            'Audience',
            'Lifecycle',
            'Promo',
            'Created',
            'Action',
          ],
          emptyText: 'No broadcasts found for this page.',
          summaryBuilder: (items) {
            final active = items
                .where((item) => item.lifecycle.toLowerCase() == 'active')
                .length;
            final promos = items
                .where((item) => item.type.toLowerCase() == 'promotion')
                .length;
            final scheduled = items
                .where((item) => item.lifecycle.toLowerCase() == 'scheduled')
                .length;
            return [
              _MetricChipData(
                label: 'Page broadcasts',
                value: '${items.length}',
              ),
              _MetricChipData(
                label: 'Active',
                value: '$active',
                color: AppColors.success,
              ),
              _MetricChipData(
                label: 'Promotions',
                value: '$promos',
                color: const Color(0xFF0EA5E9),
              ),
              _MetricChipData(
                label: 'Scheduled',
                value: '$scheduled',
                color: AppColors.warning,
              ),
            ];
          },
          filterRows: (items) {
            final query = _searchQuery.trim().toLowerCase();
            return items
                .where((item) {
                  final typeMatch =
                      _broadcastTypeFilter == 'all' ||
                      item.type.toLowerCase() == _broadcastTypeFilter;
                  if (!typeMatch) return false;
                  final lifecycleMatch =
                      _broadcastStatusFilter == 'all' ||
                      item.lifecycle.toLowerCase() == _broadcastStatusFilter;
                  if (!lifecycleMatch) return false;
                  final roleMatch =
                      _broadcastRoleFilter == 'all' ||
                      item.targetRoles.any(
                        (role) =>
                            role.toLowerCase().trim() == _broadcastRoleFilter,
                      );
                  if (!roleMatch) return false;
                  if (query.isEmpty) return true;
                  final haystack =
                      '${item.type} ${item.title} ${item.message} ${item.promoCode} ${item.lifecycle} ${item.targetRoles.join(' ')}'
                          .toLowerCase();
                  return haystack.contains(query);
                })
                .toList(growable: false);
          },
          rowCells: (item) {
            final type = item.type.toLowerCase();
            final typeColor = type == 'promotion'
                ? const Color(0xFF0EA5E9)
                : AppColors.primary;
            return [
              DataCell(_Pill(text: _prettyStatus(item.type), color: typeColor)),
              DataCell(_cellText(item.title, width: 210)),
              DataCell(_cellText(item.targetRoles.join(', '), width: 140)),
              DataCell(
                _Pill(
                  text: _prettyStatus(item.lifecycle),
                  color: _statusColor(item.lifecycle),
                ),
              ),
              DataCell(
                _cellText(item.promoCode.isEmpty ? '-' : item.promoCode),
              ),
              DataCell(_cellText(_formatDateTime(item.createdAt), width: 150)),
              DataCell(
                _actionMenu(
                  actions: [
                    _ActionMenuItem(
                      label: item.active ? 'Deactivate' : 'Activate',
                      onTap: () => _toggleBroadcastActive(item),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _actionMenu({required List<_ActionMenuItem> actions}) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    return PopupMenuButton<int>(
      icon: const Icon(Icons.more_vert_rounded),
      tooltip: 'Actions',
      onSelected: (index) {
        if (index < 0 || index >= actions.length) return;
        unawaited(Future.sync(actions[index].onTap));
      },
      itemBuilder: (context) {
        return List<PopupMenuEntry<int>>.generate(actions.length, (index) {
          final action = actions[index];
          return PopupMenuItem<int>(value: index, child: Text(action.label));
        });
      },
    );
  }
}

class _ActionReasonDialog extends StatefulWidget {
  final String title;
  final String actionLabel;

  const _ActionReasonDialog({required this.title, required this.actionLabel});

  @override
  State<_ActionReasonDialog> createState() => _ActionReasonDialogState();
}

class _ActionReasonDialogState extends State<_ActionReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        minLines: 2,
        maxLines: 4,
        decoration: _adminFieldDecoration(hintText: 'Reason (required)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
