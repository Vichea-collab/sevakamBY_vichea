import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool onDark;

  const VerifiedBadge({super.key, this.size = 14, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final background = onDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFFEAF2FF);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFFC9DAFF);
    final foreground = onDark ? Colors.white : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: size, color: foreground),
          const SizedBox(width: 6),
          Text(
            'VERIFIED',
            style: TextStyle(
              color: foreground,
              fontSize: size * 0.62,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}
