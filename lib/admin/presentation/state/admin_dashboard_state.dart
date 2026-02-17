import 'package:flutter/foundation.dart';

import '../../../core/config/app_env.dart';
import '../../data/datasources/admin_remote_data_source.dart';
import '../../data/network/admin_api_client.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/admin_models.dart';
import '../../domain/repositories/admin_repository.dart';

class AdminDashboardState {
  static const int pageSize = 10;

  static final AdminRepository _repository = AdminRepositoryImpl(
    AdminRemoteDataSource(
      AdminApiClient(
        baseUrl: AppEnv.apiBaseUrl(),
        bearerToken: AppEnv.apiAuthToken(),
      ),
    ),
  );

  static final ValueNotifier<bool> loadingOverview = ValueNotifier(false);
  static final ValueNotifier<bool> loadingUsers = ValueNotifier(false);
  static final ValueNotifier<bool> loadingOrders = ValueNotifier(false);
  static final ValueNotifier<bool> loadingPosts = ValueNotifier(false);
  static final ValueNotifier<bool> loadingTickets = ValueNotifier(false);
  static final ValueNotifier<bool> loadingServices = ValueNotifier(false);
  static final ValueNotifier<bool> loadingReadBudget = ValueNotifier(false);
  static final ValueNotifier<bool> loadingAnalytics = ValueNotifier(false);
  static final ValueNotifier<bool> loadingGlobalSearch = ValueNotifier(false);
  static final ValueNotifier<bool> loadingUndoHistory = ValueNotifier(false);

  static final ValueNotifier<AdminOverview> overview = ValueNotifier(
    const AdminOverview.empty(),
  );
  static final ValueNotifier<AdminReadBudget> readBudget = ValueNotifier(
    const AdminReadBudget.empty(),
  );
  static final ValueNotifier<AdminAnalytics> analytics = ValueNotifier(
    const AdminAnalytics.empty(),
  );
  static final ValueNotifier<AdminGlobalSearchResult> globalSearch =
      ValueNotifier(const AdminGlobalSearchResult.empty());

  static final ValueNotifier<List<AdminUserRow>> users = ValueNotifier(
    const <AdminUserRow>[],
  );
  static final ValueNotifier<List<AdminOrderRow>> orders = ValueNotifier(
    const <AdminOrderRow>[],
  );
  static final ValueNotifier<List<AdminPostRow>> posts = ValueNotifier(
    const <AdminPostRow>[],
  );
  static final ValueNotifier<List<AdminTicketRow>> tickets = ValueNotifier(
    const <AdminTicketRow>[],
  );
  static final ValueNotifier<List<AdminServiceRow>> services = ValueNotifier(
    const <AdminServiceRow>[],
  );
  static final ValueNotifier<List<AdminUndoHistoryRow>> undoHistory =
      ValueNotifier(const <AdminUndoHistoryRow>[]);

  static final ValueNotifier<AdminPagination> usersPagination = ValueNotifier(
    const AdminPagination.initial(limit: pageSize),
  );
  static final ValueNotifier<AdminPagination> ordersPagination = ValueNotifier(
    const AdminPagination.initial(limit: pageSize),
  );
  static final ValueNotifier<AdminPagination> postsPagination = ValueNotifier(
    const AdminPagination.initial(limit: pageSize),
  );
  static final ValueNotifier<AdminPagination> ticketsPagination = ValueNotifier(
    const AdminPagination.initial(limit: pageSize),
  );
  static final ValueNotifier<AdminPagination> servicesPagination =
      ValueNotifier(const AdminPagination.initial(limit: pageSize));
  static final ValueNotifier<AdminPagination> undoHistoryPagination =
      ValueNotifier(const AdminPagination.initial(limit: pageSize));

  static void setBackendToken(String token) {
    _repository.setBearerToken(token);
    if (token.trim().isEmpty) {
      clear();
    }
  }

  static void clear() {
    overview.value = const AdminOverview.empty();
    readBudget.value = const AdminReadBudget.empty();
    analytics.value = const AdminAnalytics.empty();
    globalSearch.value = const AdminGlobalSearchResult.empty();

    users.value = const <AdminUserRow>[];
    orders.value = const <AdminOrderRow>[];
    posts.value = const <AdminPostRow>[];
    tickets.value = const <AdminTicketRow>[];
    services.value = const <AdminServiceRow>[];
    undoHistory.value = const <AdminUndoHistoryRow>[];

    usersPagination.value = const AdminPagination.initial(limit: pageSize);
    ordersPagination.value = const AdminPagination.initial(limit: pageSize);
    postsPagination.value = const AdminPagination.initial(limit: pageSize);
    ticketsPagination.value = const AdminPagination.initial(limit: pageSize);
    servicesPagination.value = const AdminPagination.initial(limit: pageSize);
    undoHistoryPagination.value = const AdminPagination.initial(
      limit: pageSize,
    );
  }

  static Future<bool> verifyAccess() => _repository.verifyAccess();

  static Future<void> refreshOverview() async {
    loadingOverview.value = true;
    try {
      overview.value = await _repository.fetchOverview();
    } finally {
      loadingOverview.value = false;
    }
  }

  static Future<void> refreshReadBudget() async {
    loadingReadBudget.value = true;
    try {
      readBudget.value = await _repository.fetchReadBudget();
    } finally {
      loadingReadBudget.value = false;
    }
  }

  static Future<void> refreshAnalytics({
    int days = 14,
    int compareDays = 14,
  }) async {
    loadingAnalytics.value = true;
    try {
      analytics.value = await _repository.fetchAnalytics(
        days: days,
        compareDays: compareDays,
      );
    } finally {
      loadingAnalytics.value = false;
    }
  }

  static Future<void> runGlobalSearch({
    required String query,
    int limit = 5,
  }) async {
    final safeQuery = query.trim();
    if (safeQuery.length < 2) {
      globalSearch.value = const AdminGlobalSearchResult.empty();
      return;
    }
    loadingGlobalSearch.value = true;
    try {
      globalSearch.value = await _repository.globalSearch(
        query: safeQuery,
        limit: limit,
      );
    } finally {
      loadingGlobalSearch.value = false;
    }
  }

  static Future<void> refreshUsers({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String role = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingUsers.value = true;
    try {
      final result = await _repository.fetchUsers(
        page: safePage,
        limit: limit,
        query: query,
        role: role,
      );
      users.value = result.items;
      usersPagination.value = result.pagination;
    } finally {
      loadingUsers.value = false;
    }
  }

  static Future<void> refreshOrders({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String status = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingOrders.value = true;
    try {
      final result = await _repository.fetchOrders(
        page: safePage,
        limit: limit,
        query: query,
        status: status,
      );
      orders.value = result.items;
      ordersPagination.value = result.pagination;
    } finally {
      loadingOrders.value = false;
    }
  }

  static Future<void> refreshPosts({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String type = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingPosts.value = true;
    try {
      final result = await _repository.fetchPosts(
        page: safePage,
        limit: limit,
        query: query,
        type: type,
      );
      posts.value = result.items;
      postsPagination.value = result.pagination;
    } finally {
      loadingPosts.value = false;
    }
  }

  static Future<void> refreshTickets({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String status = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingTickets.value = true;
    try {
      final result = await _repository.fetchTickets(
        page: safePage,
        limit: limit,
        query: query,
        status: status,
      );
      tickets.value = result.items;
      ticketsPagination.value = result.pagination;
    } finally {
      loadingTickets.value = false;
    }
  }

  static Future<void> refreshServices({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String active = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingServices.value = true;
    try {
      final result = await _repository.fetchServices(
        page: safePage,
        limit: limit,
        query: query,
        active: active,
      );
      services.value = result.items;
      servicesPagination.value = result.pagination;
    } finally {
      loadingServices.value = false;
    }
  }

  static Future<void> refreshUndoHistory({
    int page = 1,
    int limit = pageSize,
    String query = '',
    String state = '',
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingUndoHistory.value = true;
    try {
      final result = await _repository.fetchUndoHistory(
        page: safePage,
        limit: limit,
        query: query,
        state: state,
      );
      undoHistory.value = result.items;
      undoHistoryPagination.value = result.pagination;
    } finally {
      loadingUndoHistory.value = false;
    }
  }

  static Future<AdminActionResult> updateUserStatus({
    required String userId,
    required bool active,
    required String reason,
  }) {
    return _repository.updateUserStatus(
      userId: userId,
      active: active,
      reason: reason,
    );
  }

  static Future<AdminActionResult> updateOrderStatus({
    required String orderId,
    required String status,
    required String reason,
  }) {
    return _repository.updateOrderStatus(
      orderId: orderId,
      status: status,
      reason: reason,
    );
  }

  static Future<AdminActionResult> updatePostStatus({
    required String sourceCollection,
    required String postId,
    required String status,
    required String reason,
  }) {
    return _repository.updatePostStatus(
      sourceCollection: sourceCollection,
      postId: postId,
      status: status,
      reason: reason,
    );
  }

  static Future<AdminActionResult> updateTicketStatus({
    required String userUid,
    required String ticketId,
    required String status,
    required String reason,
  }) {
    return _repository.updateTicketStatus(
      userUid: userUid,
      ticketId: ticketId,
      status: status,
      reason: reason,
    );
  }

  static Future<AdminActionResult> updateServiceActive({
    required String serviceId,
    required bool active,
    required String reason,
  }) {
    return _repository.updateServiceActive(
      serviceId: serviceId,
      active: active,
      reason: reason,
    );
  }

  static Future<void> undoAction({required String undoToken}) {
    return _repository.undoAction(undoToken: undoToken);
  }
}
