class AdminPagination {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasPrevPage;
  final bool hasNextPage;

  const AdminPagination({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevPage,
    required this.hasNextPage,
  });

  const AdminPagination.initial({this.limit = 10})
    : page = 1,
      totalItems = 0,
      totalPages = 0,
      hasPrevPage = false,
      hasNextPage = false;

  factory AdminPagination.fromMap(
    Map<String, dynamic> row, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
    int fallbackTotalItems = 0,
  }) {
    final page = _AdminParser.parseInt(
      row['page'],
      fallbackPage,
    ).clamp(1, 999999);
    final limit = _AdminParser.parseInt(
      row['limit'],
      fallbackLimit,
    ).clamp(1, 999999);
    final totalItems = _AdminParser.parseInt(
      row['totalItems'],
      fallbackTotalItems,
    ).clamp(0, 99999999);
    final totalPages = _AdminParser.parseInt(
      row['totalPages'],
      totalItems == 0 ? 0 : ((totalItems + limit - 1) ~/ limit),
    ).clamp(0, 999999);

    return AdminPagination(
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasPrevPage: _AdminParser.parseBool(
        row['hasPrevPage'],
        totalPages > 0 && page > 1,
      ),
      hasNextPage: _AdminParser.parseBool(
        row['hasNextPage'],
        totalPages > 0 && page < totalPages,
      ),
    );
  }
}

class AdminOverview {
  final DateTime? generatedAt;
  final Map<String, num> kpis;
  final Map<String, int> orderStatus;
  final List<AdminRecentOrderRow> recentOrders;
  final List<AdminRecentUserRow> recentUsers;
  final List<AdminRecentPostRow> recentPosts;

  const AdminOverview({
    required this.generatedAt,
    required this.kpis,
    required this.orderStatus,
    required this.recentOrders,
    required this.recentUsers,
    required this.recentPosts,
  });

  const AdminOverview.empty()
    : generatedAt = null,
      kpis = const <String, num>{},
      orderStatus = const <String, int>{},
      recentOrders = const <AdminRecentOrderRow>[],
      recentUsers = const <AdminRecentUserRow>[],
      recentPosts = const <AdminRecentPostRow>[];

  factory AdminOverview.fromMap(Map<String, dynamic> row) {
    return AdminOverview(
      generatedAt: _AdminParser.parseDate(row['generatedAt']),
      kpis: _AdminParser.parseNumMap(row['kpis']),
      orderStatus: _AdminParser.parseIntMap(row['orderStatus']),
      recentOrders: _AdminParser.parseMapList(
        row['recentOrders'],
      ).map(AdminRecentOrderRow.fromMap).toList(growable: false),
      recentUsers: _AdminParser.parseMapList(
        row['recentUsers'],
      ).map(AdminRecentUserRow.fromMap).toList(growable: false),
      recentPosts: _AdminParser.parseMapList(
        row['recentPosts'],
      ).map(AdminRecentPostRow.fromMap).toList(growable: false),
    );
  }
}

class AdminRecentOrderRow {
  final String id;
  final String finderName;
  final String providerName;
  final String serviceName;
  final String status;
  final double total;
  final DateTime? createdAt;

  const AdminRecentOrderRow({
    required this.id,
    required this.finderName,
    required this.providerName,
    required this.serviceName,
    required this.status,
    required this.total,
    required this.createdAt,
  });

  factory AdminRecentOrderRow.fromMap(Map<String, dynamic> row) {
    return AdminRecentOrderRow(
      id: _AdminParser.text(row['id']),
      finderName: _AdminParser.text(row['finderName'], fallback: 'Finder'),
      providerName: _AdminParser.text(
        row['providerName'],
        fallback: 'Provider',
      ),
      serviceName: _AdminParser.text(row['serviceName'], fallback: 'Service'),
      status: _AdminParser.text(row['status'], fallback: 'booked'),
      total: _AdminParser.parseDouble(row['total']),
      createdAt: _AdminParser.parseDate(row['createdAt']),
    );
  }
}

class AdminRecentUserRow {
  final String id;
  final String name;
  final String email;
  final String role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminRecentUserRow({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminRecentUserRow.fromMap(Map<String, dynamic> row) {
    return AdminRecentUserRow(
      id: _AdminParser.text(row['id']),
      name: _AdminParser.text(row['name'], fallback: 'Unnamed User'),
      email: _AdminParser.text(row['email']),
      role: _AdminParser.text(row['role'], fallback: 'user'),
      createdAt: _AdminParser.parseDate(row['createdAt']),
      updatedAt: _AdminParser.parseDate(row['updatedAt']),
    );
  }
}

class AdminRecentPostRow {
  final String id;
  final String type;
  final String ownerName;
  final String category;
  final String service;
  final String status;
  final DateTime? createdAt;

  const AdminRecentPostRow({
    required this.id,
    required this.type,
    required this.ownerName,
    required this.category,
    required this.service,
    required this.status,
    required this.createdAt,
  });

  factory AdminRecentPostRow.fromMap(Map<String, dynamic> row) {
    return AdminRecentPostRow(
      id: _AdminParser.text(row['id']),
      type: _AdminParser.text(row['type'], fallback: 'provider_offer'),
      ownerName: _AdminParser.text(row['ownerName'], fallback: 'User'),
      category: _AdminParser.text(row['category']),
      service: _AdminParser.text(row['service']),
      status: _AdminParser.text(row['status'], fallback: 'open'),
      createdAt: _AdminParser.parseDate(row['createdAt']),
    );
  }
}

class AdminUserRow {
  final String id;
  final String name;
  final String email;
  final String role;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserRow({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.active,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUserRow.fromMap(Map<String, dynamic> row) {
    return AdminUserRow(
      id: _AdminParser.text(row['id']),
      name: _AdminParser.text(row['name'], fallback: 'Unnamed User'),
      email: _AdminParser.text(row['email']),
      role: _AdminParser.text(row['role'], fallback: 'user'),
      active: _AdminParser.parseBool(row['active'], true),
      createdAt: _AdminParser.parseDate(row['createdAt']),
      updatedAt: _AdminParser.parseDate(row['updatedAt']),
    );
  }
}

class AdminOrderRow {
  final String id;
  final String serviceName;
  final String finderName;
  final String providerName;
  final String status;
  final double total;
  final String paymentMethod;
  final String paymentStatus;
  final DateTime? createdAt;

  const AdminOrderRow({
    required this.id,
    required this.serviceName,
    required this.finderName,
    required this.providerName,
    required this.status,
    required this.total,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory AdminOrderRow.fromMap(Map<String, dynamic> row) {
    return AdminOrderRow(
      id: _AdminParser.text(row['id']),
      serviceName: _AdminParser.text(row['serviceName'], fallback: 'Service'),
      finderName: _AdminParser.text(row['finderName'], fallback: 'Finder'),
      providerName: _AdminParser.text(
        row['providerName'],
        fallback: 'Provider',
      ),
      status: _AdminParser.text(row['status'], fallback: 'booked'),
      total: _AdminParser.parseDouble(row['total']),
      paymentMethod: _AdminParser.text(row['paymentMethod']),
      paymentStatus: _AdminParser.text(row['paymentStatus']),
      createdAt: _AdminParser.parseDate(row['createdAt']),
    );
  }
}

class AdminPostRow {
  final String id;
  final String sourceCollection;
  final String type;
  final String ownerName;
  final String category;
  final String service;
  final String location;
  final String status;
  final DateTime? createdAt;

  const AdminPostRow({
    required this.id,
    required this.sourceCollection,
    required this.type,
    required this.ownerName,
    required this.category,
    required this.service,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory AdminPostRow.fromMap(Map<String, dynamic> row) {
    final type = _AdminParser.text(row['type'], fallback: 'provider_offer');
    return AdminPostRow(
      id: _AdminParser.text(row['id']),
      sourceCollection: _AdminParser.text(
        row['sourceCollection'],
        fallback: type == 'finder_request' ? 'finderPosts' : 'providerPosts',
      ),
      type: type,
      ownerName: _AdminParser.text(row['ownerName'], fallback: 'User'),
      category: _AdminParser.text(row['category']),
      service: _AdminParser.text(row['service']),
      location: _AdminParser.text(row['location']),
      status: _AdminParser.text(row['status'], fallback: 'open'),
      createdAt: _AdminParser.parseDate(row['createdAt']),
    );
  }
}

class AdminReadBudget {
  final String dateKey;
  final int dailyBudget;
  final int estimatedReadsUsed;
  final int estimatedReadsRemaining;
  final double usedPercent;
  final String level;

  const AdminReadBudget({
    required this.dateKey,
    required this.dailyBudget,
    required this.estimatedReadsUsed,
    required this.estimatedReadsRemaining,
    required this.usedPercent,
    required this.level,
  });

  const AdminReadBudget.empty()
    : dateKey = '',
      dailyBudget = 50000,
      estimatedReadsUsed = 0,
      estimatedReadsRemaining = 50000,
      usedPercent = 0,
      level = 'healthy';

  factory AdminReadBudget.fromMap(Map<String, dynamic> row) {
    return AdminReadBudget(
      dateKey: _AdminParser.text(row['dateKey']),
      dailyBudget: _AdminParser.parseInt(row['dailyBudget'], 50000),
      estimatedReadsUsed: _AdminParser.parseInt(row['estimatedReadsUsed'], 0),
      estimatedReadsRemaining: _AdminParser.parseInt(
        row['estimatedReadsRemaining'],
        50000,
      ),
      usedPercent: _AdminParser.parseDouble(row['usedPercent']),
      level: _AdminParser.text(row['level'], fallback: 'healthy'),
    );
  }
}

class AdminGlobalSearchResult {
  final String query;
  final int total;
  final List<AdminSearchGroup> groups;

  const AdminGlobalSearchResult({
    required this.query,
    required this.total,
    required this.groups,
  });

  const AdminGlobalSearchResult.empty()
    : query = '',
      total = 0,
      groups = const <AdminSearchGroup>[];

  factory AdminGlobalSearchResult.fromMap(Map<String, dynamic> row) {
    return AdminGlobalSearchResult(
      query: _AdminParser.text(row['query']),
      total: _AdminParser.parseInt(row['total'], 0),
      groups: _AdminParser.parseMapList(
        row['groups'],
      ).map(AdminSearchGroup.fromMap).toList(growable: false),
    );
  }
}

class AdminSearchGroup {
  final String section;
  final String label;
  final List<AdminSearchItem> items;

  const AdminSearchGroup({
    required this.section,
    required this.label,
    required this.items,
  });

  factory AdminSearchGroup.fromMap(Map<String, dynamic> row) {
    return AdminSearchGroup(
      section: _AdminParser.text(row['section']),
      label: _AdminParser.text(row['label']),
      items: _AdminParser.parseMapList(
        row['items'],
      ).map(AdminSearchItem.fromMap).toList(growable: false),
    );
  }
}

class AdminSearchItem {
  final String id;
  final String section;
  final String title;
  final String subtitle;

  const AdminSearchItem({
    required this.id,
    required this.section,
    required this.title,
    required this.subtitle,
  });

  factory AdminSearchItem.fromMap(Map<String, dynamic> row) {
    return AdminSearchItem(
      id: _AdminParser.text(row['id']),
      section: _AdminParser.text(row['section']),
      title: _AdminParser.text(row['title'], fallback: 'Result'),
      subtitle: _AdminParser.text(row['subtitle']),
    );
  }
}

class AdminAnalytics {
  final int currentDays;
  final int compareDays;
  final AdminAnalyticsTotals current;
  final AdminAnalyticsTotals previous;
  final Map<String, double> deltaPercent;
  final AdminAnalyticsFunnel funnel;
  final List<AdminAnalyticsSeriesPoint> currentSeries;
  final List<AdminAnalyticsSeriesPoint> previousSeries;
  final List<AdminTopService> topServices;

  const AdminAnalytics({
    required this.currentDays,
    required this.compareDays,
    required this.current,
    required this.previous,
    required this.deltaPercent,
    required this.funnel,
    required this.currentSeries,
    required this.previousSeries,
    required this.topServices,
  });

  const AdminAnalytics.empty()
    : currentDays = 14,
      compareDays = 14,
      current = const AdminAnalyticsTotals.empty(),
      previous = const AdminAnalyticsTotals.empty(),
      deltaPercent = const <String, double>{},
      funnel = const AdminAnalyticsFunnel.empty(),
      currentSeries = const <AdminAnalyticsSeriesPoint>[],
      previousSeries = const <AdminAnalyticsSeriesPoint>[],
      topServices = const <AdminTopService>[];

  factory AdminAnalytics.fromMap(Map<String, dynamic> row) {
    final range = _AdminParser.safeMap(row['range']);
    final totals = _AdminParser.safeMap(row['totals']);
    final trend = _AdminParser.safeMap(row['trend']);
    final deltaRaw = totals['deltaPercent'];
    final deltaPercent = <String, double>{};
    if (deltaRaw is Map) {
      for (final entry in deltaRaw.entries) {
        deltaPercent[entry.key.toString()] = _AdminParser.parseDouble(
          entry.value,
        );
      }
    }
    return AdminAnalytics(
      currentDays: _AdminParser.parseInt(range['currentDays'], 14),
      compareDays: _AdminParser.parseInt(range['compareDays'], 14),
      current: AdminAnalyticsTotals.fromMap(
        _AdminParser.safeMap(totals['current']),
      ),
      previous: AdminAnalyticsTotals.fromMap(
        _AdminParser.safeMap(totals['previous']),
      ),
      deltaPercent: deltaPercent,
      funnel: AdminAnalyticsFunnel.fromMap(_AdminParser.safeMap(row['funnel'])),
      currentSeries: _AdminParser.parseMapList(
        trend['currentSeries'],
      ).map(AdminAnalyticsSeriesPoint.fromMap).toList(growable: false),
      previousSeries: _AdminParser.parseMapList(
        trend['previousSeries'],
      ).map(AdminAnalyticsSeriesPoint.fromMap).toList(growable: false),
      topServices: _AdminParser.parseMapList(
        row['topServices'],
      ).map(AdminTopService.fromMap).toList(growable: false),
    );
  }
}

class AdminAnalyticsTotals {
  final int orders;
  final int completedOrders;
  final int cancelledOrders;
  final double revenue;

  const AdminAnalyticsTotals({
    required this.orders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.revenue,
  });

  const AdminAnalyticsTotals.empty()
    : orders = 0,
      completedOrders = 0,
      cancelledOrders = 0,
      revenue = 0;

  factory AdminAnalyticsTotals.fromMap(Map<String, dynamic> row) {
    return AdminAnalyticsTotals(
      orders: _AdminParser.parseInt(row['orders'], 0),
      completedOrders: _AdminParser.parseInt(row['completedOrders'], 0),
      cancelledOrders: _AdminParser.parseInt(row['cancelledOrders'], 0),
      revenue: _AdminParser.parseDouble(row['revenue']),
    );
  }
}

class AdminAnalyticsFunnel {
  final int postIntents;
  final int activeChats;
  final int bookedOrders;
  final int completedOrders;

  const AdminAnalyticsFunnel({
    required this.postIntents,
    required this.activeChats,
    required this.bookedOrders,
    required this.completedOrders,
  });

  const AdminAnalyticsFunnel.empty()
    : postIntents = 0,
      activeChats = 0,
      bookedOrders = 0,
      completedOrders = 0;

  factory AdminAnalyticsFunnel.fromMap(Map<String, dynamic> row) {
    return AdminAnalyticsFunnel(
      postIntents: _AdminParser.parseInt(row['postIntents'], 0),
      activeChats: _AdminParser.parseInt(row['activeChats'], 0),
      bookedOrders: _AdminParser.parseInt(row['bookedOrders'], 0),
      completedOrders: _AdminParser.parseInt(row['completedOrders'], 0),
    );
  }
}

class AdminAnalyticsSeriesPoint {
  final String date;
  final int orders;
  final double revenue;

  const AdminAnalyticsSeriesPoint({
    required this.date,
    required this.orders,
    required this.revenue,
  });

  factory AdminAnalyticsSeriesPoint.fromMap(Map<String, dynamic> row) {
    return AdminAnalyticsSeriesPoint(
      date: _AdminParser.text(row['date']),
      orders: _AdminParser.parseInt(row['orders'], 0),
      revenue: _AdminParser.parseDouble(row['revenue']),
    );
  }
}

class AdminTopService {
  final String serviceName;
  final int completedOrders;
  final double revenue;

  const AdminTopService({
    required this.serviceName,
    required this.completedOrders,
    required this.revenue,
  });

  factory AdminTopService.fromMap(Map<String, dynamic> row) {
    return AdminTopService(
      serviceName: _AdminParser.text(row['serviceName'], fallback: 'Service'),
      completedOrders: _AdminParser.parseInt(row['completedOrders'], 0),
      revenue: _AdminParser.parseDouble(row['revenue']),
    );
  }
}

class AdminActionResult {
  final String id;
  final String reason;
  final String undoToken;
  final DateTime? undoExpiresAt;

  const AdminActionResult({
    required this.id,
    required this.reason,
    required this.undoToken,
    required this.undoExpiresAt,
  });

  factory AdminActionResult.fromMap(Map<String, dynamic> row) {
    return AdminActionResult(
      id: _AdminParser.text(row['id']),
      reason: _AdminParser.text(row['reason']),
      undoToken: _AdminParser.text(row['undoToken']),
      undoExpiresAt: _AdminParser.parseDate(row['undoExpiresAt']),
    );
  }
}

class AdminUndoHistoryRow {
  final String id;
  final String undoToken;
  final String actionType;
  final String targetLabel;
  final String reason;
  final String docPath;
  final DateTime? createdAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  final String usedBy;
  final String state;
  final bool canUndo;

  const AdminUndoHistoryRow({
    required this.id,
    required this.undoToken,
    required this.actionType,
    required this.targetLabel,
    required this.reason,
    required this.docPath,
    required this.createdAt,
    required this.expiresAt,
    required this.usedAt,
    required this.usedBy,
    required this.state,
    required this.canUndo,
  });

  factory AdminUndoHistoryRow.fromMap(Map<String, dynamic> row) {
    return AdminUndoHistoryRow(
      id: _AdminParser.text(row['id']),
      undoToken: _AdminParser.text(
        row['undoToken'],
        fallback: _AdminParser.text(row['id']),
      ),
      actionType: _AdminParser.text(row['actionType'], fallback: 'action'),
      targetLabel: _AdminParser.text(row['targetLabel']),
      reason: _AdminParser.text(row['reason']),
      docPath: _AdminParser.text(row['docPath']),
      createdAt: _AdminParser.parseDate(row['createdAt']),
      expiresAt: _AdminParser.parseDate(row['expiresAt']),
      usedAt: _AdminParser.parseDate(row['usedAt']),
      usedBy: _AdminParser.text(row['usedBy']),
      state: _AdminParser.text(row['state'], fallback: 'available'),
      canUndo: _AdminParser.parseBool(row['canUndo'], false),
    );
  }
}

class AdminTicketRow {
  final String id;
  final String userUid;
  final String title;
  final String message;
  final String status;
  final DateTime? createdAt;

  const AdminTicketRow({
    required this.id,
    required this.userUid,
    required this.title,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory AdminTicketRow.fromMap(Map<String, dynamic> row) {
    return AdminTicketRow(
      id: _AdminParser.text(row['id']),
      userUid: _AdminParser.text(row['userUid']),
      title: _AdminParser.text(row['title'], fallback: 'Support request'),
      message: _AdminParser.text(row['message']),
      status: _AdminParser.text(row['status'], fallback: 'open'),
      createdAt: _AdminParser.parseDate(row['createdAt']),
    );
  }
}

class AdminServiceRow {
  final String id;
  final String name;
  final String categoryId;
  final String categoryName;
  final bool active;
  final String imageUrl;

  const AdminServiceRow({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryName,
    required this.active,
    required this.imageUrl,
  });

  factory AdminServiceRow.fromMap(Map<String, dynamic> row) {
    return AdminServiceRow(
      id: _AdminParser.text(row['id']),
      name: _AdminParser.text(row['name'], fallback: 'Unnamed Service'),
      categoryId: _AdminParser.text(row['categoryId']),
      categoryName: _AdminParser.text(row['categoryName'], fallback: 'General'),
      active: _AdminParser.parseBool(row['active'], true),
      imageUrl: _AdminParser.text(row['imageUrl']),
    );
  }
}

class AdminPage<T> {
  final List<T> items;
  final AdminPagination pagination;

  const AdminPage({required this.items, required this.pagination});
}

class _AdminParser {
  static String text(dynamic value, {String fallback = ''}) {
    final raw = (value ?? '').toString().trim();
    return raw.isEmpty ? fallback : raw;
  }

  static int parseInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static double parseDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  static bool parseBool(dynamic value, bool fallback) {
    if (value is bool) return value;
    final text = (value ?? '').toString().trim().toLowerCase();
    if (text == 'true') return true;
    if (text == 'false') return false;
    return fallback;
  }

  static DateTime? parseDate(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static Map<String, num> parseNumMap(dynamic value) {
    if (value is! Map) return const <String, num>{};
    final mapped = <String, num>{};
    for (final entry in value.entries) {
      final number = num.tryParse((entry.value ?? '').toString());
      if (number == null) continue;
      mapped[entry.key.toString()] = number;
    }
    return mapped;
  }

  static Map<String, int> parseIntMap(dynamic value) {
    if (value is! Map) return const <String, int>{};
    final mapped = <String, int>{};
    for (final entry in value.entries) {
      final number = int.tryParse((entry.value ?? '').toString());
      if (number == null) continue;
      mapped[entry.key.toString()] = number;
    }
    return mapped;
  }

  static List<Map<String, dynamic>> parseMapList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map(_safeMap).toList(growable: false);
  }

  static Map<String, dynamic> safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return _safeMap(value);
    return const <String, dynamic>{};
  }

  static Map<String, dynamic> _safeMap(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
