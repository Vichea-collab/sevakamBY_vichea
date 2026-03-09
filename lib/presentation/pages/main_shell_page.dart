import 'package:flutter/material.dart';
import '../state/app_role_state.dart';
import '../widgets/app_bottom_nav.dart';
import 'home/home_page.dart';
import 'notifications/notifications_page.dart';
import 'post/client_post_page.dart';
import 'orders/orders_page.dart';
import 'profile/profile_page.dart';
import 'provider_portal/provider_home_page.dart';
import 'provider_portal/provider_notifications_page.dart';
import 'provider_portal/provider_post_page.dart';
import 'provider_portal/provider_orders_page.dart';
import 'provider_portal/provider_profile_page.dart';

class MainShellPage extends StatefulWidget {
  static const String routeName = '/main';

  const MainShellPage({super.key});

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  static final ValueNotifier<AppBottomTab> activeTab =
      ValueNotifier(AppBottomTab.home);

  @override
  void initState() {
    super.initState();
    activeTab.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    activeTab.removeListener(_onTabChanged);
    super.dispose();
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isProvider = AppRoleState.isProvider;

    final children = isProvider
        ? const [
            ProviderPortalHomePage(),
            ProviderNotificationsPage(),
            ProviderPostPage(),
            ProviderOrdersPage(),
            ProviderProfilePage(),
          ]
        : const [
            HomePage(),
            NotificationsPage(),
            ClientPostPage(),
            OrdersPage(),
            ProfilePage(),
          ];

    return Scaffold(
      body: IndexedStack(
        index: activeTab.value.index,
        children: children,
      ),
      bottomNavigationBar: AppBottomNav(
        current: activeTab.value,
        onTabChanged: (tab) => activeTab.value = tab,
      ),
    );
  }
}
