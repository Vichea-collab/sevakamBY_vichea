import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/category_utils.dart';
import '../../domain/entities/category.dart';
import 'pressable_scale.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = accentForCategory(category.name);
    final softTint = isDark
        ? Color.lerp(accent, const Color(0xFF0F172A), 0.74)!
        : Color.lerp(accent, Colors.white, 0.86)!;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(rs.radius(24)),
        child: Container(
          width: rs.dimension(96, minFactor: 0.86, maxFactor: 1.02),
          padding: EdgeInsets.fromLTRB(
            rs.space(8),
            rs.space(10),
            rs.space(8),
            rs.space(10),
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(rs.radius(24)),
            border: Border.all(color: accent.withValues(alpha: 0.14)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: -14,
                offset: const Offset(0, 14),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                spreadRadius: -8,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: rs.space(8)),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [softTint, accent.withValues(alpha: 0.10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(rs.radius(18)),
                ),
                child: Center(
                  child: Container(
                    height: rs.dimension(42),
                    width: rs.dimension(42),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.72)
                          : Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconForCategory(category.name),
                      color: accent,
                      size: rs.icon(20),
                    ),
                  ),
                ),
              ),
              rs.gapH(6),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(
                    category.name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                      fontSize: rs.text(11.8),
                      height: 1.18,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
