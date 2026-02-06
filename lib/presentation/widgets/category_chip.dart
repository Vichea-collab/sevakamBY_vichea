import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/category.dart';
import 'pressable_scale.dart';

class CategoryChip extends StatelessWidget {
  final Category category;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.category,
    this.onTap,
  });

  IconData _iconFor(String name) {
    switch (name) {
      case 'plumber':
        return Icons.plumbing;
      case 'electrician':
        return Icons.bolt;
      case 'cleaner':
        return Icons.cleaning_services;
      case 'appliance':
        return Icons.ac_unit;
      case 'maintenance':
        return Icons.handyman;
      default:
        return Icons.handyman;
    }
  }

  Color _accentFor(String name) {
    switch (name) {
      case 'plumber':
        return const Color(0xFF0284C7);
      case 'electrician':
        return const Color(0xFFF59E0B);
      case 'cleaner':
        return const Color(0xFF10B981);
      case 'appliance':
        return const Color(0xFF6366F1);
      case 'maintenance':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentFor(category.icon);
    return PressableScale(
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 108,
          height: 130,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: accent,
                child: Icon(_iconFor(category.icon), color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
