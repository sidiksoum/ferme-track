import 'package:flutter/material.dart';

/// Color Palette - Faithfully following mockups
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryLight = Color(0xFFE4F1E5);

  // Accent & States
  static const Color accent = Color(0xFFF9A825);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF1565C0);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFB9770E);

  // Neutral
  static const Color background = Color(0xFFF3F1EA);
  static const Color ink = Color(0xFF1A2E1F);
  static const Color inkSoft = Color(0xFF5F6B62);
  static const Color paper = Color(0xFFFFFFFF);
  static const Color line = Color(0xFFDDE5DA);

  // Extended palette
  static const Color errorLight = Color(0xFFFBE4E4);
  static const Color warningLight = Color(0xFFFFF3D6);
  static const Color infoLight = Color(0xFFE3EDFB);
  static const Color successLight = Color(0xFFE3F3E4);
  static const Color syncGreen = Color(0xFF8BE28F);

  // Status colors
  static const Color statusDone = Color(0xFF2E7D32);
  static const Color statusTodo = Color(0xFF946200);
  static const Color statusLate = Color(0xFFC62828);
}

/// Typography
class AppTypography {
  static const String fontFamily = 'Roboto';
  static const String fontFamilyMono = 'RobotoMono';

  // Heading Styles
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 64,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.02,
    color: AppColors.primaryDark,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    letterSpacing: -0.01,
    color: AppColors.primaryDark,
  );

  static const TextStyle appbarTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle appbarSubtitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.normal,
    color: Color.fromARGB(204, 255, 255, 255),
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20.5,
    fontWeight: FontWeight.normal,
    height: 1.6,
    color: AppColors.inkSoft,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18.5,
    fontWeight: FontWeight.normal,
    height: 1.55,
    color: AppColors.ink,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16.5,
    fontWeight: FontWeight.normal,
    color: AppColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13.5,
    fontWeight: FontWeight.normal,
    color: AppColors.inkSoft,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.03,
    color: AppColors.inkSoft,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15.5,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.05,
    color: AppColors.inkSoft,
  );

  // Mono styles for metadata
  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontFamilyMono,
    fontSize: 15.5,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.14,
    color: AppColors.primaryDark,
  );
}

/// App Theme
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.accent,
        tertiary: AppColors.info,
        error: AppColors.danger,
        surface: AppColors.paper,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.appbarTitle,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          side: const BorderSide(color: AppColors.primary, width: 1.6),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.line, width: 1.4),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.line, width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        labelStyle: AppTypography.label,
        hintStyle: const TextStyle(color: AppColors.inkSoft),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.paper,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.line, width: 1),
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: AppTypography.h1,
        displayMedium: AppTypography.h2,
        titleLarge: AppTypography.appbarTitle,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelSmall: AppTypography.caption,
      ),
    );
  }
}
