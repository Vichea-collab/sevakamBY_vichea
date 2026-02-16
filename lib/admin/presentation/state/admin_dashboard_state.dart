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

  static final ValueNotifier<AdminOverview> overview = ValueNotifier(
    const AdminOverview.empty(),
  );

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

  static void setBackendToken(String token) {
    _repository.setBearerToken(token);
    if (token.trim().isEmpty) {
      clear();
    }
  }

  static void clear() {
    overview.value = const AdminOverview.empty();

    users.value = const <AdminUserRow>[];
    orders.value = const <AdminOrderRow>[];
    posts.value = const <AdminPostRow>[];
    tickets.value = const <AdminTicketRow>[];
    services.value = const <AdminServiceRow>[];

    usersPagination.value = const AdminPagination.initial(limit: pageSize);
    ordersPagination.value = const AdminPagination.initial(limit: pageSize);
    postsPagination.value = const AdminPagination.initial(limit: pageSize);
    ticketsPagination.value = const AdminPagination.initial(limit: pageSize);
    servicesPagination.value = const AdminPagination.initial(limit: pageSize);
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

  static Future<void> refreshUsers({int page = 1, int limit = pageSize}) async {
    final safePage = page < 1 ? 1 : page;
    loadingUsers.value = true;
    try {
      final result = await _repository.fetchUsers(page: safePage, limit: limit);
      users.value = result.items;
      usersPagination.value = result.pagination;
    } finally {
      loadingUsers.value = false;
    }
  }

  static Future<void> refreshOrders({
    int page = 1,
    int limit = pageSize,
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingOrders.value = true;
    try {
      final result = await _repository.fetchOrders(
        page: safePage,
        limit: limit,
      );
      orders.value = result.items;
      ordersPagination.value = result.pagination;
    } finally {
      loadingOrders.value = false;
    }
  }

  static Future<void> refreshPosts({int page = 1, int limit = pageSize}) async {
    final safePage = page < 1 ? 1 : page;
    loadingPosts.value = true;
    try {
      final result = await _repository.fetchPosts(page: safePage, limit: limit);
      posts.value = result.items;
      postsPagination.value = result.pagination;
    } finally {
      loadingPosts.value = false;
    }
  }

  static Future<void> refreshTickets({
    int page = 1,
    int limit = pageSize,
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingTickets.value = true;
    try {
      final result = await _repository.fetchTickets(
        page: safePage,
        limit: limit,
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
  }) async {
    final safePage = page < 1 ? 1 : page;
    loadingServices.value = true;
    try {
      final result = await _repository.fetchServices(
        page: safePage,
        limit: limit,
      );
      services.value = result.items;
      servicesPagination.value = result.pagination;
    } finally {
      loadingServices.value = false;
    }
  }
}
