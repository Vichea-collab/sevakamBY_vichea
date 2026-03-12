import 'order.dart';

enum ProviderOrderState { incoming, booked, onTheWay, started, completed, declined }

class FinderPostItem {
  final String id;
  final String finderUid;
  final String clientName;
  final String message;
  final String timeLabel;
  final String category;
  final String service;
  final List<String> services;
  final String location;
  final String avatarPath;
  final DateTime? preferredDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FinderPostItem({
    required this.id,
    this.finderUid = '',
    required this.clientName,
    required this.message,
    required this.timeLabel,
    required this.category,
    required this.service,
    this.services = const <String>[],
    required this.location,
    required this.avatarPath,
    this.preferredDate,
    this.createdAt,
    this.updatedAt,
  });

  List<String> get serviceList => _serviceList(service, services);

  String get serviceLabel => _serviceLabel(serviceList);
}

class ProviderPostItem {
  final String id;
  final String providerUid;
  final String providerName;
  final String providerBio;
  final String category;
  final String service;
  final List<String> services;
  final String area;
  final String details;
  final bool availableNow;
  final String timeLabel;
  final String avatarPath;
  final double rating;
  final bool isVerified;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DateTime> blockedDates;

  const ProviderPostItem({
    required this.id,
    required this.providerUid,
    required this.providerName,
    this.providerBio = '',
    required this.category,
    required this.service,
    required this.services,
    required this.area,
    required this.details,
    required this.availableNow,
    required this.timeLabel,
    this.avatarPath = '',
    this.rating = 0,
    this.isVerified = false,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.blockedDates = const [],
  });

  List<String> get serviceList => _serviceList(service, services);

  String get serviceLabel => _serviceLabel(serviceList);

  factory ProviderPostItem.fromMap(Map<String, dynamic> map) {
    final ratingVal = map['rating'] ?? map['providerRating'] ?? 0;
    return ProviderPostItem(
      id: (map['id'] ?? '').toString(),
      providerUid: (map['providerUid'] ?? '').toString(),
      providerName: (map['providerName'] ?? 'Service Provider').toString(),
      providerBio: (map['providerBio'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      service: (map['service'] ?? '').toString(),
      services: (map['services'] as List? ?? []).map((e) => e.toString()).toList(),
      area: (map['area'] ?? '').toString(),
      details: (map['details'] ?? '').toString(),
      availableNow: map['availableNow'] == true,
      timeLabel: (map['timeLabel'] ?? '').toString(),
      avatarPath: (map['avatarPath'] ?? map['providerAvatar'] ?? '').toString(),
      rating: ratingVal is num ? ratingVal.toDouble() : 0,
      isVerified: map['isVerified'] == true,
      latitude: double.tryParse((map['latitude'] ?? '').toString()),
      longitude: double.tryParse((map['longitude'] ?? '').toString()),
      createdAt: map['createdAt'] != null ? DateTime.tryParse(map['createdAt'].toString()) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.tryParse(map['updatedAt'].toString()) : null,
      blockedDates: (map['blockedDates'] as List? ?? [])
          .map((e) => DateTime.parse(e.toString()))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerUid': providerUid,
      'providerName': providerName,
      'providerBio': providerBio,
      'category': category,
      'service': service,
      'services': services,
      'area': area,
      'details': details,
      'availableNow': availableNow,
      'timeLabel': timeLabel,
      'avatarPath': avatarPath,
      'rating': rating,
      'isVerified': isVerified,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'blockedDates': blockedDates.map((e) => e.toIso8601String()).toList(),
    };
  }
}

class ProviderOrderItem {
  final String id;
  final String clientName;
  final String clientPhone;
  final String category;
  final String serviceName;
  final String address;
  final String addressLink;
  final String scheduleDate;
  final String scheduleTime;
  final String homeType;
  final String additionalService;
  final String finderNote;
  final Map<String, String> serviceInputs;
  final ProviderOrderState state;
  final OrderStatusTimeline timeline;

  const ProviderOrderItem({
    required this.id,
    required this.clientName,
    this.clientPhone = '',
    required this.category,
    required this.serviceName,
    required this.address,
    this.addressLink = '',
    required this.scheduleDate,
    required this.scheduleTime,
    this.homeType = '',
    this.additionalService = '',
    this.finderNote = '',
    this.serviceInputs = const {},
    required this.state,
    this.timeline = const OrderStatusTimeline(),
  });

  ProviderOrderItem copyWith({
    ProviderOrderState? state,
    OrderStatusTimeline? timeline,
  }) {
    return ProviderOrderItem(
      id: id,
      clientName: clientName,
      clientPhone: clientPhone,
      category: category,
      serviceName: serviceName,
      address: address,
      addressLink: addressLink,
      scheduleDate: scheduleDate,
      scheduleTime: scheduleTime,
      homeType: homeType,
      additionalService: additionalService,
      finderNote: finderNote,
      serviceInputs: serviceInputs,
      state: state ?? this.state,
      timeline: timeline ?? this.timeline,
    );
  }
}

List<String> _serviceList(String primary, List<String> extras) {
  final values = <String>{};
  final base = primary.trim();
  if (base.isNotEmpty) values.add(base);
  for (final entry in extras) {
    final value = entry.trim();
    if (value.isNotEmpty) values.add(value);
  }
  return values.toList(growable: false);
}

String _serviceLabel(List<String> values) {
  if (values.isEmpty) return '';
  final sorted = values.toList(growable: false)..sort();
  if (sorted.length == 1) return sorted.first;
  return '${sorted.first} +${sorted.length - 1} more';
}
