import 'package:flutter/material.dart';
import '../../domain/entities/subscription.dart';

/// Shows a tier-based badge next to a provider name.
/// - Basic: no badge (returns empty)
/// - Professional: blue verified badge
/// - Elite: gold diamond badge
class SubscriptionBadge extends StatelessWidget {
  final SubscriptionTier tier;
  final double size;

  const SubscriptionBadge({
    super.key,
    required this.tier,
    this.size = 16,
  });

  /// Create from a string tier name (from Firestore/API data).
  factory SubscriptionBadge.fromString(String? tierName, {double size = 16}) {
    final tier = _parseTier(tierName);
    return SubscriptionBadge(tier: tier, size: size);
  }

  static SubscriptionTier _parseTier(String? value) {
    final text = (value ?? '').toLowerCase().trim();
    switch (text) {
      case 'professional':
        return SubscriptionTier.professional;
      case 'elite':
        return SubscriptionTier.elite;
      default:
        return SubscriptionTier.basic;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (tier == SubscriptionTier.basic) {
      return const SizedBox.shrink();
    }

    final isElite = tier == SubscriptionTier.elite;
    final color = isElite ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6);
    final label = isElite ? 'PRO' : 'PLUS';
    final icon = isElite ? Icons.workspace_premium_rounded : Icons.verified_user_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: size,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: size * 0.65,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
