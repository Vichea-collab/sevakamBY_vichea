import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/category_utils.dart';
import '../../domain/entities/category.dart';
import 'pressable_scale.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryChip({super.key, required this.category, this.onTap});

  @override
  Widget build(BuildContext context) {
    final accent = accentForCategory(category.name);
    final softTint = Color.lerp(accent, Colors.white, 0.86)!;
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 102,
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 14),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [softTint, accent.withValues(alpha: 0.10)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconForCategory(category.name),
                      color: accent,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      color: AppColors.textPrimary,
                      fontSize: 13.5,
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
