import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum AppStatePanelType { loading, empty, error }

class AppStatePanel extends StatelessWidget {
  final AppStatePanelType type;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStatePanel({
    super.key,
    required this.type,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  const AppStatePanel.loading({
    super.key,
    this.title = 'Loading data...',
    this.message,
  }) : type = AppStatePanelType.loading,
       actionLabel = null,
       onAction = null;

  const AppStatePanel.empty({
    super.key,
    this.title = 'No data available',
    this.message,
  }) : type = AppStatePanelType.empty,
       actionLabel = null,
       onAction = null;

  const AppStatePanel.error({
    super.key,
    this.title = 'Something went wrong',
    this.message,
    this.actionLabel = 'Try again',
    required this.onAction,
  }) : type = AppStatePanelType.error;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(type);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: visual.background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(visual.icon, color: visual.foreground),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if ((message ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              message!.trim(),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (type == AppStatePanelType.loading) ...[
            const SizedBox(height: 12),
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          if (type == AppStatePanelType.error && onAction != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(actionLabel ?? 'Try again'),
            ),
          ],
        ],
      ),
    );
  }

  _StatePanelVisual _visualFor(AppStatePanelType nextType) {
    switch (nextType) {
      case AppStatePanelType.loading:
        return const _StatePanelVisual(
          icon: Icons.hourglass_top_rounded,
          background: Color(0xFFEAF1FF),
          foreground: AppColors.primary,
        );
      case AppStatePanelType.empty:
        return const _StatePanelVisual(
          icon: Icons.inbox_rounded,
          background: Color(0xFFF3F5F9),
          foreground: AppColors.textSecondary,
        );
      case AppStatePanelType.error:
        return const _StatePanelVisual(
          icon: Icons.warning_amber_rounded,
          background: Color(0xFFFFF4ED),
          foreground: AppColors.warning,
        );
    }
  }
}

class _StatePanelVisual {
  final IconData icon;
  final Color background;
  final Color foreground;

  const _StatePanelVisual({
    required this.icon,
    required this.background,
    required this.foreground,
  });
}
