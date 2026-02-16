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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AdminUserRow({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdminUserRow.fromMap(Map<String, dynamic> row) {
    return AdminUserRow(
      id: _AdminParser.text(row['id']),
      name: _AdminParser.text(row['name'], fallback: 'Unnamed User'),
      email: _AdminParser.text(row['email']),
      role: _AdminParser.text(row['role'], fallback: 'user'),
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
  final String type;
  final String ownerName;
  final String category;
  final String service;
  final String location;
  final String status;
  final DateTime? createdAt;

  const AdminPostRow({
    required this.id,
    required this.type,
    required this.ownerName,
    required this.category,
    required this.service,
    required this.location,
    required this.status,
    required this.createdAt,
  });

  factory AdminPostRow.fromMap(Map<String, dynamic> row) {
    return AdminPostRow(
      id: _AdminParser.text(row['id']),
      type: _AdminParser.text(row['type'], fallback: 'provider_offer'),
      ownerName: _AdminParser.text(row['ownerName'], fallback: 'User'),
      category: _AdminParser.text(row['category']),
      service: _AdminParser.text(row['service']),
      location: _AdminParser.text(row['location']),
      status: _AdminParser.text(row['status'], fallback: 'open'),
      createdAt: _AdminParser.parseDate(row['createdAt']),
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

  static Map<String, dynamic> _safeMap(Map value) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
