import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueNotifier, debugPrint;
import 'package:flutter/services.dart' show rootBundle;

import '../../core/config/app_env.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/service.dart';

class CatalogState {
  static const int _pageSize = 10;
  static const Duration _cacheTtl = Duration(hours: 6);

  static final BackendApiClient _apiClient = BackendApiClient(
    baseUrl: AppEnv.apiBaseUrl(),
    bearerToken: AppEnv.apiAuthToken(),
  );

  static final ValueNotifier<List<Category>> categories = ValueNotifier(
    const <Category>[],
  );
  static final ValueNotifier<List<ServiceItem>> services = ValueNotifier(
    const <ServiceItem>[],
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);

  static bool _initialized = false;
  static DateTime? _lastHydratedAt;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  static Future<void> refresh({bool force = false}) async {
    final isFresh =
        !force &&
        _lastHydratedAt != null &&
        DateTime.now().difference(_lastHydratedAt!) < _cacheTtl &&
        categories.value.isNotEmpty &&
        services.value.isNotEmpty;
    if (isFresh) {
      return;
    }
    loading.value = true;
    try {
      final loadedCategories = await _loadCategories();
      final loadedServices = await _loadServices(loadedCategories);

      if (loadedCategories.isNotEmpty) {
        categories.value = loadedCategories;
      } else {
        categories.value = await _loadCategoriesFromAssets();
      }

      // No fallback for services, only from API
      services.value = loadedServices;

      _lastHydratedAt = DateTime.now();
    } catch (_) {
      categories.value = await _loadCategoriesFromAssets();
      services.value = const <ServiceItem>[];
      _lastHydratedAt = DateTime.now();
    } finally {
      loading.value = false;
    }
  }

  static Future<List<Category>> _loadCategoriesFromAssets() async {
    try {
      final String response = await rootBundle.loadString(
        'assets/data/categories.json',
      );
      final List<dynamic> data = json.decode(response);
      return data
          .map(
            (json) => Category(
              name: json['name'].toString(),
              icon: json['icon'].toString(),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('Error loading categories from assets: $e');
      return const <Category>[];
    }
  }

  static List<String> servicesForCategory(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    if (normalized.isEmpty) return const <String>[];
    return services.value
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .map((item) => item.title)
        .toSet()
        .toList(growable: false);
  }

  static List<ServiceItem> servicesByCategory(String categoryName) {
    final normalized = categoryName.trim().toLowerCase();
    return services.value
        .where((item) => item.category.trim().toLowerCase() == normalized)
        .toList(growable: false);
  }

  static List<ServiceItem> popularServices({int limit = 6}) {
    final sorted = List<ServiceItem>.from(services.value)
      ..sort((a, b) => b.rating.compareTo(a.rating));
    if (limit <= 0 || sorted.length <= limit) return sorted;
    return sorted.take(limit).toList(growable: false);
  }

  static String categoryForProviderRole(String role) {
    final value = role.trim().toLowerCase();
    switch (value) {
      case 'appliance':
        return 'Home Appliance';
      case 'maintenance':
        return 'Home Maintenance';
      default:
        return role.trim().isEmpty ? 'Cleaner' : role.trim();
    }
  }

  static Future<List<Category>> _loadCategories() async {
    try {
      final rows = await _loadAllPagedRows('/api/categories/allCategories');
      if (rows.isEmpty) return const <Category>[];

      final mapped = rows
          .map((raw) {
            final row = raw;
            final name = (row['name'] ?? row['title'] ?? '').toString().trim();
            if (name.isEmpty) return null;
            final iconRaw = (row['icon'] ?? row['iconKey'] ?? '')
                .toString()
                .trim();
            return Category(
              name: name,
              icon: iconRaw.isEmpty ? _iconKeyForCategory(name) : iconRaw,
            );
          })
          .whereType<Category>()
          .toList(growable: false);

      return mapped;
    } catch (_) {
      return const <Category>[];
    }
  }

  static Future<List<ServiceItem>> _loadServices(
    List<Category> loadedCategories,
  ) async {
    try {
      final rows = await _loadAllPagedRows('/api/services');
      if (rows.isEmpty) return const <ServiceItem>[];

      final categoriesById = <String, Category>{};
      for (final category in loadedCategories) {
        categoriesById[_idKey(category.name)] = category;
      }

      final mapped = rows
          .map((raw) {
            final row = raw;
            final title =
                (row['name'] ?? row['serviceName'] ?? row['title'] ?? '')
                    .toString()
                    .trim();
            if (title.isEmpty) return null;

            final categoryName = _resolveCategoryName(row, categoriesById);
            final rate = _toDouble(
              row['pricePerHour'] ?? row['ratePerHour'] ?? row['price'],
              fallback: 12,
            );
            final completedCount = _toInt(row['completedCount'], fallback: 0);
            final rating = _toDouble(row['rating'], fallback: 4.6);
            final available = row['available'] != false;
            final badge = completedCount >= 80
                ? 'Popular'
                : completedCount >= 40
                ? 'Trusted'
                : 'Pro';

            final imageFromApi = (row['image'] ?? row['imageUrl'] ?? '')
                .toString();

            return ServiceItem(
              title: title,
              subtitle: 'Starts in \$${rate.toStringAsFixed(0)}/hr',
              badge: badge,
              imagePath: imageFromApi.isNotEmpty
                  ? imageFromApi
                  : _imageForCategory(categoryName),
              rating: rating,
              category: categoryName,
              location: 'Phnom Penh, Cambodia',
              available: available,
              etaHours: _etaHoursFromCategory(categoryName),
            );
          })
          .whereType<ServiceItem>()
          .toList(growable: false);

      return mapped;
    } catch (_) {
      return const <ServiceItem>[];
    }
  }

  static Future<List<Map<String, dynamic>>> _loadAllPagedRows(
    String path,
  ) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    while (page <= 200) {
      final response = await _apiClient.getJson(
        '$path?page=$page&limit=$_pageSize',
      );
      final pageRows = _safeList(response['data']);
      rows.addAll(pageRows);
      final pagination = PaginationMeta.fromMap(
        _safeMap(response['pagination']),
        fallbackPage: page,
        fallbackLimit: _pageSize,
        fallbackTotalItems: rows.length,
      );
      if (!pagination.hasNextPage) break;
      page += 1;
    }
    return rows;
  }

  static String _resolveCategoryName(
    Map<String, dynamic> row,
    Map<String, Category> categoriesById,
  ) {
    final explicit = (row['categoryName'] ?? row['category'] ?? '')
        .toString()
        .trim();
    if (explicit.isNotEmpty) return explicit;

    final categoryId = (row['categoryId'] ?? '').toString().trim();
    if (categoryId.isNotEmpty && categoriesById.containsKey(categoryId)) {
      return categoriesById[categoryId]!.name;
    }
    return 'General';
  }

  static String _iconKeyForCategory(String name) {
    final value = name.trim().toLowerCase();
    if (value.contains('plumb')) return 'plumber';
    if (value.contains('electric')) return 'electrician';
    if (value.contains('clean')) return 'cleaner';
    if (value.contains('appliance')) return 'appliance';
    if (value.contains('maintenance')) return 'maintenance';
    return 'maintenance';
  }

  static String _idKey(String name) {
    return name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  static String _imageForCategory(String category) {
    final value = category.trim().toLowerCase();
    if (value.contains('plumb')) {
      return 'assets/images/plumber/pipe-leak.jpg';
    }
    if (value.contains('electric')) {
      return 'assets/images/electrician/wiring-repair.jpg';
    }
    if (value.contains('clean')) {
      return 'assets/images/cleaning/house-cleaning.jpg';
    }
    if (value.contains('appliance')) {
      return 'assets/images/home_appliance_repair/ac-repair.jpg';
    }
    if (value.contains('maintenance')) {
      return 'assets/images/home_maintenance/furniture-repair.jpg';
    }
    return 'assets/images/plumber_category.jpg';
  }

  static int _etaHoursFromCategory(String category) {
    final value = category.trim().toLowerCase();
    if (value.contains('plumb')) return 1;
    if (value.contains('electric')) return 2;
    if (value.contains('clean')) return 2;
    if (value.contains('appliance')) return 3;
    return 2;
  }

  static Map<String, dynamic> _safeMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, item) => MapEntry(key.toString(), item));
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _safeList(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];
    return value.whereType<Map>().map(_safeMap).toList(growable: false);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? fallback;
  }

  static const List<String> defaultRecentSearches = <String>[
    'House Cleaning',
    'Pipe leaks',
    'Wiring Repair',
    'Air Conditioner Repair',
    'Furniture Fixing',
  ];
}
