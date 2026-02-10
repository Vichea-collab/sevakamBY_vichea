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
  final String title;
  final String message;
  final DateTime createdAt;

  const HelpSupportTicket({
    required this.title,
    required this.message,
    required this.createdAt,
  });

  factory HelpSupportTicket.fromMap(Map<String, dynamic> map) {
    final rawValue = map['createdAt'];
    String rawDate = '';
    if (rawValue is Map && rawValue['_seconds'] is num) {
      final seconds = rawValue['_seconds'] as num;
      rawDate = DateTime.fromMillisecondsSinceEpoch(
        (seconds * 1000).round(),
      ).toIso8601String();
    } else {
      rawDate = (rawValue ?? '').toString();
    }
    return HelpSupportTicket(
      title: (map['title'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      createdAt: DateTime.tryParse(rawDate) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

String paymentMethodToStorageValue(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.creditCard:
      return 'credit_card';
    case PaymentMethod.bankAccount:
      return 'bank_account';
    case PaymentMethod.cash:
      return 'cash';
  }
}

PaymentMethod paymentMethodFromStorageValue(String value) {
  switch (value) {
    case 'bank_account':
      return PaymentMethod.bankAccount;
    case 'cash':
      return PaymentMethod.cash;
    case 'credit_card':
    default:
      return PaymentMethod.creditCard;
  }
}
