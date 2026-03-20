import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/safe_image_provider.dart';
import '../../domain/entities/service.dart';
import 'pressable_scale.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem item;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rs.radius(20)),
        child: Container(
          width: rs.dimension(200, minFactor: 0.8, maxFactor: 1.05),
          padding: rs.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(rs.radius(20)),
            border: Border.all(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Hero(
                    tag: 'service-${item.title}',
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(rs.radius(16)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(rs.radius(16)),
                        child: SafeImage(
                          source: item.imagePath,
                          height: rs.dimension(110),
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    top: 10,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: rs.space(10),
                        vertical: rs.space(5),
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(rs.radius(10)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        item.badge,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              rs.gapH(14),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              rs.gapH(10),
              Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: rs.icon(18),
                    color: const Color(0xFFF59E0B),
                  ),
                  rs.gapW(4),
                  Text(
                    item.rating.toStringAsFixed(1),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: rs.all(6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(rs.radius(10)),
                    ),
                    child: Icon(
                      Icons.arrow_forward_rounded,
                      size: rs.icon(16),
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
