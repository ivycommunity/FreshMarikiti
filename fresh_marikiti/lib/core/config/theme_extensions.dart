import 'package:flutter/material.dart';
import 'package:fresh_marikiti/core/config/theme.dart';

/// Convenient extensions for accessing theme properties
extension ThemeExtensions on BuildContext {
  /// Get current theme data
  ThemeData get theme => Theme.of(this);
  
  /// Get current color scheme
  ColorScheme get colors => theme.colorScheme;
  
  /// Get current text theme
  TextTheme get textTheme => theme.textTheme;
  
  /// Check if current theme is dark
  bool get isDarkMode => theme.brightness == Brightness.dark;
}

/// Fresh Marikiti specific color extensions
extension FreshMarikitiColors on ColorScheme {
  /// Get Fresh Marikiti brand colors
  Color get freshGreen => AppColors.freshGreen;
  Color get organicGreen => AppColors.organicGreen;
  Color get marketOrange => AppColors.marketOrange;
  Color get ecoBlue => AppColors.ecoBlue;
  Color get naturalBrown => AppColors.naturalBrown;
  Color get harvestYellow => AppColors.harvestYellow;
  
  /// Status colors
  Color get success => AppColors.success;
  Color get warning => AppColors.warning;
  Color get info => AppColors.info;
  
  /// Contextual colors based on current brightness
  Color get cardColor => brightness == Brightness.dark 
      ? AppColors.cardDark 
      : AppColors.cardLight;
      
  Color get surfaceColor => brightness == Brightness.dark 
      ? AppColors.surfaceDark 
      : AppColors.surfaceLight;
      
  Color get textPrimary => brightness == Brightness.dark 
      ? AppColors.textPrimaryDark 
      : AppColors.textPrimaryLight;
      
  Color get textSecondary => brightness == Brightness.dark 
      ? AppColors.textSecondaryDark 
      : AppColors.textSecondaryLight;
}

/// Fresh Marikiti spacing constants
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  /// Edge insets
  static const EdgeInsets paddingXS = EdgeInsets.all(xs);
  static const EdgeInsets paddingSM = EdgeInsets.all(sm);
  static const EdgeInsets paddingMD = EdgeInsets.all(md);
  static const EdgeInsets paddingLG = EdgeInsets.all(lg);
  static const EdgeInsets paddingXL = EdgeInsets.all(xl);
  
  /// Horizontal padding
  static const EdgeInsets horizontalXS = EdgeInsets.symmetric(horizontal: xs);
  static const EdgeInsets horizontalSM = EdgeInsets.symmetric(horizontal: sm);
  static const EdgeInsets horizontalMD = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets horizontalLG = EdgeInsets.symmetric(horizontal: lg);
  static const EdgeInsets horizontalXL = EdgeInsets.symmetric(horizontal: xl);
  
  /// Vertical padding
  static const EdgeInsets verticalXS = EdgeInsets.symmetric(vertical: xs);
  static const EdgeInsets verticalSM = EdgeInsets.symmetric(vertical: sm);
  static const EdgeInsets verticalMD = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets verticalLG = EdgeInsets.symmetric(vertical: lg);
  static const EdgeInsets verticalXL = EdgeInsets.symmetric(vertical: xl);
  
  /// Page padding
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: md, vertical: lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
  static const EdgeInsets screenPadding = EdgeInsets.all(md);
}

/// Border radius constants
class AppRadius {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double pill = 100.0;
  
  /// Border radius objects
  static const BorderRadius radiusXS = BorderRadius.all(Radius.circular(xs));
  static const BorderRadius radiusSM = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius radiusMD = BorderRadius.all(Radius.circular(md));
  static const BorderRadius radiusLG = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius radiusXL = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius radiusPill = BorderRadius.all(Radius.circular(pill));
  
  /// Top-only radius
  static const BorderRadius topRadiusMD = BorderRadius.vertical(top: Radius.circular(md));
  static const BorderRadius topRadiusLG = BorderRadius.vertical(top: Radius.circular(lg));
  
  /// Bottom-only radius
  static const BorderRadius bottomRadiusMD = BorderRadius.vertical(bottom: Radius.circular(md));
  static const BorderRadius bottomRadiusLG = BorderRadius.vertical(bottom: Radius.circular(lg));
}

/// Shadow constants
class AppShadows {
  static const List<BoxShadow> small = [
    BoxShadow(
      color: Color(0x0D000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
  
  static const List<BoxShadow> medium = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  static const List<BoxShadow> large = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];
  
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 12,
      offset: Offset(0, 2),
    ),
  ];
}

/// Icon size constants
class AppIconSizes {
  static const double xs = 16.0;
  static const double sm = 20.0;
  static const double md = 24.0;
  static const double lg = 32.0;
  static const double xl = 48.0;
  static const double xxl = 64.0;
}

/// Animation duration constants
class AppDurations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 250);
}

/// Typography extensions for easier text styling
extension AppTextStyles on TextTheme {
  /// Display styles
  TextStyle get displayBold => displayLarge!.copyWith(fontWeight: FontWeight.bold);
  TextStyle get displaySemiBold => displayMedium!.copyWith(fontWeight: FontWeight.w600);
  
  /// Heading styles with specific weights
  TextStyle get h1Bold => headlineLarge!.copyWith(fontWeight: FontWeight.bold);
  TextStyle get h2SemiBold => headlineMedium!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get h3Medium => headlineSmall!.copyWith(fontWeight: FontWeight.w500);
  
  /// Body styles with weights
  TextStyle get bodyBold => bodyLarge!.copyWith(fontWeight: FontWeight.bold);
  TextStyle get bodySemiBold => bodyMedium!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get bodyRegular => bodyMedium!;
  
  /// Button text style
  TextStyle get buttonText => labelLarge!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  /// Caption styles
  TextStyle get captionBold => bodySmall!.copyWith(fontWeight: FontWeight.w600);
  TextStyle get captionRegular => bodySmall!;
}

/// Convenient widget extensions
extension WidgetExtensions on Widget {
  /// Add padding
  Widget get paddingXS => Padding(padding: AppSpacing.paddingXS, child: this);
  Widget get paddingSM => Padding(padding: AppSpacing.paddingSM, child: this);
  Widget get paddingMD => Padding(padding: AppSpacing.paddingMD, child: this);
  Widget get paddingLG => Padding(padding: AppSpacing.paddingLG, child: this);
  Widget get paddingXL => Padding(padding: AppSpacing.paddingXL, child: this);
  
  /// Add custom padding
  Widget padding(EdgeInsets padding) => Padding(padding: padding, child: this);
  
  /// Add margin (using container)
  Widget marginAll(double margin) => Container(margin: EdgeInsets.all(margin), child: this);
  Widget marginHorizontal(double margin) => Container(margin: EdgeInsets.symmetric(horizontal: margin), child: this);
  Widget marginVertical(double margin) => Container(margin: EdgeInsets.symmetric(vertical: margin), child: this);
  
  /// Center widget
  Widget get center => Center(child: this);
  
  /// Expand widget
  Widget get expanded => Expanded(child: this);
  Widget expand({int flex = 1}) => Expanded(flex: flex, child: this);
  
  /// Flexible widget
  Widget get flexible => Flexible(child: this);
  Widget flex({int flex = 1}) => Flexible(flex: flex, child: this);
} 