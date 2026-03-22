import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/support_ticket_options.dart';
import '../../../core/firebase/firebase_storage_service.dart';
import '../../../core/utils/safe_image_provider.dart';
import '../../../domain/entities/subscription.dart';
import '../../app/admin_web_app.dart';
import '../../data/network/admin_api_client.dart';
import '../../domain/entities/admin_models.dart';
import '../state/admin_dashboard_state.dart';
part 'admin_dashboard_section_overview.dart';
part 'admin_dashboard_section_users.dart';
part 'admin_dashboard_section_kyc.dart';
part 'admin_dashboard_section_subscriptions.dart';
part 'admin_dashboard_section_orders.dart';
part 'admin_dashboard_section_posts.dart';
part 'admin_dashboard_section_tickets.dart';
part 'admin_dashboard_section_services.dart';
part 'admin_dashboard_section_promotions.dart';
part 'admin_dashboard_section_broadcasts.dart';
part '../widgets/admin_dashboard_shell_widgets.dart';
part '../widgets/admin_dashboard_table_widgets.dart';
part '../widgets/admin_dashboard_overview_widgets.dart';
part '../widgets/admin_dashboard_media_widgets.dart';
part '../widgets/admin_dashboard_widgets.dart';

enum _AdminSection {
  overview,
  users,
  kyc,
  subscriptions,
  orders,
  posts,
  tickets,
  services,
  promotions,
  broadcasts,
}

extension _AdminSectionX on _AdminSection {
  String get label {
    switch (this) {
      case _AdminSection.overview:
        return 'Overview';
      case _AdminSection.users:
        return 'Users';
      case _AdminSection.kyc:
        return 'Provider Verification';
      case _AdminSection.subscriptions:
        return 'Subscriptions';
      case _AdminSection.orders:
        return 'Orders';
      case _AdminSection.posts:
        return 'Posts';
      case _AdminSection.tickets:
        return 'Tickets';
      case _AdminSection.services:
        return 'Services';
      case _AdminSection.promotions:
        return 'Promotions';
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
      case _AdminSection.kyc:
        return 'Review provider KYC documents and approval status';
      case _AdminSection.subscriptions:
        return 'Track provider plans, monthly pricing, and billing revenue';
      case _AdminSection.orders:
        return 'Bookings and service lifecycle status';
      case _AdminSection.posts:
        return 'Finder requests and provider offers';
      case _AdminSection.tickets:
        return 'Support workload and open incidents';
      case _AdminSection.services:
        return 'Service catalog and category coverage';
      case _AdminSection.promotions:
        return 'Curate finder home carousel ads and campaign windows';
      case _AdminSection.broadcasts:
        return 'System announcements and promotion campaigns';
    }
  }

  IconData get icon {
    switch (this) {
      case _AdminSection.overview:
        return Icons.dashboard_rounded;
      case _AdminSection.users:
        return Icons.group_rounded;
      case _AdminSection.kyc:
        return Icons.verified_user_rounded;
      case _AdminSection.subscriptions:
        return Icons.workspace_premium_rounded;
      case _AdminSection.orders:
        return Icons.receipt_long_rounded;
      case _AdminSection.posts:
        return Icons.campaign_rounded;
      case _AdminSection.tickets:
        return Icons.support_agent_rounded;
      case _AdminSection.services:
        return Icons.handyman_rounded;
      case _AdminSection.promotions:
        return Icons.view_carousel_rounded;
      case _AdminSection.broadcasts:
        return Icons.campaign_rounded;
    }
  }

  String get navHint {
    switch (this) {
      case _AdminSection.overview:
        return 'Metrics and recent signals';
      case _AdminSection.users:
        return 'Roles, states, and access';
      case _AdminSection.kyc:
        return 'Provider identity review';
      case _AdminSection.subscriptions:
        return 'Plans, billing, and revenue';
      case _AdminSection.orders:
        return 'Service booking pipeline';
      case _AdminSection.posts:
        return 'Finder and provider activity';
      case _AdminSection.tickets:
        return 'Support triage workspace';
      case _AdminSection.services:
        return 'Catalog structure and status';
      case _AdminSection.promotions:
        return 'Home placements and campaigns';
      case _AdminSection.broadcasts:
        return 'System notices and messages';
    }
  }

  Color get accentColor {
    switch (this) {
      case _AdminSection.overview:
        return const Color(0xFF2563EB);
      case _AdminSection.users:
        return const Color(0xFF3B82F6);
      case _AdminSection.kyc:
        return const Color(0xFF0F766E);
      case _AdminSection.subscriptions:
        return const Color(0xFF7C3AED);
      case _AdminSection.orders:
        return const Color(0xFFF97316);
      case _AdminSection.posts:
        return const Color(0xFFEA580C);
      case _AdminSection.tickets:
        return const Color(0xFF4F46E5);
      case _AdminSection.services:
        return const Color(0xFF0891B2);
      case _AdminSection.promotions:
        return const Color(0xFFDB2777);
      case _AdminSection.broadcasts:
        return const Color(0xFF4338CA);
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
  bool? _sidebarExpanded = true;
  _AdminSection _section = _AdminSection.overview;
  late final TextEditingController _searchController;

  String _searchQuery = '';
  String _userRoleFilter = 'all';
  String _userKycFilter = 'all';
  String _userPlanFilter = 'all';
  String _subscriptionPlanFilter = 'all';
  String _subscriptionStatusFilter = 'all';
  String _orderStatusFilter = 'all';
  String _postTypeFilter = 'all';
  String _ticketStatusFilter = 'all';
  String _ticketCategoryFilter = 'all';
  String _serviceStateFilter = 'all';
  String _promotionPlacementFilter = 'finder_home';
  String _promotionTargetTypeFilter = 'all';
  String _promotionStatusFilter = 'all';
  String _broadcastTypeFilter = 'all';
  String _broadcastStatusFilter = 'all';
  String _broadcastRoleFilter = 'all';
  String _undoHistoryStateFilter = 'all';
  String _broadcastComposerType = 'system';
  String _promotionComposerPlacement = 'finder_home';
  String _promotionComposerTargetType = 'search';
  bool _broadcastComposerFinder = true;
  bool _broadcastComposerProvider = true;
  bool _broadcastComposerActive = true;
  bool _broadcastComposerSaving = false;
  bool _promotionComposerFinder = true;
  bool _promotionComposerProvider = false;
  bool _promotionComposerActive = true;
  bool _promotionComposerSaving = false;
  int _undoHistoryPage = 1;
  late final TextEditingController _broadcastTitleController;
  late final TextEditingController _broadcastMessageController;
  late final TextEditingController _promotionBadgeController;
  late final TextEditingController _promotionTitleController;
  late final TextEditingController _promotionCtaController;
  late final TextEditingController _promotionTargetValueController;
  late final TextEditingController _promotionQueryController;
  late final TextEditingController _promotionCategoryController;
  late final TextEditingController _promotionCityController;
  late final TextEditingController _promotionSortOrderController;
  late final TextEditingController _promotionStartAtController;
  late final TextEditingController _promotionEndAtController;
  Uint8List? _promotionImageBytes;
  String? _promotionImageName;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _broadcastTitleController = TextEditingController();
    _broadcastMessageController = TextEditingController();
    _promotionBadgeController = TextEditingController(text: 'Featured');
    _promotionTitleController = TextEditingController();
    _promotionCtaController = TextEditingController(text: 'Explore');
    _promotionTargetValueController = TextEditingController();
    _promotionQueryController = TextEditingController();
    _promotionCategoryController = TextEditingController();
    _promotionCityController = TextEditingController();
    _promotionSortOrderController = TextEditingController(text: '0');
    _promotionStartAtController = TextEditingController();
    _promotionEndAtController = TextEditingController();
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
    _promotionBadgeController.dispose();
    _promotionTitleController.dispose();
    _promotionCtaController.dispose();
    _promotionTargetValueController.dispose();
    _promotionQueryController.dispose();
    _promotionCategoryController.dispose();
    _promotionCityController.dispose();
    _promotionSortOrderController.dispose();
    _promotionStartAtController.dispose();
    _promotionEndAtController.dispose();
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
                  final sidebarExpanded = _sidebarExpanded ?? true;
                  final desktop = constraints.maxWidth >= 1080;
                  if (desktop) {
                    return Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: sidebarExpanded ? 318 : 112,
                          child: _DashboardSidebar(
                            email: email,
                            section: _section,
                            expanded: sidebarExpanded,
                            onSectionChanged: _onSectionChanged,
                            onToggleExpanded: _toggleSidebarExpanded,
                            onLogout: _logout,
                          ),
                        ),
                        Expanded(child: _buildMainContent(desktop: true)),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      _MobileTopBar(
                        email: email,
                        section: _section,
                        onSectionChanged: _onSectionChanged,
                        onLogout: _logout,
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

  void _toggleSidebarExpanded() {
    setState(() => _sidebarExpanded = !(_sidebarExpanded ?? true));
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
          category: _ticketCategoryFilter == 'all' ? '' : _ticketCategoryFilter,
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

  Future<void> _loadPromotions(int page) async {
    try {
      await _runAuthed(
        () => AdminDashboardState.refreshPromotions(
          page: page,
          query: _searchQuery,
          placement: _promotionPlacementFilter,
          targetType: _promotionTargetTypeFilter == 'all'
              ? ''
              : _promotionTargetTypeFilter,
          status: _promotionStatusFilter == 'all' ? '' : _promotionStatusFilter,
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
      case _AdminSection.kyc:
      case _AdminSection.subscriptions:
        return _loadUsers(page);
      case _AdminSection.orders:
        return _loadOrders(page);
      case _AdminSection.posts:
        return _loadPosts(page);
      case _AdminSection.tickets:
        return _loadTickets(page);
      case _AdminSection.services:
        return _loadServices(page);
      case _AdminSection.promotions:
        return _loadPromotions(page);
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

  void _setSectionState(VoidCallback fn) => setState(fn);

  _AdminSection? _sectionFromKey(String value) {
    switch (value.trim().toLowerCase()) {
      case 'users':
        return _AdminSection.users;
      case 'kyc':
      case 'provider_verification':
        return _AdminSection.kyc;
      case 'subscription':
      case 'subscriptions':
        return _AdminSection.subscriptions;
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

  Future<void> _showPostDetails(AdminPostRow item) async {
    final services = item.serviceList;
    final serviceText = services.isEmpty ? 'Service' : services.join(', ');
    final details = item.details.trim().isEmpty ? '-' : item.details.trim();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post details'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Type: ${_prettyPostType(item.type)}'),
                  const SizedBox(height: 8),
                  Text('Owner: ${item.ownerName}'),
                  const SizedBox(height: 8),
                  Text(
                    'Category: ${item.category.trim().isEmpty ? 'General' : item.category}',
                  ),
                  const SizedBox(height: 8),
                  Text('Services: $serviceText'),
                  const SizedBox(height: 8),
                  Text(
                    'Location: ${item.location.trim().isEmpty ? '-' : item.location}',
                  ),
                  const SizedBox(height: 8),
                  Text('Status: ${_prettyStatus(item.status)}'),
                  const SizedBox(height: 8),
                  Text('Created: ${_formatDateTime(item.createdAt)}'),
                  const SizedBox(height: 12),
                  const Text(
                    'Description',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(details),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showKycDocuments(AdminUserRow item) async {
    if (item.providerKycIdFrontUrl.trim().isEmpty &&
        item.providerKycIdBackUrl.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No KYC documents uploaded yet.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('KYC Documents • ${item.name}'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Pill(
                        text: _prettyKycStatus(item.providerKycStatus),
                        color: _kycStatusColor(item.providerKycStatus),
                      ),
                      _Pill(
                        text: item.providerSubscriptionTier.isEmpty
                            ? 'Basic'
                            : _titleCase(item.providerSubscriptionTier),
                        color: _planColor(item.providerSubscriptionTier),
                      ),
                      if (item.providerKycSubmittedAt != null)
                        _Pill(
                          text:
                              'Submitted ${_formatDateTime(item.providerKycSubmittedAt)}',
                          color: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _KycImagePanel(
                    title: 'Front of ID',
                    imageUrl: item.providerKycIdFrontUrl,
                  ),
                  const SizedBox(height: 16),
                  _KycImagePanel(
                    title: 'Back of ID',
                    imageUrl: item.providerKycIdBackUrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
    Timer? pollTimer;
    await _runAuthed(
      () => AdminDashboardState.refreshTicketMessages(
        userUid: uid,
        ticketId: ticketId,
        page: 1,
      ),
    );
    if (!mounted) {
      inputController.dispose();
      return;
    }
    pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (paging || sending) return;
      try {
        await _runAuthed(
          () => AdminDashboardState.refreshTicketMessages(
            userUid: uid,
            ticketId: ticketId,
            page: currentPage,
          ),
        );
      } catch (_) {
        // Keep dialog stable if a background poll fails.
      }
    });
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
                                            .value &&
                                        messages.isNotEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(bottom: 8),
                                        child: LinearProgressIndicator(
                                          minHeight: 2,
                                        ),
                                      ),
                                    Expanded(
                                      child:
                                          AdminDashboardState
                                                  .loadingTicketMessages
                                                  .value &&
                                              messages.isEmpty
                                          ? const Center(
                                              child: _AdminLoadingPanel(
                                                title:
                                                    'Loading ticket messages',
                                                message:
                                                    'Syncing conversation with the user.',
                                              ),
                                            )
                                          : messages.isEmpty
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
                                                final isAutoReply =
                                                    message.type
                                                        .toLowerCase() ==
                                                    'auto_reply';
                                                return Align(
                                                  alignment: isAutoReply
                                                      ? Alignment.centerLeft
                                                      : (fromAdmin
                                                            ? Alignment
                                                                  .centerRight
                                                            : Alignment
                                                                  .centerLeft),
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
                                                      color: isAutoReply
                                                          ? const Color(
                                                              0xFFF7FAFF,
                                                            )
                                                          : (fromAdmin
                                                                ? AppColors
                                                                      .primary
                                                                      .withValues(
                                                                        alpha:
                                                                            0.14,
                                                                      )
                                                                : Colors.white),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                      border: Border.all(
                                                        color: isAutoReply
                                                            ? const Color(
                                                                0xFFBFDBFE,
                                                              )
                                                            : (fromAdmin
                                                                  ? AppColors
                                                                        .primary
                                                                        .withValues(
                                                                          alpha:
                                                                              0.28,
                                                                        )
                                                                  : const Color(
                                                                      0xFFD6DEED,
                                                                    )),
                                                      ),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          isAutoReply
                                                              ? 'Support assistant'
                                                              : message
                                                                    .senderName,
                                                          style: TextStyle(
                                                            color: isAutoReply
                                                                ? AppColors
                                                                      .primary
                                                                : (fromAdmin
                                                                      ? AppColors
                                                                            .primaryDark
                                                                      : AppColors
                                                                            .textSecondary),
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
                                                            height: 1.4,
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ticketQuickReplies(ticket)
                          .map(
                            (reply) => ActionChip(
                              label: Text(reply),
                              onPressed: sending
                                  ? null
                                  : () {
                                      inputController.text = reply;
                                      inputController.selection =
                                          TextSelection.fromPosition(
                                            TextPosition(
                                              offset:
                                                  inputController.text.length,
                                            ),
                                          );
                                      setDialogState(() {});
                                    },
                            ),
                          )
                          .toList(growable: false),
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
    pollTimer.cancel();
    inputController.dispose();
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
            child: ScrollConfiguration(
              behavior: const _AdminScrollBehavior(),
              child: ListView(
                primary: true,
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
                        '${_section.name}_${_searchQuery.trim()}-$_userRoleFilter-$_userKycFilter-$_userPlanFilter-$_subscriptionPlanFilter-$_subscriptionStatusFilter-$_orderStatusFilter-$_postTypeFilter-$_ticketStatusFilter-$_serviceStateFilter-$_promotionPlacementFilter-$_promotionTargetTypeFilter-$_promotionStatusFilter-$_broadcastTypeFilter-$_broadcastStatusFilter-$_broadcastRoleFilter-$_undoHistoryStateFilter',
                      ),
                      child: _buildActiveSection(),
                    ),
                  ),
                ],
              ),
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
      case _AdminSection.kyc:
        if (_userKycFilter != 'all') {
          values.add('KYC: ${_prettyKycStatus(_userKycFilter)}');
        }
        if (_userPlanFilter != 'all') {
          values.add('Plan: ${_titleCase(_userPlanFilter)}');
        }
        break;
      case _AdminSection.subscriptions:
        if (_subscriptionPlanFilter != 'all') {
          values.add('Plan: ${_titleCase(_subscriptionPlanFilter)}');
        }
        if (_subscriptionStatusFilter != 'all') {
          values.add(
            'Billing: ${_prettySubscriptionStatus(_subscriptionStatusFilter)}',
          );
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
        if (_ticketCategoryFilter != 'all') {
          values.add(
            'Category: ${supportTicketCategoryLabel(_ticketCategoryFilter)}',
          );
        }
        break;
      case _AdminSection.services:
        if (_serviceStateFilter != 'all') {
          values.add(
            'State: ${_serviceStateFilter == 'active' ? 'Active' : 'Inactive'}',
          );
        }
        break;
      case _AdminSection.promotions:
        if (_promotionPlacementFilter != 'all') {
          values.add('Placement: ${_prettyStatus(_promotionPlacementFilter)}');
        }
        if (_promotionTargetTypeFilter != 'all') {
          values.add('Target: ${_prettyStatus(_promotionTargetTypeFilter)}');
        }
        if (_promotionStatusFilter != 'all') {
          values.add('Status: ${_prettyStatus(_promotionStatusFilter)}');
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
      _userKycFilter = 'all';
      _userPlanFilter = 'all';
      _subscriptionPlanFilter = 'all';
      _subscriptionStatusFilter = 'all';
      _orderStatusFilter = 'all';
      _postTypeFilter = 'all';
      _ticketStatusFilter = 'all';
      _ticketCategoryFilter = 'all';
      _serviceStateFilter = 'all';
      _promotionPlacementFilter = 'finder_home';
      _promotionTargetTypeFilter = 'all';
      _promotionStatusFilter = 'all';
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
      case _AdminSection.kyc:
        return _buildKycSection();
      case _AdminSection.subscriptions:
        return _buildSubscriptionsSection();
      case _AdminSection.orders:
        return _buildOrdersSection();
      case _AdminSection.posts:
        return _buildPostsSection();
      case _AdminSection.tickets:
        return _buildTicketsSection();
      case _AdminSection.services:
        return _buildServicesSection();
      case _AdminSection.promotions:
        return _buildPromotionsSection();
      case _AdminSection.broadcasts:
        return _buildBroadcastsSection();
    }
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
