import 'package:flutter/foundation.dart' show ValueNotifier;

import '../../core/config/app_env.dart';
import '../../data/network/backend_api_client.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/service.dart';

class CatalogState {
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

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
  }

  static Future<void> refresh() async {
    loading.value = true;
    try {
      final loadedCategories = await _loadCategories();
      final loadedServices = await _loadServices(loadedCategories);

      categories.value = loadedCategories.isEmpty
          ? _fallbackCategories
          : loadedCategories;
      services.value = loadedServices.isEmpty
          ? _fallbackServices
          : loadedServices;
    } catch (_) {
      categories.value = _fallbackCategories;
      services.value = _fallbackServices;
    } finally {
      loading.value = false;
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
    final response = await _apiClient.getJson('/api/categories/allCategories');
    final rows = response['data'];
    if (rows is! List) return const <Category>[];

    final mapped = rows
        .whereType<Map>()
        .map((raw) {
          final row = _safeMap(raw);
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
  }

  static Future<List<ServiceItem>> _loadServices(
    List<Category> loadedCategories,
  ) async {
    final response = await _apiClient.getJson('/api/services');
    final rows = response['data'];
    if (rows is! List) return const <ServiceItem>[];

    final categoriesById = <String, Category>{};
    for (final category in loadedCategories) {
      categoriesById[_idKey(category.name)] = category;
    }

    final mapped = rows
        .whereType<Map>()
        .map((raw) {
          final row = _safeMap(raw);
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

          return ServiceItem(
            title: title,
            subtitle: 'Starts in \$${rate.toStringAsFixed(0)}/hr',
            badge: badge,
            imagePath: _imageForCategory(categoryName),
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
    'Pipe Leak Repair',
    'Wiring Repair',
    'Air Conditioner Repair',
    'Door & Window Repair',
  ];

  static const List<Category> _fallbackCategories = <Category>[
    Category(name: 'Plumber', icon: 'plumber'),
    Category(name: 'Electrician', icon: 'electrician'),
    Category(name: 'Cleaner', icon: 'cleaner'),
    Category(name: 'Home Appliance', icon: 'appliance'),
    Category(name: 'Home Maintenance', icon: 'maintenance'),
  ];

  static const List<ServiceItem> _fallbackServices = <ServiceItem>[
    ServiceItem(
      title: 'Pipe Leak Repair',
      subtitle: 'Starts in \$12/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.8,
      category: 'Plumber',
      etaHours: 1,
    ),
    ServiceItem(
      title: 'Toilet Repair',
      subtitle: 'Starts in \$11/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Plumber',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Water Installation',
      subtitle: 'Starts in \$14/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Plumber',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Wiring Repair',
      subtitle: 'Starts in \$16/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.7,
      category: 'Electrician',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Light / Fan Installation',
      subtitle: 'Starts in \$14/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Electrician',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Power Outage Fixes',
      subtitle: 'Starts in \$15/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Electrician',
      etaHours: 1,
    ),
    ServiceItem(
      title: 'House Cleaning',
      subtitle: 'Starts in \$10/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.9,
      category: 'Cleaner',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Office Cleaning',
      subtitle: 'Starts in \$13/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.4,
      category: 'Cleaner',
      etaHours: 3,
    ),
    ServiceItem(
      title: 'Move-in / Move-out Cleaning',
      subtitle: 'Starts in \$15/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.7,
      category: 'Cleaner',
      etaHours: 3,
    ),
    ServiceItem(
      title: 'Air Conditioner Repair',
      subtitle: 'Starts in \$20/hr',
      badge: 'Popular',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.8,
      category: 'Home Appliance',
      etaHours: 3,
    ),
    ServiceItem(
      title: 'Washing Machine Repair',
      subtitle: 'Starts in \$19/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Home Appliance',
      etaHours: 3,
    ),
    ServiceItem(
      title: 'Refrigerator Repair',
      subtitle: 'Starts in \$18/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Home Appliance',
      etaHours: 3,
    ),
    ServiceItem(
      title: 'Door & Window Repair',
      subtitle: 'Starts in \$17/hr',
      badge: 'Trusted',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.4,
      category: 'Home Maintenance',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Furniture Fixing',
      subtitle: 'Starts in \$18/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.6,
      category: 'Home Maintenance',
      etaHours: 2,
    ),
    ServiceItem(
      title: 'Shelf / Curtain Installation',
      subtitle: 'Starts in \$16/hr',
      badge: 'Pro',
      imagePath: 'assets/images/plumber_category.jpg',
      rating: 4.5,
      category: 'Home Maintenance',
      etaHours: 2,
    ),
  ];
}
