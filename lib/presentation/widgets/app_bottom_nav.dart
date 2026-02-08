import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../state/app_role_state.dart';

enum AppBottomTab { home, notification, post, order, profile }

class AppBottomNav extends StatelessWidget {
  final AppBottomTab current;

  const AppBottomNav({super.key, required this.current});

  int _indexFor(AppBottomTab tab) {
    switch (tab) {
      case AppBottomTab.home:
        return 0;
      case AppBottomTab.notification:
        return 1;
      case AppBottomTab.post:
        return 2;
      case AppBottomTab.order:
        return 3;
      case AppBottomTab.profile:
        return 4;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: _indexFor(current),
      onTap: (index) {
        switch (index) {
          case 0:
            if (current != AppBottomTab.home) {
              Navigator.pushReplacementNamed(context, AppRoleState.homeRoute());
            }
            break;
          case 1:
            if (current != AppBottomTab.notification) {
              Navigator.pushReplacementNamed(
                context,
                AppRoleState.notificationRoute(),
              );
            }
            break;
          case 2:
            if (current != AppBottomTab.post) {
              Navigator.pushReplacementNamed(context, AppRoleState.postRoute());
            }
            break;
          case 3:
            if (current != AppBottomTab.order) {
              Navigator.pushReplacementNamed(context, AppRoleState.orderRoute());
            }
            break;
          case 4:
            if (current != AppBottomTab.profile) {
              Navigator.pushReplacementNamed(
                context,
                AppRoleState.profileRoute(),
              );
            }
            break;
        }
      },
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: 'Notification',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Post'),
        BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Order'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
