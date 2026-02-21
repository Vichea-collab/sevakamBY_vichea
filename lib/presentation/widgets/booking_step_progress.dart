import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum BookingFlowStep { address, details, serviceFields, payment, confirmation }

extension BookingFlowStepX on BookingFlowStep {
  String get label {
    switch (this) {
      case BookingFlowStep.address:
        return 'Address';
      case BookingFlowStep.details:
        return 'Details';
      case BookingFlowStep.serviceFields:
        return 'Service';
      case BookingFlowStep.payment:
        return 'Payment';
      case BookingFlowStep.confirmation:
        return 'Done';
    }
  }
}

class BookingStepProgress extends StatelessWidget {
  final BookingFlowStep currentStep;

  const BookingStepProgress({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = BookingFlowStep.values;
    final currentIndex = steps.indexOf(currentStep);
    var remaining = steps.length - currentIndex - 1;
    if (remaining < 0) remaining = 0;
    final progress = steps.length <= 1
        ? 1.0
        : currentIndex / (steps.length - 1);
    final remainingLabel = remaining == 0
        ? 'Completed'
        : '$remaining step${remaining > 1 ? 's' : ''} left';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Step ${currentIndex + 1} / ${steps.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                remainingLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++)
                Expanded(
                  child: Center(
                    child: _StepCircle(
                      number: index + 1,
                      active: index == currentIndex,
                      completed: index < currentIndex,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: steps
                .map(
                  (step) => Expanded(
                    child: Text(
                      step.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: step == currentStep
                            ? AppColors.primary
                            : AppColors.textSecondary,
                        fontWeight: step == currentStep
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  final int number;
  final bool active;
  final bool completed;

  const _StepCircle({
    required this.number,
    required this.active,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final background = completed || active ? AppColors.primary : Colors.white;
    final borderColor = completed || active
        ? AppColors.primary
        : AppColors.divider;
    final textColor = completed || active
        ? Colors.white
        : AppColors.textSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
          : Text(
              '$number',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
    );
  }
}
