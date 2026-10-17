import 'package:flutter/material.dart';

class AppColors {
  static const ink = Color(0xFF2B2D3B);
  static const navy = Color(0xFF2B2D3B);
  static const navyDeep = Color(0xFF232430);
  static const card = Color(0xFF383A4B);
  static const cardAlt = Color(0xFF494C65);
  static const gold = Color(0xFFDDDE68);
  static const cyan = Color(0xFFA5B2EB);
  static const teal = Color(0xFFDA935D);
  static const slate = Color(0xFF494C65);
  static const mist = Color(0xFFC3C7E0);
  static const line = Color(0xFF676386);
  static const danger = Color(0xFFFF6B6B);
}

class AppFonts {
  static const heading = 'Sora';
  static const body = 'Inter';
}

class AppTheme {
  static OutlineInputBorder _border(Color c, [double w = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  /// Soft raised surface used by cards across the app.
  static BoxDecoration surfaceCard({Color? border, double radius = 18}) =>
      BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardAlt, AppColors.card],
        ),
        border: Border.all(
          color: border ?? AppColors.line,
          width: 1,
        ),
      );

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: AppColors.gold,
      onPrimary: AppColors.navy,
      secondary: AppColors.cyan,
      onSecondary: AppColors.navy,
      tertiary: AppColors.teal,
      onTertiary: AppColors.navy,
      surface: AppColors.card,
      onSurface: Colors.white,
      error: AppColors.danger,
      onError: AppColors.navy,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: AppFonts.body,
      scaffoldBackgroundColor: AppColors.navy,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        toolbarHeight: 64,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.heading,
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontSize: 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
        headlineSmall: TextStyle(
          fontFamily: AppFonts.heading,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
        titleLarge: TextStyle(
          fontFamily: AppFonts.heading,
          fontSize: 19,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          fontFamily: AppFonts.heading,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 15,
          height: 1.45,
        ),
        bodyMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12.5,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelMedium: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.mist,
        titleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.mist,
          fontSize: 12.5,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: AppColors.navyDeep,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        indicatorShape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.transparent),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (s) => IconThemeData(
            size: 24,
            color: s.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.mist,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (s) => TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: s.contains(WidgetState.selected)
                ? AppColors.gold
                : AppColors.mist,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.slate.withValues(alpha: 0.45),
        labelStyle: const TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.mist,
          fontSize: 14,
        ),
        hintStyle: TextStyle(
          fontFamily: AppFonts.body,
          color: AppColors.mist.withValues(alpha: 0.6),
          fontSize: 14,
        ),
        prefixIconColor: AppColors.mist,
        suffixIconColor: AppColors.mist,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        enabledBorder: _border(AppColors.line),
        focusedBorder: _border(AppColors.gold, 1.6),
        errorBorder: _border(scheme.error),
        focusedErrorBorder: _border(scheme.error, 1.6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.navy,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyan,
          textStyle: const TextStyle(
            fontFamily: AppFonts.body,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.navy
              : AppColors.mist,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.gold
              : AppColors.slate,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.cardAlt,
        contentTextStyle: const TextStyle(
          fontFamily: AppFonts.body,
          color: Colors.white,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
