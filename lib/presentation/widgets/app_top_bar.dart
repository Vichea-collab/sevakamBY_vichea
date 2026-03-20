import 'package:flutter/material.dart';
import '../../core/utils/responsive.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final bool showDivider;
  final bool showBack;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.actions = const <Widget>[],
    this.showDivider = false,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        rs.space(4),
        rs.space(6),
        rs.space(4),
        rs.space(10),
      ),
      child: Row(
        children: [
          if (showBack) ...[
            _BackButton(onTap: onBack ?? () => Navigator.maybePop(context)),
            rs.gapW(8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null) ...[
                  rs.gapH(1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );

    if (!showDivider) return header;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        header,
        Container(height: 1, color: theme.dividerColor),
      ],
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(rs.radius(12)),
      onTap: onTap,
      child: Ink(
        height: rs.dimension(38),
        width: rs.dimension(38),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF172233) : Colors.white,
          borderRadius: BorderRadius.circular(rs.radius(12)),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.07),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.arrow_back_rounded,
          size: 19,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
