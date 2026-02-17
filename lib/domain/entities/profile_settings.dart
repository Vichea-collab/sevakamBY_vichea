import 'order.dart';

class ProfileFormData {
  final String name;
  final String email;
  final String dateOfBirth;
  final String country;
  final String phoneNumber;
  final String city;
  final String bio;

  const ProfileFormData({
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.country,
    required this.phoneNumber,
    required this.city,
    required this.bio,
  });

  factory ProfileFormData.finderDefault() {
    return const ProfileFormData(
      name: 'Eang Kimheng',
      email: 'kimheng@gmail.com',
      dateOfBirth: '28/11/2005',
      country: 'Cambodia',
      phoneNumber: '+855 12 345 678',
      city: 'Phnom Penh',
      bio: '',
    );
  }

  factory ProfileFormData.providerDefault() {
    return const ProfileFormData(
      name: 'Kimheng',
      email: 'kimheng@gmail.com',
      dateOfBirth: '28/11/2005',
      country: 'Cambodia',
      phoneNumber: '+855 12 345 678',
      city: 'Phnom Penh',
      bio: 'Reliable provider with clean and professional service.',
    );
  }

  ProfileFormData copyWith({
    String? name,
    String? email,
    String? dateOfBirth,
    String? country,
    String? phoneNumber,
    String? city,
    String? bio,
  }) {
    return ProfileFormData(
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      bio: bio ?? this.bio,
    );
  }

  factory ProfileFormData.fromMap(Map<String, dynamic> map) {
    return ProfileFormData(
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      dateOfBirth: (map['dateOfBirth'] ?? '').toString(),
      country: (map['country'] ?? '').toString(),
      phoneNumber: (map['phoneNumber'] ?? '').toString(),
      city: (map['city'] ?? '').toString(),
      bio: (map['bio'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'country': country,
      'phoneNumber': phoneNumber,
      'city': city,
      'bio': bio,
    };
  }
}

class ProviderProfessionData {
  final String serviceName;
  final String expertIn;
  final String availableFrom;
  final String availableTo;
  final String experienceYears;
  final String serviceArea;

  const ProviderProfessionData({
    required this.serviceName,
    required this.expertIn,
    required this.availableFrom,
    required this.availableTo,
    required this.experienceYears,
    required this.serviceArea,
  });

  factory ProviderProfessionData.defaults() {
    return const ProviderProfessionData(
      serviceName: 'Cleaner',
      expertIn: 'Home clean, lawn clean, washing',
      availableFrom: '9:00 AM',
      availableTo: '10:00 PM',
      experienceYears: '4',
      serviceArea: 'PP, Cambodia',
    );
  }

  ProviderProfessionData copyWith({
    String? serviceName,
    String? expertIn,
    String? availableFrom,
    String? availableTo,
    String? experienceYears,
    String? serviceArea,
  }) {
    return ProviderProfessionData(
      serviceName: serviceName ?? this.serviceName,
      expertIn: expertIn ?? this.expertIn,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      experienceYears: experienceYears ?? this.experienceYears,
      serviceArea: serviceArea ?? this.serviceArea,
    );
  }

  factory ProviderProfessionData.fromMap(Map<String, dynamic> map) {
    return ProviderProfessionData(
      serviceName: (map['serviceName'] ?? '').toString(),
      expertIn: (map['expertIn'] ?? '').toString(),
      availableFrom: (map['availableFrom'] ?? '').toString(),
      availableTo: (map['availableTo'] ?? '').toString(),
      experienceYears: (map['experienceYears'] ?? '').toString(),
      serviceArea: (map['serviceArea'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serviceName': serviceName,
      'expertIn': expertIn,
      'availableFrom': availableFrom,
      'availableTo': availableTo,
      'experienceYears': experienceYears,
      'serviceArea': serviceArea,
    };
  }
}

class NotificationPreference {
  final bool general;
  final bool sound;
  final bool vibrate;
  final bool newService;
  final bool payment;

  const NotificationPreference({
    required this.general,
    required this.sound,
    required this.vibrate,
    required this.newService,
    required this.payment,
  });

  factory NotificationPreference.defaults() {
    return const NotificationPreference(
      general: true,
      sound: false,
      vibrate: true,
      newService: false,
      payment: true,
    );
  }

  NotificationPreference copyWith({
    bool? general,
    bool? sound,
    bool? vibrate,
    bool? newService,
    bool? payment,
  }) {
    return NotificationPreference(
      general: general ?? this.general,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      newService: newService ?? this.newService,
      payment: payment ?? this.payment,
    );
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      general: map['general'] == true,
      sound: map['sound'] == true,
      vibrate: map['vibrate'] == true,
      newService: map['newService'] == true,
      payment: map['payment'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'general': general,
      'sound': sound,
      'vibrate': vibrate,
      'newService': newService,
      'payment': payment,
    };
  }
}

class HelpSupportTicket {
  final String id;
  final String title;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String lastMessageText;
  final DateTime? lastMessageAt;

  const HelpSupportTicket({
    this.id = '',
    required this.title,
    required this.message,
    this.status = 'open',
    required this.createdAt,
    this.updatedAt,
    this.lastMessageText = '',
    this.lastMessageAt,
  });

  factory HelpSupportTicket.fromMap(Map<String, dynamic> map) {
    final createdAt = _parseDateDynamic(map['createdAt']) ?? DateTime.now();
    final message = (map['message'] ?? '').toString();
    final lastMessageText = (map['lastMessageText'] ?? '').toString().trim();
    return HelpSupportTicket(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      message: message,
      status: (map['status'] ?? 'open').toString(),
      createdAt: createdAt,
      updatedAt: _parseDateDynamic(map['updatedAt']),
      lastMessageText: lastMessageText.isEmpty ? message : lastMessageText,
      lastMessageAt: _parseDateDynamic(map['lastMessageAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastMessageText': lastMessageText,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
    };
  }
}

class HelpTicketMessage {
  final String id;
  final String text;
  final String type;
  final String senderUid;
  final String senderRole;
  final String senderName;
  final DateTime createdAt;

  const HelpTicketMessage({
    this.id = '',
    required this.text,
    this.type = 'text',
    this.senderUid = '',
    this.senderRole = 'finder',
    this.senderName = 'User',
    required this.createdAt,
  });

  factory HelpTicketMessage.fromMap(Map<String, dynamic> map) {
    return HelpTicketMessage(
      id: (map['id'] ?? '').toString(),
      text: (map['text'] ?? map['message'] ?? '').toString(),
      type: (map['type'] ?? 'text').toString(),
      senderUid: (map['senderUid'] ?? '').toString(),
      senderRole: (map['senderRole'] ?? 'finder').toString(),
      senderName: (map['senderName'] ?? 'User').toString(),
      createdAt: _parseDateDynamic(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'type': type,
      'senderUid': senderUid,
      'senderRole': senderRole,
      'senderName': senderName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

DateTime? _parseDateDynamic(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  if (value is Map && value['_seconds'] is num) {
    final seconds = value['_seconds'] as num;
    return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
  }
  return null;
}

String paymentMethodToStorageValue(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.creditCard:
      return 'credit_card';
    case PaymentMethod.bankAccount:
      return 'bank_account';
    case PaymentMethod.cash:
      return 'cash';
    case PaymentMethod.khqr:
      return 'khqr';
  }
}

PaymentMethod paymentMethodFromStorageValue(String value) {
  switch (value) {
    case 'bank_account':
      return PaymentMethod.bankAccount;
    case 'cash':
      return PaymentMethod.cash;
    case 'khqr':
      return PaymentMethod.khqr;
    case 'credit_card':
    default:
      return PaymentMethod.creditCard;
  }
}
