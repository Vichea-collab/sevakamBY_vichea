import 'dart:async';
import 'dart:math' as math;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../app/admin_web_app.dart';
import '../../data/network/admin_api_client.dart';
import '../../domain/entities/admin_models.dart';
import '../state/admin_dashboard_state.dart';

enum _AdminSection { overview, users, orders, posts, tickets, services }

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
  Timer? _searchDebounce;

  String _searchQuery = '';
  String _userRoleFilter = 'all';
  String _orderStatusFilter = 'all';
  String _postTypeFilter = 'all';
  String _ticketStatusFilter = 'all';
  String _serviceStateFilter = 'all';
  String _undoHistoryStateFilter = 'all';
  int _analyticsDays = 14;
  int _analyticsCompareDays = 14;
  int _undoHistoryPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() => _searchQuery = _searchController.text);
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 420), () {
        if (!mounted) return;
        unawaited(_onSearchChanged());
      });
    });
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
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
    await Future.wait<void>([
      AdminDashboardState.refreshOverview(),
      AdminDashboardState.refreshReadBudget(),
      AdminDashboardState.refreshAnalytics(
        days: _analyticsDays,
        compareDays: _analyticsCompareDays,
      ),
    ]);
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
    }
  }

  Future<void> _onSearchChanged() async {
    try {
      await _runAuthed(() async {
        await AdminDashboardState.runGlobalSearch(
          query: _searchQuery,
          limit: 4,
        );
        await _reloadCurrentSection(page: 1);
      });
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
    setState(() {
      _section = section;
    });
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
    await _reloadCurrentSection(page: 1);
  }

  Future<String?> _askActionReason({
    required String title,
    required String actionLabel,
  }) async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(title),
            content: TextField(
              controller: controller,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Reason (required)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: Text(actionLabel),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
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
        await AdminDashboardState.refreshReadBudget();
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
                        await AdminDashboardState.refreshReadBudget();
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
        await AdminDashboardState.refreshReadBudget();
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

  Widget _buildMainContent({required bool desktop}) {
    return Column(
      children: [
        _DashboardToolbar(
          section: _section,
          searchController: _searchController,
          onRefresh: _refreshAll,
        ),
        ValueListenableBuilder<AdminReadBudget>(
          valueListenable: AdminDashboardState.readBudget,
          builder: (context, budget, _) {
            return _ReadBudgetCard(budget: budget);
          },
        ),
        ValueListenableBuilder<AdminGlobalSearchResult>(
          valueListenable: AdminDashboardState.globalSearch,
          builder: (context, result, _) {
            if (_searchQuery.trim().length < 2 || result.groups.isEmpty) {
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
              children: [_buildActiveSection()],
            ),
          ),
        ),
      ],
    );
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
    }
  }

  Future<void> _setAnalyticsRange(int days) async {
    setState(() {
      _analyticsDays = days;
      _analyticsCompareDays = days;
    });
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshAnalytics(
          days: _analyticsDays,
          compareDays: _analyticsCompareDays,
        ),
      );
    } catch (error) {
      _showError(error);
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
                const SizedBox(height: 12),
                ValueListenableBuilder<AdminAnalytics>(
                  valueListenable: AdminDashboardState.analytics,
                  builder: (context, analytics, _) {
                    return _OverviewAnalyticsCard(
                      analytics: analytics,
                      selectedDays: _analyticsDays,
                      onDaysChanged: (days) =>
                          unawaited(_setAnalyticsRange(days)),
                    );
                  },
                ),
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
        'User UID',
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
                  '${item.title} ${item.message} ${item.userUid} ${item.status}'
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
            _cellText(item.userUid.isEmpty ? '-' : item.userUid, width: 180),
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

class _DashboardSidebar extends StatelessWidget {
  final String email;
  final _AdminSection section;
  final ValueChanged<_AdminSection> onSectionChanged;
  final Future<void> Function() onLogout;

  const _DashboardSidebar({
    required this.email,
    required this.section,
    required this.onSectionChanged,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 8, 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFD7E2F5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                gradient: LinearGradient(
                  colors: [Color(0xFF0F5CD7), Color(0xFF5C8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.24),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sevakam Admin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: _AdminSection.values.length,
                itemBuilder: (context, index) {
                  final item = _AdminSection.values[index];
                  final selected = item == section;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Material(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSectionChanged(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item.icon,
                                size: 24,
                                color: selected
                                    ? AppColors.primaryDark
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                item.label,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE3EAF9)),
            Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Sign out'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFD5DEEF)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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

class _DashboardToolbar extends StatelessWidget {
  final _AdminSection section;
  final TextEditingController searchController;
  final Future<void> Function() onRefresh;

  const _DashboardToolbar({
    required this.section,
    required this.searchController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD8E3F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
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
                        section.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        section.subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.14),
                    foregroundColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search current section...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: searchController.clear,
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: const Color(0xFFF8FAFF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD5DFEF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFD5DFEF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.3,
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

class _AdminTableCard<T> extends StatelessWidget {
  final String title;
  final String subtitle;
  final ValueListenable<bool> loadingListenable;
  final ValueListenable<List<T>> rowsListenable;
  final ValueListenable<AdminPagination> paginationListenable;
  final Future<void> Function(int page) onPageSelected;
  final List<Widget> controls;
  final List<String> columns;
  final String emptyText;
  final List<_MetricChipData> Function(List<T> items) summaryBuilder;
  final List<T> Function(List<T> items) filterRows;
  final List<DataCell> Function(T row) rowCells;

  const _AdminTableCard({
    required this.title,
    required this.subtitle,
    required this.loadingListenable,
    required this.rowsListenable,
    required this.paginationListenable,
    required this.onPageSelected,
    required this.controls,
    required this.columns,
    required this.emptyText,
    required this.summaryBuilder,
    required this.filterRows,
    required this.rowCells,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: loadingListenable,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<T>>(
          valueListenable: rowsListenable,
          builder: (context, rows, _) {
            return ValueListenableBuilder<AdminPagination>(
              valueListenable: paginationListenable,
              builder: (context, pageMeta, _) {
                final filteredRows = filterRows(rows);
                final summaries = summaryBuilder(rows);

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFD8E3F6)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
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
                                  title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          if (isLoading)
                            const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      if (controls.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(spacing: 10, runSpacing: 8, children: controls),
                      ],
                      if (summaries.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: summaries
                              .map(
                                (item) => _Pill(
                                  text: '${item.label}: ${item.value}',
                                  color: item.color,
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                      const SizedBox(height: 10),
                      if (filteredRows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            rows.isEmpty
                                ? emptyText
                                : 'No rows matched your search/filter in this page.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        )
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStatePropertyAll(
                              const Color(0xFFF4F7FF),
                            ),
                            columns: columns
                                .map(
                                  (name) => DataColumn(
                                    label: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                            rows: filteredRows
                                .map((row) => DataRow(cells: rowCells(row)))
                                .toList(growable: false),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Page ${pageMeta.page} • ${filteredRows.length}/${rows.length} visible • ${pageMeta.totalItems} total items',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _CompactPager(
                        page: pageMeta.page,
                        totalPages: pageMeta.totalPages,
                        loading: isLoading,
                        onPageSelected: onPageSelected,
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _OverviewKpiGrid extends StatelessWidget {
  final Map<String, num> kpis;

  const _OverviewKpiGrid({required this.kpis});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _KpiData(
        label: 'Users',
        value: '${_intValue(kpis['users'])}',
        icon: Icons.group_rounded,
      ),
      _KpiData(
        label: 'Finders',
        value: '${_intValue(kpis['finders'])}',
        icon: Icons.person_search_rounded,
      ),
      _KpiData(
        label: 'Providers',
        value: '${_intValue(kpis['providers'])}',
        icon: Icons.handyman_rounded,
      ),
      _KpiData(
        label: 'Orders',
        value: '${_intValue(kpis['orders'])}',
        icon: Icons.receipt_long_rounded,
      ),
      _KpiData(
        label: 'Open Finder Requests',
        value: '${_intValue(kpis['activeFinderRequests'])}',
        icon: Icons.assignment_rounded,
      ),
      _KpiData(
        label: 'Open Provider Offers',
        value: '${_intValue(kpis['activeProviderPosts'])}',
        icon: Icons.campaign_rounded,
      ),
      _KpiData(
        label: 'Open Tickets',
        value: '${_intValue(kpis['openHelpTickets'])}',
        icon: Icons.support_agent_rounded,
      ),
      _KpiData(
        label: 'Completed Revenue',
        value: _toMoney(_numValue(kpis['completedRevenue'])),
        icon: Icons.attach_money_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 760
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: columns == 2 ? 1.5 : 1.8,
          ),
          itemBuilder: (context, index) {
            final card = cards[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF8FAFF),
                border: Border.all(color: const Color(0xFFDDE6F8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: AppColors.primary.withValues(alpha: 0.12),
                    ),
                    child: Icon(card.icon, color: AppColors.primary, size: 44),
                  ),
                  const Spacer(),
                  Text(
                    card.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    card.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusBoard extends StatelessWidget {
  final Map<String, int> status;

  const _StatusBoard({required this.status});

  @override
  Widget build(BuildContext context) {
    final chips = [
      _MetricChipData(
        label: 'Booked',
        value: '${status['booked'] ?? 0}',
        color: AppColors.warning,
      ),
      _MetricChipData(
        label: 'On the way',
        value: '${status['on_the_way'] ?? 0}',
        color: AppColors.primary,
      ),
      _MetricChipData(
        label: 'Started',
        value: '${status['started'] ?? 0}',
        color: const Color(0xFF0284C7),
      ),
      _MetricChipData(
        label: 'Completed',
        value: '${status['completed'] ?? 0}',
        color: AppColors.success,
      ),
      _MetricChipData(
        label: 'Cancelled',
        value: '${status['cancelled'] ?? 0}',
        color: AppColors.danger,
      ),
      _MetricChipData(
        label: 'Declined',
        value: '${status['declined'] ?? 0}',
        color: const Color(0xFFE11D48),
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order status health',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips
                .map(
                  (item) => _Pill(
                    text: '${item.label}: ${item.value}',
                    color: item.color,
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ReadBudgetCard extends StatelessWidget {
  final AdminReadBudget budget;

  const _ReadBudgetCard({required this.budget});

  @override
  Widget build(BuildContext context) {
    final percent = budget.usedPercent.clamp(0, 1).toDouble();
    final level = budget.level.trim().toLowerCase();
    final color = switch (level) {
      'critical' => AppColors.danger,
      'warning' => AppColors.warning,
      _ => AppColors.success,
    };
    final label = switch (level) {
      'critical' => 'Critical read usage',
      'warning' => 'Read usage warning',
      _ => 'Read usage healthy',
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E3F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withValues(alpha: 0.15),
                  ),
                  child: Icon(Icons.speed_rounded, color: color, size: 24),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Firestore Read Budget',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$label • ${budget.dateKey.isEmpty ? 'Today' : budget.dateKey}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _Pill(
                  text: '${(percent * 100).toStringAsFixed(1)}%',
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: percent,
                backgroundColor: const Color(0xFFEAF0FF),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  text: 'Used: ${budget.estimatedReadsUsed}',
                  color: AppColors.primary,
                ),
                _Pill(
                  text: 'Remaining: ${budget.estimatedReadsRemaining}',
                  color: AppColors.success,
                ),
                _Pill(
                  text: 'Budget: ${budget.dailyBudget}',
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalSearchPanel extends StatelessWidget {
  final AdminGlobalSearchResult result;
  final ValueChanged<AdminSearchItem> onTap;

  const _GlobalSearchPanel({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 2, 14, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD8E3F6)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x120F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.travel_explore_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Global results for "${result.query}"',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _Pill(
                  text: '${result.total} matches',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...result.groups.map((group) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.label,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...group.items.map(
                      (item) => InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onTap(item),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FAFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFDCE6F7)),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _searchSectionIcon(item.section),
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    if (item.subtitle.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        item.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OverviewAnalyticsCard extends StatelessWidget {
  final AdminAnalytics analytics;
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;

  const _OverviewAnalyticsCard({
    required this.analytics,
    required this.selectedDays,
    required this.onDaysChanged,
  });

  @override
  Widget build(BuildContext context) {
    final delta = analytics.deltaPercent;
    final maxFunnel = math.max(
      1,
      math.max(
        analytics.funnel.postIntents,
        math.max(
          analytics.funnel.activeChats,
          math.max(
            analytics.funnel.bookedOrders,
            analytics.funnel.completedOrders,
          ),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Performance Analytics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Wrap(
                spacing: 6,
                children: [7, 14, 30]
                    .map((days) {
                      final selected = days == selectedDays;
                      return ChoiceChip(
                        selected: selected,
                        label: Text('${days}d'),
                        onSelected: (_) => onDaysChanged(days),
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
                    })
                    .toList(growable: false),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 920;
              final tiles = [
                _AnalyticsMetricTile(
                  label: 'Orders',
                  value: '${analytics.current.orders}',
                  delta: delta['orders'] ?? 0,
                  color: AppColors.primary,
                ),
                _AnalyticsMetricTile(
                  label: 'Completed',
                  value: '${analytics.current.completedOrders}',
                  delta: delta['completedOrders'] ?? 0,
                  color: AppColors.success,
                ),
                _AnalyticsMetricTile(
                  label: 'Cancelled',
                  value: '${analytics.current.cancelledOrders}',
                  delta: delta['cancelledOrders'] ?? 0,
                  color: AppColors.warning,
                ),
                _AnalyticsMetricTile(
                  label: 'Revenue',
                  value: _toMoney(analytics.current.revenue),
                  delta: delta['revenue'] ?? 0,
                  color: const Color(0xFF0284C7),
                ),
              ];
              if (!wide) {
                return Column(
                  children: tiles
                      .map(
                        (tile) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: tile,
                        ),
                      )
                      .toList(growable: false),
                );
              }
              return Row(
                children: tiles
                    .map(
                      (tile) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: tile,
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 10),
          Text(
            'Conversion funnel',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FunnelStage(
                label: 'Post intents',
                value: analytics.funnel.postIntents,
                max: maxFunnel,
                color: const Color(0xFF1D4ED8),
              ),
              _FunnelStage(
                label: 'Active chats',
                value: analytics.funnel.activeChats,
                max: maxFunnel,
                color: const Color(0xFF0284C7),
              ),
              _FunnelStage(
                label: 'Booked',
                value: analytics.funnel.bookedOrders,
                max: maxFunnel,
                color: const Color(0xFF14B8A6),
              ),
              _FunnelStage(
                label: 'Completed',
                value: analytics.funnel.completedOrders,
                max: maxFunnel,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _TrendBars(
            currentSeries: analytics.currentSeries,
            previousSeries: analytics.previousSeries,
          ),
          if (analytics.topServices.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Top services',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            ...analytics.topServices.take(5).map((service) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE6F7)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.serviceName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _Pill(
                      text: '${service.completedOrders} done',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _toMoney(service.revenue),
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _UndoHistoryCard extends StatelessWidget {
  final bool loading;
  final List<AdminUndoHistoryRow> items;
  final AdminPagination pagination;
  final String selectedState;
  final ValueChanged<String> onStateChanged;
  final Future<void> Function(int page) onPageSelected;
  final Future<void> Function(AdminUndoHistoryRow row) onUndo;

  const _UndoHistoryCard({
    required this.loading,
    required this.items,
    required this.pagination,
    required this.selectedState,
    required this.onStateChanged,
    required this.onPageSelected,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Undo history',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: selectedState,
                  decoration: InputDecoration(
                    labelText: 'State',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD3DDEF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.2,
                      ),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All states')),
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(value: 'used', child: Text('Used')),
                    DropdownMenuItem(value: 'expired', child: Text('Expired')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    onStateChanged(value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track reversible actions and restore items while undo is still valid.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(minHeight: 2),
            ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              'No undo actions found.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            ...items.map((item) {
              final stateColor = _undoStateColor(item.state);
              final target = item.targetLabel.isEmpty
                  ? item.docPath
                  : item.targetLabel;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDDE6F8)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_prettyUndoActionType(item.actionType)} • ${target.isEmpty ? item.id : target}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _Pill(
                          text: _prettyStatus(item.state),
                          color: stateColor,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.reason.isEmpty ? 'No reason provided.' : item.reason,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          'Created: ${_formatDateTime(item.createdAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Expires: ${_formatDateTime(item.expiresAt)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (item.usedAt != null)
                          Text(
                            'Used: ${_formatDateTime(item.usedAt)}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    if (item.canUndo) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => onUndo(item),
                          icon: const Icon(Icons.undo_rounded, size: 18),
                          label: const Text('Undo now'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryDark,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          const SizedBox(height: 6),
          Text(
            'Page ${pagination.page} • ${items.length} items',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          _CompactPager(
            page: pagination.page,
            totalPages: pagination.totalPages,
            loading: loading,
            onPageSelected: onPageSelected,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final double delta;
  final Color color;

  const _AnalyticsMetricTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final positive = delta >= 0;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: (positive ? AppColors.success : AppColors.danger)
                  .withValues(alpha: 0.12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  color: positive ? AppColors.success : AppColors.danger,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${delta.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: positive ? AppColors.success : AppColors.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FunnelStage extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;

  const _FunnelStage({
    required this.label,
    required this.value,
    required this.max,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (value / math.max(1, max)).clamp(0, 1).toDouble();
    return Container(
      width: 180,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: progress,
              backgroundColor: const Color(0xFFEAF0FF),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBars extends StatelessWidget {
  final List<AdminAnalyticsSeriesPoint> currentSeries;
  final List<AdminAnalyticsSeriesPoint> previousSeries;

  const _TrendBars({required this.currentSeries, required this.previousSeries});

  @override
  Widget build(BuildContext context) {
    if (currentSeries.isEmpty && previousSeries.isEmpty) {
      return const SizedBox.shrink();
    }
    final maxOrders = math.max<int>(
      1,
      [
        ...currentSeries.map((item) => item.orders),
        ...previousSeries.map((item) => item.orders),
      ].fold<int>(0, math.max),
    );
    final points = math.max(currentSeries.length, previousSeries.length);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDE6F8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily trend (orders)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List<Widget>.generate(points, (index) {
                final current = index < currentSeries.length
                    ? currentSeries[index].orders
                    : 0;
                final previous = index < previousSeries.length
                    ? previousSeries[index].orders
                    : 0;
                final currentHeight = 10 + (64 * (current / maxOrders));
                final previousHeight = 10 + (64 * (previous / maxOrders));
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          Container(
                            width: 12,
                            height: previousHeight,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF94A3B8,
                              ).withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          Container(
                            width: 9,
                            height: currentHeight,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              _TrendLegend(color: AppColors.primary, label: 'Current'),
              SizedBox(width: 10),
              _TrendLegend(color: Color(0xFF94A3B8), label: 'Previous'),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _TrendLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

IconData _searchSectionIcon(String section) {
  switch (section.trim().toLowerCase()) {
    case 'users':
      return Icons.group_rounded;
    case 'orders':
      return Icons.receipt_long_rounded;
    case 'posts':
      return Icons.campaign_rounded;
    case 'tickets':
      return Icons.support_agent_rounded;
    case 'services':
      return Icons.handyman_rounded;
    default:
      return Icons.search_rounded;
  }
}

class _ActivityCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final List<_ActivityItem> items;
  final String emptyText;

  const _ActivityCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFD8E3F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Text(
              emptyText,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            Column(
              children: items
                  .take(7)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFDCE6F7)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.trailing,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _CompactPager extends StatelessWidget {
  final int page;
  final int totalPages;
  final bool loading;
  final Future<void> Function(int page) onPageSelected;

  const _CompactPager({
    required this.page,
    required this.totalPages,
    required this.loading,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) {
      return const SizedBox.shrink();
    }

    final pages = _buildPages(page, totalPages);
    final canPrev = page > 1 && !loading;
    final canNext = page < totalPages && !loading;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _pagerButton(
            icon: Icons.chevron_left_rounded,
            enabled: canPrev,
            onTap: () => onPageSelected(page - 1),
          ),
          const SizedBox(width: 8),
          for (final token in pages) ...[
            if (token is int)
              _pagerButton(
                label: '$token',
                selected: token == page,
                enabled: !loading,
                onTap: () => onPageSelected(token),
              )
            else
              _pagerButton(label: '...', enabled: false, onTap: null),
            const SizedBox(width: 8),
          ],
          _pagerButton(
            icon: Icons.chevron_right_rounded,
            enabled: canNext,
            onTap: () => onPageSelected(page + 1),
          ),
        ],
      ),
    );
  }

  Widget _pagerButton({
    String label = '',
    IconData? icon,
    bool selected = false,
    required bool enabled,
    required VoidCallback? onTap,
  }) {
    final background = selected ? AppColors.primary : Colors.white;
    final border = selected ? AppColors.primary : const Color(0xFFD1DBEE);
    final foreground = selected
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 42,
        width: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x332C5EFF),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ]
              : const [],
        ),
        child: icon != null
            ? Icon(icon, color: foreground)
            : Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
      ),
    );
  }

  List<Object> _buildPages(int currentPage, int totalPages) {
    if (totalPages <= 7) {
      return List<Object>.generate(totalPages, (index) => index + 1);
    }

    final raw = <int>{1, totalPages, currentPage};
    if (currentPage - 1 > 1) raw.add(currentPage - 1);
    if (currentPage + 1 < totalPages) raw.add(currentPage + 1);
    if (currentPage <= 3) {
      raw.add(2);
      raw.add(3);
    }
    if (currentPage >= totalPages - 2) {
      raw.add(totalPages - 1);
      raw.add(totalPages - 2);
    }

    final sorted =
        raw.where((value) => value >= 1 && value <= totalPages).toList()
          ..sort();

    final tokens = <Object>[];
    for (var index = 0; index < sorted.length; index++) {
      final current = sorted[index];
      tokens.add(current);
      if (index == sorted.length - 1) continue;
      final next = sorted[index + 1];
      if (next - current > 1) {
        tokens.add('ellipsis');
      }
    }
    return tokens;
  }
}

class _DropdownFilter extends StatelessWidget {
  final String label;
  final String value;
  final List<_DropdownOption> options;
  final ValueChanged<String> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<String>(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD3DDEF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
          isDense: true,
        ),
        items: options
            .map(
              (option) => DropdownMenuItem<String>(
                value: option.value,
                child: Text(option.label),
              ),
            )
            .toList(growable: false),
        onChanged: (next) {
          if (next == null) return;
          onChanged(next);
        },
      ),
    );
  }
}

class _DropdownOption {
  final String value;
  final String label;

  const _DropdownOption({required this.value, required this.label});
}

class _ActionMenuItem {
  final String label;
  final FutureOr<void> Function() onTap;

  const _ActionMenuItem({required this.label, required this.onTap});
}

class _MetricChipData {
  final String label;
  final String value;
  final Color color;

  const _MetricChipData({
    required this.label,
    required this.value,
    this.color = AppColors.primary,
  });
}

class _KpiData {
  final String label;
  final String value;
  final IconData icon;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
  });
}

class _ActivityItem {
  final String title;
  final String subtitle;
  final String trailing;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });
}

class _Pill extends StatelessWidget {
  final String text;
  final Color color;

  const _Pill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
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
          fontSize: 12,
        ),
      ),
    );
  }
}

class _BootstrappingView extends StatelessWidget {
  const _BootstrappingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.93),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFD9E3F7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2.3),
            ),
            SizedBox(width: 12),
            Text('Loading admin workspace...'),
          ],
        ),
      ),
    );
  }
}

class _MobileTopBar extends StatelessWidget {
  final String email;
  final Future<void> Function() onLogout;

  const _MobileTopBar({required this.email, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F5CD7), Color(0xFF5C8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x332563EB),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sevakam Admin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowBubble extends StatelessWidget {
  final double diameter;
  final Color color;

  const _GlowBubble({required this.diameter, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

Widget _cellText(String value, {double width = 130}) {
  return SizedBox(
    width: width,
    child: Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppColors.textPrimary),
    ),
  );
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '-';
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}

String _toMoney(num value) => '\$${value.toStringAsFixed(2)}';

int _intValue(num? value) => value?.toInt() ?? 0;

double _numValue(num? value) => value?.toDouble() ?? 0;

String _prettyStatus(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) return 'Unknown';
  return normalized
      .split('_')
      .map(
        (part) =>
            part.isEmpty ? '' : '${part[0].toUpperCase()}${part.substring(1)}',
      )
      .join(' ');
}

String _prettyPostType(String value) {
  return switch (value.trim().toLowerCase()) {
    'provider_offer' => 'Provider Offer',
    'finder_request' => 'Finder Request',
    _ => 'Post',
  };
}

Color _statusColor(String status) {
  return switch (status.trim().toLowerCase()) {
    'completed' => AppColors.success,
    'booked' => AppColors.warning,
    'on_the_way' => AppColors.primary,
    'started' => const Color(0xFF0284C7),
    'cancelled' => AppColors.danger,
    'declined' => const Color(0xFFE11D48),
    'resolved' => AppColors.success,
    'closed' => const Color(0xFF64748B),
    _ => AppColors.textSecondary,
  };
}

Color _postTypeColor(String type) {
  return switch (type.trim().toLowerCase()) {
    'provider_offer' => AppColors.primary,
    'finder_request' => const Color(0xFF14B8A6),
    _ => AppColors.textSecondary,
  };
}

Color _undoStateColor(String state) {
  return switch (state.trim().toLowerCase()) {
    'available' => AppColors.success,
    'used' => const Color(0xFF64748B),
    'expired' => AppColors.warning,
    _ => AppColors.textSecondary,
  };
}

String _prettyUndoActionType(String actionType) {
  final value = actionType.trim().toLowerCase();
  switch (value) {
    case 'user_status':
      return 'User status';
    case 'order_status':
      return 'Order status';
    case 'post_status':
      return 'Post status';
    case 'ticket_status':
      return 'Ticket status';
    case 'service_active':
      return 'Service state';
    default:
      return _prettyStatus(value);
  }
}
