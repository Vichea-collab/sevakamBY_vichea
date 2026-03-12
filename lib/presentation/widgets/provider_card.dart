import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/safe_image_provider.dart';
import '../../domain/entities/provider.dart';
import '../state/favorite_state.dart';
import 'pressable_scale.dart';

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
    final serviceChips = _serviceChips(context);
    final effectiveHeroTag = heroTag ?? 'provider-card-${provider.uid}';

    return PressableScale(
      onTap: onDetails,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.08),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Main card content with its own InkWell
            InkWell(
              onTap: onDetails,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Section: Image/Avatar background
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          provider.accentColor.withValues(alpha: 0.15),
                          provider.accentColor.withValues(alpha: 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Hero(
                        tag: effectiveHeroTag,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: provider.imagePath.trim().isEmpty
                              ? CircleAvatar(
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 40,
                                    color: provider.accentColor,
                                  ),
                                )
                              : ClipOval(
                                  child: SafeImage(
                                    isAvatar: true,
                                    source: provider.imagePath,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom Section: Info
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      provider.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.textPrimary,
                                            fontSize: 18,
                                            letterSpacing: -0.3,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.verified_rounded, size: 16, color: AppColors.primary),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 18, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 4),
                                  Text(
                                    provider.rating.toStringAsFixed(1),
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFFF59E0B),
                                          fontSize: 15,
                                        ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      provider.role,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            color: Theme.of(context).hintColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Horizontally scrollable services
                        if (serviceChips.isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: serviceChips
                                  .map((chip) => Padding(
                                        padding: const EdgeInsets.only(right: 6),
                                        child: chip,
                                      ))
                                  .toList(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Floating Favorite Button - Placed outside the main InkWell
            Positioned(
              top: 12,
              right: 12,
              child: ValueListenableBuilder<Set<String>>(
                valueListenable: FavoriteState.favoriteUids,
                builder: (context, favorites, _) {
                  final isFav = favorites.contains(provider.uid);
                  return PressableScale(
                    onTap: () => FavoriteState.toggleFavorite(provider.uid),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                        color: isFav ? AppColors.danger : AppColors.textSecondary,
                        size: 20,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _serviceChips(BuildContext context) {
    final values = provider.services
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList(growable: false);
    
    return values.map(
      (item) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: provider.accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: provider.accentColor.withValues(alpha: 0.15)),
        ),
        child: Text(
          item,
          maxLines: 1,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: provider.accentColor,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    ).toList();
  }
}
