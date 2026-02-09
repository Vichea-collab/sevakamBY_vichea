import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

enum AppDialogTone { primary, info, success, warning, danger }

Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required IconData icon,
  required String title,
  required String message,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
  AppDialogTone tone = AppDialogTone.primary,
  bool barrierDismissible = true,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => _AppConfirmDialog(
      icon: icon,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      tone: tone,
    ),
  );
}

class _AppConfirmDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final AppDialogTone tone;

  const _AppConfirmDialog({
    required this.icon,
    required this.title,
    required this.message,
    required this.confirmText,
    required this.cancelText,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _DialogColors.resolve(tone);
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.divider.withValues(alpha: 165)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x29000000),
                blurRadius: 30,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: colors.iconBackground,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, size: 34, color: colors.iconColor),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: colors.buttonGradient,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      textStyle: textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    child: Text(confirmText),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  cancelText,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
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

class _DialogColors {
  final List<Color> buttonGradient;
  final List<Color> iconBackground;
  final Color iconColor;

  const _DialogColors({
    required this.buttonGradient,
    required this.iconBackground,
    required this.iconColor,
  });

  static _DialogColors resolve(AppDialogTone tone) {
    switch (tone) {
      case AppDialogTone.info:
        return const _DialogColors(
          buttonGradient: [AppColors.primaryDark, AppColors.primary],
          iconBackground: [Color(0xFFEAF2FF), Color(0xFFDCEAFF)],
          iconColor: AppColors.primary,
        );
      case AppDialogTone.success:
        return const _DialogColors(
          buttonGradient: [Color(0xFF166534), Color(0xFF16A34A)],
          iconBackground: [Color(0xFFECFDF3), Color(0xFFDCFCE7)],
          iconColor: Color(0xFF15803D),
        );
      case AppDialogTone.warning:
        return const _DialogColors(
          buttonGradient: [Color(0xFFC46A03), Color(0xFFF59E0B)],
          iconBackground: [Color(0xFFFFF8E8), Color(0xFFFFF1D4)],
          iconColor: Color(0xFFD97706),
        );
      case AppDialogTone.danger:
        return const _DialogColors(
          buttonGradient: [Color(0xFFDC2626), Color(0xFFEF4444)],
          iconBackground: [Color(0xFFFFF1F2), Color(0xFFFFE4E6)],
          iconColor: AppColors.danger,
        );
      case AppDialogTone.primary:
        return const _DialogColors(
          buttonGradient: [AppColors.primary, AppColors.primaryLight],
          iconBackground: [Color(0xFFEAF2FF), Color(0xFFDCEAFF)],
          iconColor: AppColors.primary,
        );
    }
  }
}
