import 'package:flutter/material.dart';
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

class ServiceFinderApp extends StatelessWidget {
  const ServiceFinderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: SplashPage.routeName,
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
