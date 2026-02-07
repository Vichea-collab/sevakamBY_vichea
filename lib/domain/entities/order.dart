import 'provider.dart';

enum PaymentMethod { creditCard, bankAccount, cash }

enum OrderStatus { booked, onTheWay, started, completed, cancelled }

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
  final int hours;
  final HomeType homeType;
  final int workers;
  final PaymentMethod paymentMethod;
  final String additionalService;
  final String promoCode;
  final double unitPricePerHour;
  final Map<String, dynamic> serviceFields;

  const BookingDraft({
    required this.provider,
    required this.categoryName,
    required this.serviceName,
    this.address,
    required this.preferredDate,
    required this.preferredTimeSlot,
    this.hours = 2,
    this.homeType = HomeType.apartment,
    this.workers = 1,
    this.paymentMethod = PaymentMethod.creditCard,
    this.additionalService = '',
    this.promoCode = '',
    this.unitPricePerHour = 11,
    this.serviceFields = const {},
  });

  BookingDraft copyWith({
    ProviderItem? provider,
    String? categoryName,
    String? serviceName,
    HomeAddress? address,
    DateTime? preferredDate,
    String? preferredTimeSlot,
    int? hours,
    HomeType? homeType,
    int? workers,
    PaymentMethod? paymentMethod,
    String? additionalService,
    String? promoCode,
    double? unitPricePerHour,
    Map<String, dynamic>? serviceFields,
  }) {
    return BookingDraft(
      provider: provider ?? this.provider,
      categoryName: categoryName ?? this.categoryName,
      serviceName: serviceName ?? this.serviceName,
      address: address ?? this.address,
      preferredDate: preferredDate ?? this.preferredDate,
      preferredTimeSlot: preferredTimeSlot ?? this.preferredTimeSlot,
      hours: hours ?? this.hours,
      homeType: homeType ?? this.homeType,
      workers: workers ?? this.workers,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      additionalService: additionalService ?? this.additionalService,
      promoCode: promoCode ?? this.promoCode,
      unitPricePerHour: unitPricePerHour ?? this.unitPricePerHour,
      serviceFields: serviceFields ?? this.serviceFields,
    );
  }

  double get subtotal => unitPricePerHour * hours * workers;
  double get processingFee => 0;
  double get discount => promoCode.isEmpty ? 0 : 2;
  double get total => subtotal + processingFee - discount;
}

class OrderItem {
  final String id;
  final ProviderItem provider;
  final String serviceName;
  final HomeAddress address;
  final int hours;
  final int workers;
  final HomeType homeType;
  final String additionalService;
  final DateTime bookedAt;
  final DateTime scheduledAt;
  final String timeRange;
  final PaymentMethod paymentMethod;
  final double subtotal;
  final double processingFee;
  final double discount;
  final OrderStatus status;
  final double? rating;

  const OrderItem({
    required this.id,
    required this.provider,
    required this.serviceName,
    required this.address,
    required this.hours,
    required this.workers,
    required this.homeType,
    required this.additionalService,
    required this.bookedAt,
    required this.scheduledAt,
    required this.timeRange,
    required this.paymentMethod,
    required this.subtotal,
    required this.processingFee,
    required this.discount,
    required this.status,
    this.rating,
  });

  double get total => subtotal + processingFee - discount;

  OrderItem copyWith({OrderStatus? status, double? rating}) {
    return OrderItem(
      id: id,
      provider: provider,
      serviceName: serviceName,
      address: address,
      hours: hours,
      workers: workers,
      homeType: homeType,
      additionalService: additionalService,
      bookedAt: bookedAt,
      scheduledAt: scheduledAt,
      timeRange: timeRange,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      processingFee: processingFee,
      discount: discount,
      status: status ?? this.status,
      rating: rating ?? this.rating,
    );
  }
}
