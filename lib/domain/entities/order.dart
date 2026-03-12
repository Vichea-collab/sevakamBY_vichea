import 'provider.dart';

enum OrderStatus { booked, onTheWay, started, completed, cancelled, declined }

class OrderStatusTimeline {
  final DateTime? bookedAt;
  final DateTime? onTheWayAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;
  final DateTime? declinedAt;

  const OrderStatusTimeline({
    this.bookedAt,
    this.onTheWayAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.declinedAt,
  });

  bool get isEmpty =>
      bookedAt == null &&
      onTheWayAt == null &&
      startedAt == null &&
      completedAt == null &&
      cancelledAt == null &&
      declinedAt == null;
}

enum HomeType { apartment, flat, villa, office }

enum BookingFieldType { text, number, dropdown, toggle, photo, multiline }

class BookingFieldDef {
  final String key;
  final String label;
  final BookingFieldType type;
  final bool required;
  final List<String> options;

  const BookingFieldDef({
    required this.key,
    required this.label,
    required this.type,
    this.required = false,
    this.options = const [],
  });

  factory BookingFieldDef.fromMap(Map<String, dynamic> map) {
    return BookingFieldDef(
      key: map['key'].toString(),
      label: map['label'].toString(),
      type: _parseFieldType(map['type'].toString()),
      required: map['required'] == true,
      options: (map['options'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
    );
  }

  static BookingFieldType _parseFieldType(String value) {
    switch (value.toLowerCase()) {
      case 'number':
        return BookingFieldType.number;
      case 'dropdown':
        return BookingFieldType.dropdown;
      case 'toggle':
        return BookingFieldType.toggle;
      case 'photo':
        return BookingFieldType.photo;
      case 'multiline':
        return BookingFieldType.multiline;
      case 'text':
      default:
        return BookingFieldType.text;
    }
  }
}

class HomeAddress {
  final String id;
  final String label;
  final String mapLink;
  final String street;
  final String city;
  final bool isDefault;

  const HomeAddress({
    required this.id,
    required this.label,
    this.mapLink = '',
    required this.street,
    required this.city,
    this.isDefault = false,
  });
}

class BookingDraft {
  final ProviderItem provider;
  final String categoryName;
  final String serviceName;
  final HomeAddress? address;
  final DateTime preferredDate;
  final String preferredTimeSlot;
  final HomeType homeType;
  final String additionalService;
  final Map<String, dynamic> serviceFields;

  const BookingDraft({
    required this.provider,
    required this.categoryName,
    required this.serviceName,
    this.address,
    required this.preferredDate,
    required this.preferredTimeSlot,
    this.homeType = HomeType.apartment,
    this.additionalService = '',
    this.serviceFields = const {},
  });

  BookingDraft copyWith({
    ProviderItem? provider,
    String? categoryName,
    String? serviceName,
    HomeAddress? address,
    DateTime? preferredDate,
    String? preferredTimeSlot,
    HomeType? homeType,
    String? additionalService,
    Map<String, dynamic>? serviceFields,
  }) {
    return BookingDraft(
      provider: provider ?? this.provider,
      categoryName: categoryName ?? this.categoryName,
      serviceName: serviceName ?? this.serviceName,
      address: address ?? this.address,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      homeType: homeType ?? this.homeType,
      additionalService: additionalService ?? this.additionalService,
      serviceFields: serviceFields ?? this.serviceFields,
    );
  }
}

class OrderItem {
  final String id;
  final ProviderItem provider;
  final String serviceName;
  final HomeAddress address;
  final HomeType homeType;
  final String additionalService;
  final DateTime bookedAt;
  final DateTime scheduledAt;
  final String timeRange;
  final OrderStatus status;
  final double? rating;
  final String reviewComment;
  final List<String> photoUrls;
  final DateTime? reviewedAt;
  final OrderStatusTimeline timeline;

  const OrderItem({
    required this.id,
    required this.provider,
    required this.serviceName,
    required this.address,
    required this.homeType,
    required this.additionalService,
    required this.bookedAt,
    required this.scheduledAt,
    required this.timeRange,
    required this.status,
    this.rating,
    this.reviewComment = '',
    this.photoUrls = const [],
    this.reviewedAt,
    this.timeline = const OrderStatusTimeline(),
  });

  OrderItem copyWith({
    OrderStatus? status,
    double? rating,
    String? reviewComment,
    List<String>? photoUrls,
    DateTime? reviewedAt,
    OrderStatusTimeline? timeline,
  }) {
    return OrderItem(
      id: id,
      provider: provider,
      serviceName: serviceName,
      address: address,
      homeType: homeType,
      additionalService: additionalService,
      bookedAt: bookedAt,
      scheduledAt: scheduledAt,
      timeRange: timeRange,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      reviewComment: reviewComment ?? this.reviewComment,
      photoUrls: photoUrls ?? this.photoUrls,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      timeline: timeline ?? this.timeline,
    );
  }

  bool get hasReview => (rating ?? 0) > 0;
}
