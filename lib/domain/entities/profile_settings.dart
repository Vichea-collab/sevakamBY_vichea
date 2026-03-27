import '../../core/constants/support_ticket_options.dart';

DateTime _parseBlockedDate(dynamic value) {
  final raw = (value ?? '').toString().trim();
  if (raw.isEmpty) return DateTime.now();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
  if (match != null) {
    return DateTime(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
  }
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return DateTime.now();
  return DateTime(parsed.year, parsed.month, parsed.day);
}

String _formatBlockedDate(DateTime value) {
  final normalized = DateTime(value.year, value.month, value.day);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

class ProfileFormData {
  final String name;
  final String email;
  final String dateOfBirth;
  final String country;
  final String phoneNumber;
  final String city;
  final String bio;
  final String photoUrl;

  const ProfileFormData({
    required this.name,
    required this.email,
    required this.dateOfBirth,
    required this.country,
    required this.phoneNumber,
    required this.city,
    required this.bio,
    this.photoUrl = '',
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
      photoUrl: '',
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
      photoUrl: '',
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
    String? photoUrl,
  }) {
    return ProfileFormData(
      name: name ?? this.name,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      country: country ?? this.country,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      photoUrl: photoUrl ?? this.photoUrl,
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
      photoUrl: (map['photoUrl'] ?? '').toString(),
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
      'photoUrl': photoUrl,
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
  final List<DateTime> blockedDates;

  const ProviderProfessionData({
    required this.serviceName,
    required this.expertIn,
    required this.availableFrom,
    required this.availableTo,
    required this.experienceYears,
    required this.serviceArea,
    this.blockedDates = const [],
  });

  factory ProviderProfessionData.defaults() {
    return const ProviderProfessionData(
      serviceName: 'Cleaner',
      expertIn: 'Home clean, lawn clean, washing',
      availableFrom: '9:00 AM',
      availableTo: '10:00 PM',
      experienceYears: '4',
      serviceArea: 'PP, Cambodia',
      blockedDates: [],
    );
  }

  ProviderProfessionData copyWith({
    String? serviceName,
    String? expertIn,
    String? availableFrom,
    String? availableTo,
    String? experienceYears,
    String? serviceArea,
    List<DateTime>? blockedDates,
  }) {
    return ProviderProfessionData(
      serviceName: serviceName ?? this.serviceName,
      expertIn: expertIn ?? this.expertIn,
      availableFrom: availableFrom ?? this.availableFrom,
      availableTo: availableTo ?? this.availableTo,
      experienceYears: experienceYears ?? this.experienceYears,
      serviceArea: serviceArea ?? this.serviceArea,
      blockedDates: blockedDates ?? this.blockedDates,
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
      blockedDates: (map['blockedDates'] as List? ?? [])
          .map(_parseBlockedDate)
          .toList(),
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
      'blockedDates': blockedDates.map(_formatBlockedDate).toList(),
    };
  }
}

class NotificationPreference {
  final bool general;
  final bool sound;
  final bool vibrate;
  final bool newService;

  const NotificationPreference({
    required this.general,
    required this.sound,
    required this.vibrate,
    required this.newService,
  });

  factory NotificationPreference.defaults() {
    return const NotificationPreference(
      general: true,
      sound: false,
      vibrate: true,
      newService: false,
    );
  }

  NotificationPreference copyWith({
    bool? general,
    bool? sound,
    bool? vibrate,
    bool? newService,
  }) {
    return NotificationPreference(
      general: general ?? this.general,
      sound: sound ?? this.sound,
      vibrate: vibrate ?? this.vibrate,
      newService: newService ?? this.newService,
    );
  }

  factory NotificationPreference.fromMap(Map<String, dynamic> map) {
    return NotificationPreference(
      general: map['general'] == true,
      sound: map['sound'] == true,
      vibrate: map['vibrate'] == true,
      newService: map['newService'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'general': general,
      'sound': sound,
      'vibrate': vibrate,
      'newService': newService,
    };
  }
}

class HelpSupportTicket {
  final String id;
  final String ticketType;
  final String title;
  final String message;
  final String category;
  final String subcategory;
  final String priority;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String lastMessageText;
  final DateTime? lastMessageAt;

  const HelpSupportTicket({
    this.id = '',
    this.ticketType = 'help',
    required this.title,
    required this.message,
    this.category = 'other',
    this.subcategory = 'other_issue',
    this.priority = 'normal',
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
    final category = (map['category'] ?? 'other').toString();
    final subcategory = (map['subcategory'] ?? 'other_issue').toString();
    final title = (map['title'] ?? '').toString().trim();
    return HelpSupportTicket(
      id: (map['id'] ?? '').toString(),
      ticketType: (map['ticketType'] ?? 'help').toString().trim().toLowerCase(),
      title: title.isEmpty
          ? supportTicketSubcategoryLabel(
              categoryId: category,
              subcategoryId: subcategory,
            )
          : title,
      message: message,
      category: category,
      subcategory: subcategory,
      priority: (map['priority'] ?? 'normal').toString(),
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
      'ticketType': ticketType,
      'title': title,
      'message': message,
      'category': category,
      'subcategory': subcategory,
      'priority': priority,
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
  final String imageUrl;
  final String senderUid;
  final String senderRole;
  final String senderName;
  final DateTime createdAt;

  const HelpTicketMessage({
    this.id = '',
    required this.text,
    this.type = 'text',
    this.imageUrl = '',
    this.senderUid = '',
    this.senderRole = 'finder',
    this.senderName = 'User',
    required this.createdAt,
  });

  factory HelpTicketMessage.fromMap(Map<String, dynamic> map) {
    final text = (map['text'] ?? map['message'] ?? '').toString();
    final type = (map['type'] ?? 'text').toString();
    String imageUrl = (map['imageUrl'] ?? '').toString();
    // If no explicit imageUrl but type is image, try to extract from text.
    if (imageUrl.isEmpty &&
        (type == 'image' ||
            text.startsWith('data:image/') ||
            (text.startsWith('http') && _looksLikeImageUrl(text)))) {
      imageUrl = text;
    }
    return HelpTicketMessage(
      id: (map['id'] ?? '').toString(),
      text: text,
      type: type,
      imageUrl: imageUrl,
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
      'imageUrl': imageUrl,
      'senderUid': senderUid,
      'senderRole': senderRole,
      'senderName': senderName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static bool _looksLikeImageUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('firebasestorage.googleapis.com') ||
        lower.contains('storage.googleapis.com') ||
        lower.contains('alt=media') ||
        lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
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
