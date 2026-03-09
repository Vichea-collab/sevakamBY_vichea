import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../state/app_role_state.dart';

enum AppBottomTab { home, notification, post, order, profile }

class AppBottomNav extends StatelessWidget {
  final AppBottomTab current;
  final ValueChanged<AppBottomTab>? onTabChanged;

  const AppBottomNav({
    super.key,
    required this.current,
    this.onTabChanged,
  });

  bool _isCurrent(AppBottomTab tab) => current == tab;

  void _goTo(BuildContext context, AppBottomTab tab) {
    if (_isCurrent(tab)) return;
    if (onTabChanged != null) {
      onTabChanged!(tab);
    } else {
      switch (tab) {
        case AppBottomTab.home:
          Navigator.pushReplacementNamed(context, AppRoleState.homeRoute());
          break;
        case AppBottomTab.notification:
          Navigator.pushReplacementNamed(context, AppRoleState.notificationRoute());
          break;
        case AppBottomTab.post:
          Navigator.pushReplacementNamed(context, AppRoleState.postRoute());
          break;
        case AppBottomTab.order:
          Navigator.pushReplacementNamed(context, AppRoleState.orderRoute());
          break;
        case AppBottomTab.profile:
          Navigator.pushReplacementNamed(context, AppRoleState.profileRoute());
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: 94 + bottomPadding,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            height: 68 + bottomPadding,
            padding: EdgeInsets.only(bottom: bottomPadding, left: 8, right: 8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A2D4678),
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
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.notifications_none_rounded,
                    label: 'Notification',
                    selected: _isCurrent(AppBottomTab.notification),
                    onTap: () => _goTo(context, AppBottomTab.notification),
                  ),
                ),
                const SizedBox(width: 80),
                Expanded(
                  child: _NavItem(
                    icon: Icons.list_alt_rounded,
                    label: 'Order',
                    selected: _isCurrent(AppBottomTab.order),
                    onTap: () => _goTo(context, AppBottomTab.order),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.person_rounded,
                    label: 'Profile',
                    selected: _isCurrent(AppBottomTab.profile),
                    onTap: () => _goTo(context, AppBottomTab.profile),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: bottomPadding + 20,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _goTo(context, AppBottomTab.post),
              child: SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: 0.785398, // 45deg: diamond
                      child: Container(
                        width: 62,
                        height: 62,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E63FF), Color(0xFF3EA2FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x4D1E63FF),
                              blurRadius: 18,
                              offset: Offset(0, 9),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 34,
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

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0x1F1E63FF)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
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
