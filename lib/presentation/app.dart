import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'pages/splash_page.dart';
import 'pages/welcome_page.dart';
import 'pages/onboarding_page.dart';
import 'pages/auth/customer_auth_page.dart';
import 'pages/auth/provider_auth_page.dart';
import 'pages/auth/forgot_password_flow.dart';
import 'pages/home/home_page.dart';
import 'pages/providers/provider_home_page.dart';
import 'pages/search/search_page.dart';
import 'pages/profile/profile_page.dart';
import 'pages/profile/edit_profile_page.dart';
import 'pages/profile/notification_page.dart';
import 'pages/profile/payment_page.dart';
import 'pages/profile/help_support_page.dart';

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
        SearchPage.routeName: (_) => const SearchPage(),
        ProfilePage.routeName: (_) => const ProfilePage(),
        EditProfilePage.routeName: (_) => const EditProfilePage(),
        ProfileNotificationPage.routeName: (_) => const ProfileNotificationPage(),
        PaymentPage.routeName: (_) => const PaymentPage(),
        HelpSupportPage.routeName: (_) => const HelpSupportPage(),
      },
    );
  }
}
