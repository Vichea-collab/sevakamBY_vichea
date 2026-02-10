import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum AppToastType { success, error, warning, info }

class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void success(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.error);
  }

  static void warning(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.warning);
  }

  static void info(BuildContext context, String message) {
    show(context, message: message, type: AppToastType.info);
  }

  static void show(
    BuildContext context, {
    required String message,
    AppToastType type = AppToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _removeCurrent();

    final style = _ToastStyle.forType(type);
    _entry = OverlayEntry(
      builder: (overlayContext) {
        final media = MediaQuery.of(overlayContext);
        final maxWidth = media.size.width > 560 ? 430.0 : media.size.width - 24;
        return Positioned(
          top: media.padding.top + 12,
          right: 12,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset((1 - value) * 18, (1 - value) * -4),
                    child: child,
                  ),
                );
              },
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: _ToastCard(message: trimmed, style: style),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_entry!);
    _timer = Timer(duration, _removeCurrent);
  }

  static void _removeCurrent() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastStyle {
  final Color background;
  final Color accent;
  final Color iconBackground;
  final Color iconColor;
  final IconData icon;

  const _ToastStyle({
    required this.background,
    required this.accent,
    required this.iconBackground,
    required this.iconColor,
    required this.icon,
  });

  factory _ToastStyle.forType(AppToastType type) {
    switch (type) {
      case AppToastType.success:
        return const _ToastStyle(
          background: Color(0xFFEFF7F0),
          accent: AppColors.success,
          iconBackground: Color(0xFF28A745),
          iconColor: Colors.white,
          icon: Icons.check_rounded,
        );
      case AppToastType.error:
        return const _ToastStyle(
          background: Color(0xFFFDEDED),
          accent: AppColors.danger,
          iconBackground: AppColors.danger,
          iconColor: Colors.white,
          icon: Icons.close_rounded,
        );
      case AppToastType.warning:
        return const _ToastStyle(
          background: Color(0xFFFFF6E8),
          accent: AppColors.warning,
          iconBackground: AppColors.warning,
          iconColor: Colors.white,
          icon: Icons.priority_high_rounded,
        );
      case AppToastType.info:
        return const _ToastStyle(
          background: Color(0xFFEAF1FF),
          accent: AppColors.primary,
          iconBackground: AppColors.primary,
          iconColor: Colors.white,
          icon: Icons.info_outline_rounded,
        );
    }
  }
}

class _ToastCard extends StatelessWidget {
  final String message;
  final _ToastStyle style;

  const _ToastCard({required this.message, required this.style});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: style.accent.withValues(alpha: 0.16)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: style.iconBackground,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(style.icon, size: 24, color: style.iconColor),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    message,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: style.accent,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
