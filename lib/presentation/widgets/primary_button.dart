import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isOutlined;
  final EdgeInsetsGeometry? padding;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isOutlined = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: radius),
            side: const BorderSide(color: AppColors.primary),
          ),
          child: Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
          borderRadius: radius,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: padding ?? const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: radius),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
