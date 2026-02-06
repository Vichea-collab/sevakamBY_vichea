import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StepIndicator extends StatelessWidget {
  final int count;
  final int index;

  const StepIndicator({
    super.key,
    required this.count,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: isActive ? 18 : 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : AppColors.divider,
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
