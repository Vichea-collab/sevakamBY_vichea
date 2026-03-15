import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/safe_image_provider.dart';
import '../../domain/entities/provider.dart';
import '../state/favorite_state.dart';
import 'premium_outline.dart';
import 'pressable_scale.dart';
import 'subscription_badge.dart';
import 'verified_badge.dart';

class ProviderCard extends StatelessWidget {
  final ProviderItem provider;
  final VoidCallback? onDetails;
  final String? heroTag;

  const ProviderCard({
    super.key,
    required this.provider,
    this.onDetails,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveHeroTag = heroTag ?? 'provider-card-${provider.uid}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 350;
        final tier = provider.subscriptionTier.toLowerCase().trim();
        final isElite = tier == 'elite';
        final accent = _tierAccent(tier) ?? provider.accentColor;
        final softTint = isElite
            ? const Color(0xFFFFF4D6)
            : Color.lerp(accent, Colors.white, 0.82)!;
        final serviceChips = _serviceChips(context, compact: compact);
        final name = provider.name.trim().isEmpty
            ? 'Service Provider'
            : provider.name.trim();
        final card = Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            border: isElite
                ? null
                : Border.all(color: accent.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: isElite
                    ? Colors.black.withValues(alpha: 0.05)
                    : accent.withValues(alpha: 0.10),
                blurRadius: 26,
                spreadRadius: -12,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 18,
                spreadRadius: -10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: compact ? 96 : 108,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: compact ? 70 : 78,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                softTint,
                                isElite
                                    ? const Color(0xFFFFF9EA)
                                    : accent.withValues(alpha: 0.14),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                right: -18,
                                top: -20,
                                child: Container(
                                  width: compact ? 78 : 92,
                                  height: compact ? 78 : 92,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.18),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: compact ? 26 : 32,
                          left: 18,
                          child: Hero(
                            tag: effectiveHeroTag,
                            child: _ProviderAvatar(
                              imagePath: provider.imagePath,
                              accent: accent,
                              initials: _initials(name),
                              compact: compact,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 14,
                          right: 14,
                          child: _FavoriteButton(providerUid: provider.uid),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        compact ? 4 : 6,
                        16,
                        compact ? 12 : 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.isVerified || tier != 'basic') ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                if (provider.isVerified)
                                  VerifiedBadge(size: compact ? 11 : 12),
                                if (tier != 'basic')
                                  SubscriptionBadge.fromString(
                                    provider.subscriptionTier,
                                    size: compact ? 12 : 14,
                                  ),
                              ],
                            ),
                            SizedBox(height: compact ? 8 : 10),
                          ],
                          Text(
                            name,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: compact ? 17 : 19,
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -0.35,
                                ),
                          ),
                          SizedBox(height: compact ? 4 : 6),
                          Text(
                            provider.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: compact ? 12.5 : 13.5,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(height: compact ? 10 : 12),
                          Row(
                            children: [
                              _InfoPill(
                                icon: Icons.star_rounded,
                                label: provider.rating.toStringAsFixed(1),
                                background: const Color(0xFFFFF5DD),
                                foreground: const Color(0xFFB45309),
                                compact: compact,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _InfoPill(
                                  icon: Icons.radio_button_checked_rounded,
                                  label: provider.isVerified
                                      ? 'Verified'
                                      : 'Open now',
                                  background: accent.withValues(alpha: 0.10),
                                  foreground: accent,
                                  compact: compact,
                                ),
                              ),
                            ],
                          ),
                          if (serviceChips.isNotEmpty) ...[
                            SizedBox(height: compact ? 10 : 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: serviceChips,
                            ),
                          ],
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 12 : 14,
                              vertical: compact ? 11 : 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: AppColors.divider.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  'View profile',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: compact ? 13 : 14,
                                      ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: compact ? 17 : 18,
                                  color: accent,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return PressableScale(
          onTap: onDetails,
          pressedScale: 0.988,
          child: isElite
              ? PremiumOutline(radius: 26, borderWidth: 2, child: card)
              : card,
        );
      },
    );
  }

  List<Widget> _serviceChips(BuildContext context, {required bool compact}) {
    final values = provider.services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .take(compact ? 1 : 2)
        .toList(growable: false);

    return values
        .map(
          (item) => Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 12,
              vertical: compact ? 7 : 8,
            ),
            decoration: BoxDecoration(
              color: provider.accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: provider.accentColor.withValues(alpha: 0.18),
              ),
            ),
            child: Text(
              item,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: provider.accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        )
        .toList(growable: false);
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) return 'SP';
    return parts.map((part) => part.substring(0, 1).toUpperCase()).join();
  }

  Color? _tierAccent(String tier) {
    switch (tier) {
      case 'elite':
        return const Color(0xFFF59E0B);
      case 'professional':
        return const Color(0xFF2563EB);
      default:
        return null;
    }
  }
}

class _ProviderAvatar extends StatelessWidget {
  final String imagePath;
  final Color accent;
  final String initials;
  final bool compact;

  const _ProviderAvatar({
    required this.imagePath,
    required this.accent,
    required this.initials,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final size = compact ? 66.0 : 74.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: imagePath.trim().isEmpty
          ? CircleAvatar(
              backgroundColor: const Color(0xFFE7F0FF),
              child: Text(
                initials,
                style: TextStyle(
                  color: accent,
                  fontSize: compact ? 24 : 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            )
          : ClipOval(
              child: SafeImage(
                isAvatar: true,
                source: imagePath,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final String providerUid;

  const _FavoriteButton({required this.providerUid});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoriteState.favoriteUids,
      builder: (context, favorites, _) {
        final isFav = favorites.contains(providerUid);
        return PressableScale(
          onTap: () => FavoriteState.toggleFavorite(providerUid),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 20,
              color: isFav ? AppColors.danger : AppColors.textSecondary,
            ),
          ),
        );
      },
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final bool compact;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 10,
        vertical: compact ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 15, color: foreground),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
