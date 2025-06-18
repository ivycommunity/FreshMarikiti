import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fresh Marikiti Brand Colors
class AppColors {
  // Primary brand colors - inspired by fresh markets and nature
  static const Color freshGreen = Color(0xFF2E7D32); // Main brand green
  static const Color organicGreen = Color(0xFF4CAF50); // Lighter organic green
  static const Color marketOrange =
      Color(0xFFFF9800); // Market freshness orange
  static const Color ecoBlue = Color(0xFF1976D2); // Eco-friendly blue
  static const Color naturalBrown = Color(0xFF8D6E63); // Natural earth brown
  static const Color harvestYellow =
      Color(0xFFFFC107); // Harvest sunshine yellow

  // Neutral colors
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceDark = Color(0xFF2A2A2A);

  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);

  // Text colors
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB3B3B3);

  // High contrast colors
  static const Color highContrastPrimary = Color(0xFF000000);
  static const Color highContrastSecondary = Color(0xFFFFFFFF);
}

/// Enhanced theme configuration for Fresh Marikiti
class AppTheme {
  /// Create light theme with customization options
  static ThemeData lightTheme({
    Color? accentColor,
    double textScale = 1.0,
    bool isHighContrast = false,
    String fontFamily = 'poppins',
  }) {
    final primaryColor = accentColor ?? AppColors.freshGreen;
    final colorScheme = ColorScheme.light(
      primary: primaryColor,
      secondary: AppColors.organicGreen,
      tertiary: AppColors.marketOrange,
      surface: isHighContrast ? Colors.white : AppColors.surfaceLight,
      background: isHighContrast ? Colors.white : AppColors.lightBackground,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: isHighContrast
          ? AppColors.highContrastPrimary
          : AppColors.textPrimaryLight,
      onBackground: isHighContrast
          ? AppColors.highContrastPrimary
          : AppColors.textPrimaryLight,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(fontFamily, textScale, false, isHighContrast),
      appBarTheme: _getAppBarTheme(primaryColor, false),
      //cardTheme: _getCardTheme(false, isHighContrast),
      elevatedButtonTheme: _getElevatedButtonTheme(primaryColor),
      filledButtonTheme: _getFilledButtonTheme(primaryColor),
      outlinedButtonTheme: _getOutlinedButtonTheme(primaryColor),
      textButtonTheme: _getTextButtonTheme(primaryColor),
      inputDecorationTheme:
          _getInputDecorationTheme(primaryColor, false, isHighContrast),
      floatingActionButtonTheme: _getFABTheme(primaryColor),
      chipTheme: _getChipTheme(primaryColor, false),
      navigationBarTheme: _getNavigationBarTheme(false),
      bottomNavigationBarTheme: _getBottomNavigationBarTheme(false),
      dividerTheme: DividerThemeData(
        color: isHighContrast
            ? AppColors.highContrastPrimary
            : AppColors.textSecondaryLight.withValues(alpha: 0.2),
        thickness: isHighContrast ? 2 : 1,
      ),
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  /// Create dark theme with customization options
  static ThemeData darkTheme({
    Color? accentColor,
    double textScale = 1.0,
    bool isHighContrast = false,
    String fontFamily = 'poppins',
  }) {
    final primaryColor = accentColor ?? AppColors.freshGreen;
    final colorScheme = ColorScheme.dark(
      primary: primaryColor,
      secondary: AppColors.organicGreen,
      tertiary: AppColors.marketOrange,
      surface: isHighContrast ? Colors.black : AppColors.surfaceDark,
      background: isHighContrast ? Colors.black : AppColors.darkBackground,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: isHighContrast
          ? AppColors.highContrastSecondary
          : AppColors.textPrimaryDark,
      onBackground: isHighContrast
          ? AppColors.highContrastSecondary
          : AppColors.textPrimaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _getTextTheme(fontFamily, textScale, true, isHighContrast),
      appBarTheme: _getAppBarTheme(primaryColor, true),
      //cardTheme: _getCardTheme(true, isHighContrast),
      elevatedButtonTheme: _getElevatedButtonTheme(primaryColor),
      filledButtonTheme: _getFilledButtonTheme(primaryColor),
      outlinedButtonTheme: _getOutlinedButtonTheme(primaryColor),
      textButtonTheme: _getTextButtonTheme(primaryColor),
      inputDecorationTheme:
          _getInputDecorationTheme(primaryColor, true, isHighContrast),
      floatingActionButtonTheme: _getFABTheme(primaryColor),
      chipTheme: _getChipTheme(primaryColor, true),
      navigationBarTheme: _getNavigationBarTheme(true),
      bottomNavigationBarTheme: _getBottomNavigationBarTheme(true),
      dividerTheme: DividerThemeData(
        color: isHighContrast
            ? AppColors.highContrastSecondary
            : AppColors.textSecondaryDark.withValues(alpha: 0.2),
        thickness: isHighContrast ? 2 : 1,
      ),
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  /// Get text theme based on font family and scale
  static TextTheme _getTextTheme(
      String fontFamily, double textScale, bool isDark, bool isHighContrast) {
    TextTheme baseTheme;

    switch (fontFamily) {
      case 'inter':
        baseTheme = GoogleFonts.interTextTheme();
        break;
      case 'roboto':
        baseTheme = GoogleFonts.robotoTextTheme();
        break;
      case 'system':
        baseTheme = ThemeData.light().textTheme;
        break;
      case 'poppins':
      default:
        baseTheme = GoogleFonts.poppinsTextTheme();
        break;
    }

    final textColor = isHighContrast
        ? (isDark
            ? AppColors.highContrastSecondary
            : AppColors.highContrastPrimary)
        : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight);

    final secondaryTextColor = isHighContrast
        ? (isDark
            ? AppColors.highContrastSecondary
            : AppColors.highContrastPrimary)
        : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);

    return baseTheme.copyWith(
      displayLarge: baseTheme.displayLarge?.copyWith(
        color: textColor,
        fontSize: (baseTheme.displayLarge?.fontSize ?? 32) * textScale,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        color: textColor,
        fontSize: (baseTheme.displayMedium?.fontSize ?? 28) * textScale,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        color: textColor,
        fontSize: (baseTheme.displaySmall?.fontSize ?? 24) * textScale,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        color: textColor,
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 22) * textScale,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        color: textColor,
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 20) * textScale,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        color: textColor,
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 18) * textScale,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        color: textColor,
        fontSize: (baseTheme.titleLarge?.fontSize ?? 16) * textScale,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        color: textColor,
        fontSize: (baseTheme.titleMedium?.fontSize ?? 14) * textScale,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        color: secondaryTextColor,
        fontSize: (baseTheme.titleSmall?.fontSize ?? 12) * textScale,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        color: textColor,
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * textScale,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        color: textColor,
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * textScale,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        color: secondaryTextColor,
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * textScale,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        color: textColor,
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * textScale,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        color: textColor,
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * textScale,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        color: secondaryTextColor,
        fontSize: (baseTheme.labelSmall?.fontSize ?? 10) * textScale,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  /// App bar theme
  static AppBarTheme _getAppBarTheme(Color primaryColor, bool isDark) {
    return AppBarTheme(
      backgroundColor: isDark ? AppColors.cardDark : primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Card theme
  static CardTheme _getCardTheme(bool isDark, bool isHighContrast) {
    return CardTheme(
      elevation: isHighContrast ? 0 : 2,
      color: isHighContrast
          ? (isDark ? Colors.black : Colors.white)
          : (isDark ? AppColors.cardDark : AppColors.cardLight),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isHighContrast
            ? BorderSide(
                color: isDark
                    ? AppColors.highContrastSecondary
                    : AppColors.highContrastPrimary,
                width: 2,
              )
            : BorderSide.none,
      ),
    );
  }

  /// Elevated button theme
  static ElevatedButtonThemeData _getElevatedButtonTheme(Color primaryColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
    );
  }

  /// Filled button theme
  static FilledButtonThemeData _getFilledButtonTheme(Color primaryColor) {
    return FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Outlined button theme
  static OutlinedButtonThemeData _getOutlinedButtonTheme(Color primaryColor) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  /// Text button theme
  static TextButtonThemeData _getTextButtonTheme(Color primaryColor) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Input decoration theme
  static InputDecorationTheme _getInputDecorationTheme(
      Color primaryColor, bool isDark, bool isHighContrast) {
    final fillColor = isHighContrast
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? AppColors.surfaceDark : Colors.grey[100]!);

    final borderColor = isHighContrast
        ? (isDark
            ? AppColors.highContrastSecondary
            : AppColors.highContrastPrimary)
        : Colors.transparent;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: borderColor, width: isHighContrast ? 2 : 0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: borderColor, width: isHighContrast ? 2 : 0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  /// Floating action button theme
  static FloatingActionButtonThemeData _getFABTheme(Color primaryColor) {
    return FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Chip theme
  static ChipThemeData _getChipTheme(Color primaryColor, bool isDark) {
    return ChipThemeData(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      selectedColor: primaryColor.withValues(alpha: 0.2),
      secondarySelectedColor: primaryColor,
      labelStyle: GoogleFonts.poppins(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        fontSize: 14,
      ),
      secondaryLabelStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  /// Navigation bar theme
  static NavigationBarThemeData _getNavigationBarTheme(bool isDark) {
    return NavigationBarThemeData(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 8,
      height: 80,
      labelTextStyle: MaterialStateProperty.all(
        GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// Bottom navigation bar theme
  static BottomNavigationBarThemeData _getBottomNavigationBarTheme(
      bool isDark) {
    return BottomNavigationBarThemeData(
      backgroundColor: isDark ? AppColors.cardDark : AppColors.cardLight,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle:
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
      unselectedLabelStyle:
          GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400),
    );
  }
}

/// Convenient text styles for consistent usage
class AppTextStyles {
  /// Heading styles
  static TextStyle get heading1 => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get heading2 => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get heading3 => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      );

  /// Body styles
  static TextStyle get bodyLarge => GoogleFonts.poppins(fontSize: 16);
  static TextStyle get bodyMedium => GoogleFonts.poppins(fontSize: 14);
  static TextStyle get bodySmall => GoogleFonts.poppins(fontSize: 12);

  /// Special styles
  static TextStyle get button => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get caption => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get overline => GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
      );
}
