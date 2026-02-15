import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'pressable_scale.dart';

enum PrimaryButtonTone { primary, success, danger, neutral }

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;
  final IconData? icon;
  final bool iconTrailing;
  final PrimaryButtonTone tone;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.padding,
    this.icon,
    this.iconTrailing = false,
    this.tone = PrimaryButtonTone.primary,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final toneColor = _toneColor(tone);
    final enabled = onPressed != null;
    final fillGradient = _fillGradient(tone, enabled: enabled);
    final labelColor = enabled ? Colors.white : Colors.white70;
    final labelStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
      color: labelColor,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    Widget childLabel = Text(label, style: labelStyle);
    if (icon != null) {
      childLabel = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!iconTrailing) ...[
            Icon(icon, size: 18, color: labelColor),
            const SizedBox(width: 8),
          ],
          Text(label, style: labelStyle),
          if (iconTrailing) ...[
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: labelColor),
          ],
        ],
      );
    }

    if (isOutlined) {
      return PressableScale(
        onTap: onPressed,
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: labelColor,
              backgroundColor: enabled ? toneColor : const Color(0xFF64748B),
              disabledForegroundColor: Colors.white70,
              padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: radius),
              side: BorderSide(
                color: enabled ? toneColor : const Color(0xFF64748B),
              ),
            ),
            child: childLabel,
          ),
        ),
      );
    }
    return PressableScale(
      onTap: onPressed,
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: fillGradient,
            borderRadius: radius,
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: toneColor.withValues(alpha: 64),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: radius),
            ),
            child: childLabel,
          ),
        ),
      ),
    );
  }

  Color _toneColor(PrimaryButtonTone value) {
    switch (value) {
      case PrimaryButtonTone.success:
        return AppColors.success;
      case PrimaryButtonTone.danger:
        return AppColors.danger;
      case PrimaryButtonTone.neutral:
        return const Color(0xFF334155);
      case PrimaryButtonTone.primary:
        return AppColors.primary;
    }
  }

  Gradient _fillGradient(PrimaryButtonTone value, {required bool enabled}) {
    if (!enabled) {
      return const LinearGradient(
        colors: [Color(0xFF94A3B8), Color(0xFF64748B)],
      );
    }
    switch (value) {
      case PrimaryButtonTone.success:
        return const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF22C55E)],
        );
      case PrimaryButtonTone.danger:
        return const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFEF4444)],
        );
      case PrimaryButtonTone.neutral:
        return const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF64748B)],
        );
      case PrimaryButtonTone.primary:
        return const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
        );
    }
  }
}
