import 'package:flutter/material.dart';
import 'dart:async';

import '../core/theme/app_theme.dart';
import '../domain/entities/provider.dart';
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth/customer_auth_page.dart';
import 'pages/auth/provider_auth_page.dart';
import 'pages/auth/forgot_password_flow.dart';
import 'pages/home/home_page.dart';
import 'pages/providers/provider_home_page.dart';
import 'pages/providers/provider_posts_page.dart';
import 'pages/search/search_page.dart';
import 'pages/chat/chat_list_page.dart';
import 'pages/orders/orders_page.dart';
import 'pages/post/client_post_page.dart';
import 'pages/booking/booking_address_page.dart';
import 'pages/notifications/notifications_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/notification_page.dart';
import 'pages/profile/payment_page.dart';
import 'pages/profile/help_support_page.dart';
import 'pages/provider_portal/provider_home_page.dart';
import 'pages/provider_portal/provider_finder_search_page.dart';
import 'pages/provider_portal/provider_notifications_page.dart';
import 'pages/provider_portal/provider_post_page.dart';
import 'pages/provider_portal/provider_orders_page.dart';
import 'pages/provider_portal/provider_profile_page.dart';
import 'pages/provider_portal/provider_profession_page.dart';
import 'pages/provider_portal/provider_verification_page.dart';
import 'state/booking_catalog_state.dart';
import 'state/app_role_state.dart';
import 'state/user_notification_state.dart';

class ServiceFinderApp extends StatefulWidget {
  const ServiceFinderApp({super.key});

  @override
  State<ServiceFinderApp> createState() => _ServiceFinderAppState();
}

class _ServiceFinderAppState extends State<ServiceFinderApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: SplashPage.routeName,
      builder: (context, child) {
        return _GlobalNotificationHost(
          navigatorKey: _navigatorKey,
          child: child ?? const SizedBox.shrink(),
        );
      },
      routes: {
        SplashPage.routeName: (_) => const SplashPage(),
        WelcomePage.routeName: (_) => const WelcomePage(),
        OnboardingPage.routeName: (_) => const OnboardingPage(),
        CustomerAuthPage.routeName: (_) => const CustomerAuthPage(),
        ProviderAuthPage.routeName: (_) => const ProviderAuthPage(),
        ForgotPasswordFlow.routeName: (_) => const ForgotPasswordFlow(),
        HomePage.routeName: (_) => const HomePage(),
        ProviderHomePage.routeName: (_) => const ProviderHomePage(),
        ProviderPostsPage.routeName: (_) => const ProviderPostsPage(),
        SearchPage.routeName: (_) => const SearchPage(),
        ChatListPage.routeName: (_) => const ChatListPage(),
        OrdersPage.routeName: (_) => const OrdersPage(),
        ClientPostPage.routeName: (_) => const ClientPostPage(),
        NotificationsPage.routeName: (_) => const NotificationsPage(),
        '/booking/address': (_) => BookingAddressPage(
          draft: BookingCatalogState.defaultBookingDraft(
            provider: const ProviderItem(
              name: 'Service Provider',
              role: 'Cleaner',
              rating: 4.8,
              imagePath: 'assets/images/profile.jpg',
              accentColor: Color(0xFFEAF1FF),
            ),
          ),
        ),
        ProfilePage.routeName: (_) => const ProfilePage(),
        EditProfilePage.routeName: (_) => const EditProfilePage(),
        ProfileNotificationPage.routeName: (_) =>
            const ProfileNotificationPage(),
        PaymentPage.routeName: (_) => const PaymentPage(),
        HelpSupportPage.routeName: (_) => const HelpSupportPage(),
        ProviderPortalHomePage.routeName: (_) => const ProviderPortalHomePage(),
        ProviderFinderSearchPage.routeName: (_) =>
            const ProviderFinderSearchPage(),
        ProviderNotificationsPage.routeName: (_) =>
            const ProviderNotificationsPage(),
        ProviderPostPage.routeName: (_) => const ProviderPostPage(),
        ProviderOrdersPage.routeName: (_) => const ProviderOrdersPage(),
        ProviderProfilePage.routeName: (_) => const ProviderProfilePage(),
        ProviderProfessionPage.routeName: (_) => const ProviderProfessionPage(),
        ProviderVerificationPage.routeName: (_) =>
            const ProviderVerificationPage(),
      },
    );
  }
}

class _GlobalNotificationHost extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const _GlobalNotificationHost({
    required this.child,
    required this.navigatorKey,
  });

  @override
  State<_GlobalNotificationHost> createState() =>
      _GlobalNotificationHostState();
}

class _GlobalNotificationHostState extends State<_GlobalNotificationHost> {
  final Set<String> _seenNoticeIds = <String>{};
  OverlayEntry? _activeBannerEntry;
  Timer? _activeBannerTimer;
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    UserNotificationState.notices.addListener(_onNoticesChanged);
  }

  @override
  void dispose() {
    UserNotificationState.notices.removeListener(_onNoticesChanged);
    _removeActiveBanner();
    super.dispose();
  }

  void _onNoticesChanged() {
    if (!mounted) return;
    final notices = UserNotificationState.notices.value;
    if (notices.isEmpty) {
      _seenNoticeIds.clear();
      _primed = false;
      return;
    }

    if (!_primed) {
      _seenNoticeIds.addAll(notices.map((item) => item.id));
      _primed = true;
      return;
    }

    final fresh = notices
        .where((item) => !_seenNoticeIds.contains(item.id))
        .toList(growable: false);
    if (fresh.isEmpty) return;

    _seenNoticeIds.addAll(fresh.map((item) => item.id));
    final latest = fresh.reduce((left, right) {
      final leftTime = left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightTime =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightTime.isAfter(leftTime) ? right : left;
    });

    final summary = latest.message.trim().isEmpty
        ? 'You have a new notification.'
        : latest.message.trim();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _showTopBanner(title: latest.title.trim(), message: summary);
    });
  }

  void _showTopBanner({required String title, required String message}) {
    final overlay = widget.navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    _removeActiveBanner();
    final banner = OverlayEntry(
      builder: (context) {
        final safeTop = MediaQuery.of(context).padding.top + 10;
        return Positioned(
          top: safeTop,
          left: 12,
          right: 12,
          child: _TopNoticeBanner(
            title: title.isEmpty ? 'Platform update' : title,
            message: message,
            onView: () {
              _removeActiveBanner();
              final route = AppRoleState.notificationRoute();
              widget.navigatorKey.currentState?.pushNamed(route);
            },
            onDismiss: _removeActiveBanner,
          ),
        );
      },
    );
    _activeBannerEntry = banner;
    overlay.insert(banner);
    _activeBannerTimer = Timer(const Duration(seconds: 5), _removeActiveBanner);
  }

  void _removeActiveBanner() {
    _activeBannerTimer?.cancel();
    _activeBannerTimer = null;
    _activeBannerEntry?.remove();
    _activeBannerEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class _TopNoticeBanner extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onView;
  final VoidCallback onDismiss;

  const _TopNoticeBanner({
    required this.title,
    required this.message,
    required this.onView,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onView,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF252531),
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.notifications_active_rounded,
                  size: 18,
                  color: Color(0xFFBCA7FF),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$title: $message',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: onView,
                style: TextButton.styleFrom(
                  minimumSize: const Size(40, 30),
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: const Text(
                  'View',
                  style: TextStyle(
                    color: Color(0xFFD5C5FF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFFCFCFDD),
                ),
                constraints: const BoxConstraints.tightFor(
                  width: 26,
                  height: 26,
                ),
                padding: EdgeInsets.zero,
                splashRadius: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
