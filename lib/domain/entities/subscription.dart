import 'package:flutter/material.dart';

/// Subscription tier levels
enum SubscriptionTier { basic, professional, elite }

class SubscriptionCheckoutSession {
  final String sessionId;
  final String? url;
  final String paymentMethod;
  final String? qrPayload;
  final String? qrImageUrl;
  final String? merchantReference;
  final double? amount;
  final String? currency;

  const SubscriptionCheckoutSession({
    required this.sessionId,
    this.url,
    this.paymentMethod = 'stripe',
    this.qrPayload,
    this.qrImageUrl,
    this.merchantReference,
    this.amount,
    this.currency,
  });

  bool get isBakong {
    final method = paymentMethod.toLowerCase();
    return method == 'bakong' ||
        sessionId.toLowerCase().startsWith('khqr_') ||
        (qrPayload?.trim().isNotEmpty ?? false) ||
        (qrImageUrl?.trim().isNotEmpty ?? false);
  }

  factory SubscriptionCheckoutSession.fromMap(Map<String, dynamic> map) {
    final sessionId = (map['sessionId'] ?? '').toString();
    final urlText = (map['url'] ?? '').toString();
    final qrPayloadText = (map['qrPayload'] ?? '').toString();
    final qrImageUrlText = (map['qrImageUrl'] ?? '').toString();
    final rawPaymentMethod = (map['paymentMethod'] ?? '').toString().trim();
    final inferredPaymentMethod = rawPaymentMethod.isNotEmpty
        ? rawPaymentMethod
        : (sessionId.toLowerCase().startsWith('khqr_') ||
                  qrPayloadText.trim().isNotEmpty ||
                  qrImageUrlText.trim().isNotEmpty
              ? 'bakong'
              : 'stripe');
    return SubscriptionCheckoutSession(
      sessionId: sessionId,
      url: urlText.trim().isEmpty ? null : urlText,
      paymentMethod: inferredPaymentMethod,
      qrPayload: qrPayloadText.trim().isEmpty ? null : qrPayloadText,
      qrImageUrl: qrImageUrlText.trim().isEmpty ? null : qrImageUrlText,
      merchantReference: (map['merchantReference'] ?? '').toString().trim().isEmpty
          ? null
          : (map['merchantReference'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble(),
      currency: (map['currency'] ?? '').toString().trim().isEmpty
          ? null
          : (map['currency'] ?? '').toString(),
    );
  }
}

/// Static plan definition (UI display)
class SubscriptionPlan {
  final SubscriptionTier tier;
  final String name;
  final String tagline;
  final double monthlyPrice;
  final int bookingLimit; // -1 = unlimited
  final Color badgeColor;
  final IconData badgeIcon;
  final List<String> features;
  final String bestFor;
  final int searchRankMultiplier;
  final int maxPhotos; // -1 = unlimited
  final int trialDays;

  const SubscriptionPlan({
    required this.tier,
    required this.name,
    required this.tagline,
    required this.monthlyPrice,
    required this.bookingLimit,
    required this.badgeColor,
    required this.badgeIcon,
    required this.features,
    this.bestFor = '',
    this.searchRankMultiplier = 1,
    this.maxPhotos = 5,
    this.trialDays = 0,
  });

  String get priceLabel =>
      monthlyPrice == 0 ? 'Free' : '\$${monthlyPrice.toStringAsFixed(0)}/mo';

  String get bookingLimitLabel =>
      bookingLimit < 0 ? 'Unlimited' : '$bookingLimit/month';

  static const List<SubscriptionPlan> all = [
    SubscriptionPlan(
      tier: SubscriptionTier.basic,
      name: 'Basic',
      tagline: 'Try the platform and build early credibility',
      monthlyPrice: 0,
      bookingLimit: 5,
      badgeColor: Color(0xFF94A3B8),
      badgeIcon: Icons.verified_outlined,
      searchRankMultiplier: 1,
      maxPhotos: 5,
      trialDays: 7,
      bestFor: 'Freelancers starting out or testing demand',
      features: [
        'Basic profile & direct chat',
        'Standard search placement (1x)',
        'Up to 5 bookings/month',
        '7-day initial visibility boost',
        'Upload 3–5 portfolio photos',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.professional,
      name: 'Plus',
      tagline: 'Grow steady bookings and improve ranking',
      monthlyPrice: 5,
      bookingLimit: 25,
      badgeColor: Color(0xFF3B82F6),
      badgeIcon: Icons.workspace_premium,
      searchRankMultiplier: 2,
      maxPhotos: 15,
      trialDays: 7,
      bestFor: 'Full-time professionals building a consistent client base',
      features: [
        'Featured Provider badge (blue)',
        '2x search ranking boost',
        'Up to 25 bookings/month',
        'Portfolio gallery up to 15 photos',
        'Profile analytics dashboard',
        'Priority KYC review (planned)',
        '7-day free trial for new providers',
      ],
    ),
    SubscriptionPlan(
      tier: SubscriptionTier.elite,
      name: 'Pro',
      tagline: 'Maximum visibility and scale',
      monthlyPrice: 10,
      bookingLimit: -1,
      badgeColor: Color(0xFFF59E0B),
      badgeIcon: Icons.diamond_outlined,
      searchRankMultiplier: 5,
      maxPhotos: -1,
      trialDays: 0,
      bestFor: 'Established companies and teams with multiple workers',
      features: [
        'Top Tier badge (gold) + top-of-list ranking',
        '5x search ranking boost',
        'Unlimited booking requests',
        'Featured on Home "Top Providers"',
        'Unlimited portfolio photos',
        'Special-offer broadcast entitlement (planned)',
        'Dedicated premium support (planned)',
      ],
    ),
  ];
}

/// Live subscription status from backend
class SubscriptionStatus {
  final SubscriptionTier tier;
  final String status;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;
  final String paymentProvider;
  final bool autoRenews;
  final bool canCancel;
  final int bookingsUsed;
  final int bookingLimit;
  final bool canAcceptBookings;

  const SubscriptionStatus({
    this.tier = SubscriptionTier.basic,
    this.status = 'active',
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.cancelAtPeriodEnd = false,
    this.paymentProvider = '',
    this.autoRenews = false,
    this.canCancel = false,
    this.bookingsUsed = 0,
    this.bookingLimit = 5,
    this.canAcceptBookings = true,
  });

  SubscriptionPlan get plan =>
      SubscriptionPlan.all.firstWhere((p) => p.tier == tier);

  double get usagePercent {
    if (bookingLimit <= 0) return 0;
    return (bookingsUsed / bookingLimit).clamp(0.0, 1.0);
  }

  String get usageLabel {
    if (bookingLimit < 0) return '$bookingsUsed used (unlimited)';
    return '$bookingsUsed / $bookingLimit bookings used';
  }

  bool get isActive => status == 'active';
  bool get isCanceling => cancelAtPeriodEnd && isActive;

  factory SubscriptionStatus.fromMap(Map<String, dynamic> map) {
    return SubscriptionStatus(
      tier: _parseTier(map['tier']),
      status: (map['status'] ?? 'active').toString(),
      currentPeriodStart: map['currentPeriodStart'] != null
          ? DateTime.tryParse(map['currentPeriodStart'].toString())
          : null,
      currentPeriodEnd: map['currentPeriodEnd'] != null
          ? DateTime.tryParse(map['currentPeriodEnd'].toString())
          : null,
      cancelAtPeriodEnd: map['cancelAtPeriodEnd'] == true,
      paymentProvider: (map['paymentProvider'] ?? '').toString(),
      autoRenews: map['autoRenews'] == true,
      canCancel: map['canCancel'] == true,
      bookingsUsed: (map['bookingsUsed'] as num?)?.toInt() ?? 0,
      bookingLimit: (map['bookingLimit'] as num?)?.toInt() ?? 5,
      canAcceptBookings: map['canAcceptBookings'] != false,
    );
  }

  static SubscriptionTier _parseTier(dynamic value) {
    final text = (value ?? '').toString().toLowerCase();
    switch (text) {
      case 'professional':
        return SubscriptionTier.professional;
      case 'elite':
        return SubscriptionTier.elite;
      default:
        return SubscriptionTier.basic;
    }
  }
}
