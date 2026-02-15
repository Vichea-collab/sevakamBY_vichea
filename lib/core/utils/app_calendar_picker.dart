import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

Future<DateTime?> showAppCalendarDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String confirmText = 'Apply',
  String cancelText = 'Cancel',
}) {
  final normalizedInitial = _normalizeDate(initialDate);
  final normalizedFirst = _normalizeDate(firstDate);
  final normalizedLast = _normalizeDate(lastDate);

  final safeInitial = normalizedInitial.isBefore(normalizedFirst)
      ? normalizedFirst
      : normalizedInitial.isAfter(normalizedLast)
      ? normalizedLast
      : normalizedInitial;

  return showDatePicker(
    context: context,
    initialDate: safeInitial,
    firstDate: normalizedFirst,
    lastDate: normalizedLast,
    helpText: helpText,
    confirmText: confirmText,
    cancelText: cancelText,
    builder: (context, child) {
      final base = Theme.of(context);
      return Theme(
        data: base.copyWith(
          colorScheme: base.colorScheme.copyWith(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: AppColors.textPrimary,
          ),
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            headerForegroundColor: Colors.white,
            headerBackgroundColor: AppColors.primary,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppColors.textPrimary;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return null;
            }),
            todayForegroundColor: const WidgetStatePropertyAll(AppColors.primary),
            todayBorder: const BorderSide(color: AppColors.primary),
            yearForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return AppColors.textPrimary;
            }),
            yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return null;
            }),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            confirmButtonStyle: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
