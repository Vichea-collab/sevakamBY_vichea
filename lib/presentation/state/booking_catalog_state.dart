import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/order.dart';
import '../../domain/entities/provider.dart';
import 'catalog_state.dart';

class BookingCatalogState {
  static const List<int> bookingHourOptions = <int>[1, 2, 3, 4, 5, 6];
  static const List<int> workerCountOptions = <int>[1, 2, 3, 4];
  static const List<String> scheduleTimeOptions = <String>[
    '08:00 AM - 10:00 AM',
    '09:00 AM - 11:00 AM',
    '11:00 AM - 01:00 PM',
    '01:00 PM - 03:00 PM',
    '03:00 PM - 05:00 PM',
    '05:00 PM - 07:00 PM',
  ];
  static const List<HomeType> homeTypeOptions = <HomeType>[
    HomeType.apartment,
    HomeType.flat,
    HomeType.villa,
    HomeType.office,
  ];
  static const List<String> cancelReasons = <String>[
    "Don't need the service anymore",
    'Not available at this time',
    'Found a better rate elsewhere',
    'Placed the request by mistake',
    'Other',
  ];

  static Map<String, List<BookingFieldDef>> _serviceFieldsByService = {};
  static List<BookingFieldDef> _genericServiceFields = [];
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      final String response = await rootBundle.loadString('assets/data/booking_fields.json');
      final data = json.decode(response);
      
      _genericServiceFields = (data['generic'] as List)
          .map((f) => BookingFieldDef.fromMap(f))
          .toList();
          
      final servicesMap = data['services'] as Map<String, dynamic>;
      _serviceFieldsByService = servicesMap.map((key, value) => MapEntry(
        key,
        (value as List).map((f) => BookingFieldDef.fromMap(f)).toList(),
      ));
      
      _initialized = true;
    } catch (e) {
      debugPrint('Error initializing BookingCatalogState: $e');
    }
  }

  static BookingDraft defaultBookingDraft({
    required ProviderItem provider,
    String? serviceName,
  }) {
    final categoryName = CatalogState.categoryForProviderRole(provider.role);
    final providerServices = provider.services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final available = providerServices;
    final preferred = serviceName?.trim() ?? '';
    final resolvedService = available.contains(preferred)
        ? preferred
        : (available.isNotEmpty ? available.first : '');

    return BookingDraft(
      provider: provider,
      categoryName: categoryName,
      serviceName: resolvedService,
      address: null,
      preferredDate: DateTime.now().add(const Duration(days: 1)),
      preferredTimeSlot: scheduleTimeOptions[1],
      hours: 2,
      homeType: HomeType.apartment,
      workers: 1,
      paymentMethod: PaymentMethod.creditCard,
      additionalService: '',
      promoCode: '',
      unitPricePerHour: 12,
      serviceFields: initialFieldValuesForService(resolvedService),
    );
  }

  static List<BookingFieldDef> bookingFieldsForService(String serviceName) {
    final canonical = _canonicalServiceName(serviceName);
    return _serviceFieldsByService[canonical] ?? _genericServiceFields;
  }

  static Map<String, dynamic> initialFieldValuesForService(String serviceName) {
    final defs = bookingFieldsForService(serviceName);
    final values = <String, dynamic>{};
    for (final field in defs) {
      switch (field.type) {
        case BookingFieldType.toggle:
        case BookingFieldType.photo:
          values[field.key] = false;
          break;
        case BookingFieldType.dropdown:
          values[field.key] = field.options.isEmpty ? '' : field.options.first;
          break;
        case BookingFieldType.number:
          values[field.key] = '1';
          break;
        case BookingFieldType.text:
        case BookingFieldType.multiline:
          values[field.key] = '';
          break;
      }
    }
    return values;
  }

  static String _canonicalServiceName(String serviceName) {
    switch (serviceName.trim()) {
      case 'AC Repair':
        return 'Air Conditioner Repair';
      case 'Door Repair':
        return 'Door & Window Repair';
      default:
        return serviceName.trim();
    }
  }
}
