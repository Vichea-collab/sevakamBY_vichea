import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/responsive.dart';
import '../state/app_role_state.dart';
import '../state/profile_image_state.dart';

enum AppBottomTab { home, notification, post, order, profile }

class AppBottomNav extends StatelessWidget {
  final AppBottomTab current;
  final ValueChanged<AppBottomTab>? onTabChanged;

  const AppBottomNav({super.key, required this.current, this.onTabChanged});

  bool _isCurrent(AppBottomTab tab) => current == tab;

  void _goTo(BuildContext context, AppBottomTab tab) {
    if (_isCurrent(tab)) return;
    if (onTabChanged != null) {
      onTabChanged!(tab);
    } else {
      Navigator.pushReplacementNamed(context, '/main');
    }
  }

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const accentColor = AppColors.primary;
    final isProvider = AppRoleState.isProvider;
    final navHeight = rs.dimension(68);
    final totalHeight = rs.dimension(94);
    final fabSize = rs.dimension(76);
    final fabDiamond = rs.dimension(62);
    final centerGap = rs.dimension(rs.compact ? 68 : 80);

    return SizedBox(
      height: totalHeight + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: navHeight + bottomPadding,
            padding: EdgeInsets.only(
              bottom: bottomPadding,
              left: rs.space(8),
              right: rs.space(8),
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0E1727) : Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(rs.radius(20)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.10),
                  blurRadius: 20,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    selected: _isCurrent(AppBottomTab.home),
                    onTap: () => _goTo(context, AppBottomTab.home),
                    accentColor: accentColor,
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.notifications_none_rounded,
                    label: isProvider ? 'Inbox' : 'Inbox',
                    selected: _isCurrent(AppBottomTab.notification),
                    onTap: () => _goTo(context, AppBottomTab.notification),
                    accentColor: accentColor,
                  ),
                ),
                SizedBox(width: centerGap),
                Expanded(
                  child: _NavItem(
                    icon: Icons.list_alt_rounded,
                    label: 'Orders',
                    selected: _isCurrent(AppBottomTab.order),
                    onTap: () => _goTo(context, AppBottomTab.order),
                    accentColor: accentColor,
                  ),
                ),
                Expanded(
                  child: _ProfileNavItem(
                    label: 'Profile',
                    selected: _isCurrent(AppBottomTab.profile),
                    onTap: () => _goTo(context, AppBottomTab.profile),
                    accentColor: accentColor,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: bottomPadding + rs.space(20),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _goTo(context, AppBottomTab.post),
              child: SizedBox(
                width: fabSize,
                height: fabSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.785398, // 45deg: diamond
                      child: Container(
                        width: fabDiamond,
                        height: fabDiamond,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E63FF), Color(0xFF3EA2FF)],
                          ),
                          borderRadius: BorderRadius.circular(rs.radius(16)),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF0E1727)
                                : Colors.white,
                            width: rs.space(3),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.3),
                              blurRadius: rs.space(18),
                              offset: Offset(0, rs.space(9)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Icon(
                      isProvider ? Icons.post_add_rounded : Icons.add_rounded,
                      color: Colors.white,
                      size: rs.icon(isProvider ? 30 : 34),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavItem extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _ProfileNavItem({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final color = selected
        ? accentColor
        : theme.bottomNavigationBarTheme.unselectedItemColor ??
              AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(rs.radius(14)),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rs.space(7)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: ProfileImageState.listenable,
              builder: (context, _, child) {
                final image = ProfileImageState.avatarProvider();
                final hasImage = ProfileImageState.hasCustomAvatar;

                return Container(
                  width: rs.dimension(36),
                  height: rs.dimension(36),
                  decoration: BoxDecoration(
                    color: selected
                        ? accentColor.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: selected
                        ? Border.all(
                            color: accentColor.withValues(alpha: 0.2),
                            width: 1,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: hasImage && image != null
                      ? CircleAvatar(
                          radius: rs.dimension(14),
                          backgroundColor: theme.scaffoldBackgroundColor,
                          backgroundImage: image,
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: rs.icon(24),
                          color: color,
                        ),
                );
              },
            ),
            rs.gapH(2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rs.text(10, minFactor: 0.96, maxFactor: 1.08),
                height: 1.05,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color accentColor;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final rs = context.rs;
    final theme = Theme.of(context);
    final color = selected
        ? accentColor
        : theme.bottomNavigationBarTheme.unselectedItemColor ??
              AppColors.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(rs.radius(14)),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: rs.space(7)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: rs.dimension(36),
              height: rs.dimension(36),
              decoration: BoxDecoration(
                color: selected
                    ? accentColor.withValues(alpha: 0.15)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: rs.icon(24), color: color),
            ),
            rs.gapH(2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: rs.text(10, minFactor: 0.96, maxFactor: 1.08),
                height: 1.05,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
