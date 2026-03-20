import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
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
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final effectiveHeroTag = heroTag ?? 'provider-card-${provider.uid}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < rs.dimension(350) ||
            constraints.maxWidth < rs.dimension(210);
        final veryCompact =
            constraints.maxHeight < rs.dimension(320) ||
            constraints.maxWidth < rs.dimension(190);
        final tier = provider.subscriptionTier.toLowerCase().trim();
        final isElite = tier == 'elite';
        final accent = _tierAccent(tier) ?? provider.accentColor;
        final softTint = isDark
            ? Color.lerp(
                accent,
                const Color(0xFF0F172A),
                isElite ? 0.68 : 0.76,
              )!
            : isElite
            ? const Color(0xFFFFF4D6)
            : Color.lerp(accent, Colors.white, 0.82)!;
        final serviceChips = _serviceChips(
          context,
          compact: compact,
          hidden: veryCompact,
        );
        final name = provider.name.trim().isEmpty
            ? 'Service Provider'
            : provider.name.trim();
        final card = Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF101B2D) : Colors.white,
            borderRadius: BorderRadius.circular(rs.radius(26)),
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
                    height: veryCompact
                        ? rs.dimension(88)
                        : compact
                        ? rs.dimension(96)
                        : rs.dimension(108),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: veryCompact
                              ? rs.dimension(64)
                              : compact
                              ? rs.dimension(70)
                              : rs.dimension(78),
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                softTint,
                                isElite
                                    ? (isDark
                                          ? const Color(0xFF1D2433)
                                          : const Color(0xFFFFF9EA))
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
                                  width: compact
                                      ? rs.dimension(78)
                                      : rs.dimension(92),
                                  height: compact
                                      ? rs.dimension(78)
                                      : rs.dimension(92),
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
                          top: veryCompact
                              ? rs.space(24)
                              : compact
                              ? rs.space(26)
                              : rs.space(32),
                          left: rs.space(18),
                          child: Hero(
                            tag: effectiveHeroTag,
                            child: _ProviderAvatar(
                              imagePath: provider.imagePath,
                              accent: accent,
                              compact: compact || veryCompact,
                            ),
                          ),
                        ),
                        Positioned(
                          top: rs.space(14),
                          right: rs.space(14),
                          child: _FavoriteButton(providerUid: provider.uid),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        rs.space(16),
                        veryCompact
                            ? rs.space(10)
                            : compact
                            ? rs.space(12)
                            : rs.space(14),
                        rs.space(16),
                        veryCompact
                            ? rs.space(10)
                            : compact
                            ? rs.space(12)
                            : rs.space(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (provider.isVerified || tier != 'basic') ...[
                            Wrap(
                              spacing: rs.space(8),
                              runSpacing: rs.space(6),
                              children: [
                                if (provider.isVerified)
                                  VerifiedBadge(
                                    size: veryCompact
                                        ? 10
                                        : compact
                                        ? 11
                                        : 12,
                                  ),
                                if (tier != 'basic')
                                  SubscriptionBadge.fromString(
                                    provider.subscriptionTier,
                                    size: veryCompact
                                        ? 11
                                        : compact
                                        ? 12
                                        : 14,
                                  ),
                              ],
                            ),
                            SizedBox(
                              height: veryCompact
                                  ? rs.space(6)
                                  : compact
                                  ? rs.space(8)
                                  : rs.space(10),
                            ),
                          ],
                          Text(
                            name,
                            maxLines: compact ? 1 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: veryCompact
                                      ? rs.text(15.5)
                                      : compact
                                      ? rs.text(17)
                                      : rs.text(19),
                                  fontWeight: FontWeight.w800,
                                  height: 1.08,
                                  letterSpacing: -0.35,
                                ),
                          ),
                          SizedBox(
                            height: veryCompact
                                ? rs.space(3)
                                : compact
                                ? rs.space(4)
                                : rs.space(6),
                          ),
                          Text(
                            provider.role,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: theme.textTheme.bodyMedium?.color,
                                  fontSize: veryCompact
                                      ? rs.text(11.5)
                                      : compact
                                      ? rs.text(12.5)
                                      : rs.text(13.5),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          SizedBox(
                            height: veryCompact
                                ? rs.space(8)
                                : compact
                                ? rs.space(10)
                                : rs.space(12),
                          ),
                          Row(
                            children: [
                              _InfoPill(
                                icon: Icons.star_rounded,
                                label: provider.rating.toStringAsFixed(1),
                                background: const Color(0xFFFFF5DD),
                                foreground: const Color(0xFFB45309),
                                compact: compact || veryCompact,
                              ),
                              rs.gapW(8),
                              Expanded(
                                child: _InfoPill(
                                  icon: Icons.radio_button_checked_rounded,
                                  label: 'Open now',
                                  background: accent.withValues(alpha: 0.10),
                                  foreground: accent,
                                  compact: compact || veryCompact,
                                ),
                              ),
                            ],
                          ),
                          if (serviceChips.isNotEmpty) ...[
                            SizedBox(
                              height: compact ? rs.space(10) : rs.space(12),
                            ),
                            Wrap(
                              spacing: rs.space(8),
                              runSpacing: rs.space(8),
                              children: serviceChips,
                            ),
                          ],
                          const Spacer(),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              horizontal: veryCompact
                                  ? rs.space(10)
                                  : compact
                                  ? rs.space(12)
                                  : rs.space(14),
                              vertical: veryCompact
                                  ? rs.space(9)
                                  : compact
                                  ? rs.space(11)
                                  : rs.space(12),
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF162133)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(
                                rs.radius(18),
                              ),
                              border: Border.all(
                                color: theme.dividerColor.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'View profile',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: theme.colorScheme.onSurface,
                                          fontWeight: FontWeight.w700,
                                          fontSize: veryCompact
                                              ? rs.text(12)
                                              : compact
                                              ? rs.text(13)
                                              : rs.text(14),
                                        ),
                                  ),
                                ),
                                SizedBox(width: rs.space(8)),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: veryCompact
                                      ? rs.icon(16)
                                      : compact
                                      ? rs.icon(17)
                                      : rs.icon(18),
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

  List<Widget> _serviceChips(
    BuildContext context, {
    required bool compact,
    required bool hidden,
  }) {
    if (hidden) return const <Widget>[];
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
  final bool compact;

  const _ProviderAvatar({
    required this.imagePath,
    required this.accent,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedSize = compact ? rs.dimension(66) : rs.dimension(74);

    return Container(
      width: resolvedSize,
      height: resolvedSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? const Color(0xFF101B2D) : Colors.white,
          width: 4,
        ),
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
              backgroundColor: isDark
                  ? const Color(0xFF1B2840)
                  : const Color(0xFFEAF1FF),
              child: Icon(
                Icons.person_rounded,
                color: accent,
                size: compact ? rs.icon(30) : rs.icon(34),
              ),
            )
          : ClipOval(
              child: SafeImage(
                isAvatar: true,
                source: imagePath,
                width: resolvedSize,
                height: resolvedSize,
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
    final rs = context.rs;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ValueListenableBuilder<Set<String>>(
      valueListenable: FavoriteState.favoriteUids,
      builder: (context, favorites, _) {
        final isFav = favorites.contains(providerUid);
        return PressableScale(
          onTap: () => FavoriteState.toggleFavorite(providerUid),
          child: Container(
            width: rs.dimension(40),
            height: rs.dimension(40),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF172233).withValues(alpha: 0.96)
                  : Colors.white.withValues(alpha: 0.94),
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
              size: rs.icon(20),
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
    final rs = context.rs;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? rs.space(9) : rs.space(10),
        vertical: compact ? rs.space(6) : rs.space(7),
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(rs.radius(999)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: compact ? rs.icon(13) : rs.icon(15),
            color: foreground,
          ),
          rs.gapW(6),
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
