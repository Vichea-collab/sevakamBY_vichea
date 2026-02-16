import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../presentation/pages/admin_dashboard_page.dart';
import '../presentation/pages/admin_login_page.dart';

class AdminWebApp extends StatelessWidget {
  static const String loginRoute = '/';
  static const String dashboardRoute = '/dashboard';

  final bool firebaseReady;

  const AdminWebApp({super.key, required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.plusJakartaSansTextTheme();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sevakam Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFEFF4FF),
        textTheme: baseText.copyWith(
          titleLarge: baseText.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          bodyMedium: baseText.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        iconTheme: const IconThemeData(size: 24),
        iconButtonTheme: const IconButtonThemeData(
          style: ButtonStyle(iconSize: WidgetStatePropertyAll<double>(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DEEF)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD5DEEF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
          ),
        ),
      ),
      initialRoute: loginRoute,
      routes: {
        loginRoute: (_) => AdminLoginPage(firebaseReady: firebaseReady),
        dashboardRoute: (_) => const AdminDashboardPage(),
      },
    );
  }
}
