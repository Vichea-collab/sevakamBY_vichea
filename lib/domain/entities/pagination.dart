class PaginationMeta {
  final int page;
  final int limit;
  final int totalItems;
  final int totalPages;
  final bool hasPrevPage;
  final bool hasNextPage;
  final String nextCursor;

  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.totalItems,
    required this.totalPages,
    required this.hasPrevPage,
    required this.hasNextPage,
    this.nextCursor = '',
  });

  const PaginationMeta.initial({this.limit = 10})
    : page = 1,
      totalItems = 0,
      totalPages = 0,
      hasPrevPage = false,
      hasNextPage = false,
      nextCursor = '';

  factory PaginationMeta.fromMap(
    Map<String, dynamic> row, {
    int fallbackPage = 1,
    int fallbackLimit = 10,
    int fallbackTotalItems = 0,
  }) {
    int parseInt(dynamic value, int fallback) {
      if (value is int) return value;
      final parsed = int.tryParse((value ?? '').toString());
      return parsed ?? fallback;
    }

    bool parseBool(dynamic value, bool fallback) {
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return fallback;
    }

    final page = parseInt(row['page'], fallbackPage).clamp(1, 999999);
    final limit = parseInt(row['limit'], fallbackLimit).clamp(1, 999999);
    final totalItems = parseInt(
      row['totalItems'],
      fallbackTotalItems,
    ).clamp(0, 99999999);
    final totalPages = parseInt(
      row['totalPages'],
      totalItems == 0 ? 0 : ((totalItems + limit - 1) ~/ limit),
    ).clamp(0, 999999);
    return PaginationMeta(
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasPrevPage: parseBool(row['hasPrevPage'], totalPages > 0 && page > 1),
      hasNextPage: parseBool(
        row['hasNextPage'],
        totalPages > 0 && page < totalPages,
      ),
      nextCursor: (row['nextCursor'] ?? '').toString().trim(),
    );
  }
}

class PaginatedResult<T> {
  final List<T> items;
  final PaginationMeta pagination;

  const PaginatedResult({required this.items, required this.pagination});
}
