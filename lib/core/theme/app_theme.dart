import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData light({double scale = 1}) {
    final base = ThemeData.light();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      cardColor: Colors.white,
      dividerColor: AppColors.divider,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: _font(24, scale),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: _font(18, scale),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: _font(16, scale),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: _font(14, scale),
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x12000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius(18, scale)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius(24, scale)),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _font(22, scale),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _font(14, scale),
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: _space(14, scale),
            horizontal: _space(20, scale),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius(14, scale)),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: _font(14, scale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius(14, scale)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: Colors.transparent,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _space(16, scale),
          vertical: _space(14, scale),
        ),
      ),
    );
  }

  static ThemeData dark({double scale = 1}) {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDark,
      canvasColor: AppColors.bgDark,
      shadowColor: Colors.black,
      dividerColor: AppColors.dividerDark,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surfaceDark,
        primaryContainer: const Color(0xFF172554),
        secondaryContainer: const Color(0xFF0F3A44),
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimaryDark,
        onSecondary: Colors.white,
        onPrimaryContainer: const Color(0xFFDCE8FF),
        onSecondaryContainer: const Color(0xFFC8FFF7),
      ),
      textTheme: GoogleFonts.poppinsTextTheme(base.textTheme).copyWith(
        titleLarge: GoogleFonts.poppins(
          fontSize: _font(24, scale),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: _font(18, scale),
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: _font(16, scale),
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimaryDark,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: _font(14, scale),
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius(18, scale)),
          side: const BorderSide(color: AppColors.dividerDark),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius(24, scale)),
        ),
        titleTextStyle: GoogleFonts.poppins(
          fontSize: _font(22, scale),
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimaryDark,
        ),
        contentTextStyle: GoogleFonts.poppins(
          fontSize: _font(14, scale),
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondaryDark,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimaryDark,
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.5);
          }
          return const Color(0xFF243244);
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryLight;
          }
          return const Color(0xFFBAC7D9);
        }),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: const Color(0xFF182335),
        selectedColor: AppColors.primary.withValues(alpha: 0.2),
        side: const BorderSide(color: AppColors.dividerDark),
        labelStyle: GoogleFonts.poppins(
          color: AppColors.textPrimaryDark,
          fontWeight: FontWeight.w600,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          backgroundColor: const Color(0xFF172233),
          disabledBackgroundColor: const Color(0xFF111827),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            vertical: _space(14, scale),
            horizontal: _space(20, scale),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius(14, scale)),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: _font(14, scale),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimaryDark,
          side: const BorderSide(color: AppColors.dividerDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_radius(14, scale)),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111C2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.dividerDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius(14, scale)),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _space(16, scale),
          vertical: _space(14, scale),
        ),
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondaryDark,
          fontSize: _font(14, scale),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textPrimaryDark,
        textColor: AppColors.textPrimaryDark,
      ),
    );
  }

  static double _font(double value, double scale) =>
      (value * scale).clamp(value * 0.92, value * 1.12);

  static double _space(double value, double scale) =>
      (value * scale).clamp(value * 0.85, value * 1.2);

  static double _radius(double value, double scale) =>
      (value * scale).clamp(value * 0.9, value * 1.15);
}
