import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fresh_marikiti/core/services/storage_service.dart';
import 'package:fresh_marikiti/core/services/logger_service.dart';
import 'package:fresh_marikiti/core/config/theme.dart';

class ThemeProvider with ChangeNotifier {
  // Theme settings
  bool _isDarkMode = false;
  String _accentColor = 'freshGreen';
  double _textScale = 1.0;
  bool _isHighContrast = false;
  bool _reduceAnimations = false;
  String _fontFamily = 'poppins';
  
  // System settings
  bool _useSystemTheme = true;
  bool _isInitialized = false;

  // Getters
  bool get isDarkMode => _isDarkMode;
  String get accentColor => _accentColor;
  double get textScale => _textScale;
  bool get isHighContrast => _isHighContrast;
  bool get reduceAnimations => _reduceAnimations;
  String get fontFamily => _fontFamily;
  bool get useSystemTheme => _useSystemTheme;
  bool get isInitialized => _isInitialized;

  // Theme data getters
  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;
  Brightness get currentBrightness => _isDarkMode ? Brightness.dark : Brightness.light;
  
  /// Get current theme mode for MaterialApp
  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system;
    }
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  /// Initialize theme provider
  ThemeProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadThemePreferences();
    _isInitialized = true;
    notifyListeners();
  }

  /// Get current light theme
  ThemeData get lightTheme {
    return AppTheme.lightTheme(
      accentColor: _getAccentColor(),
      textScale: _textScale,
      isHighContrast: _isHighContrast,
      fontFamily: _fontFamily,
    );
  }

  /// Get current dark theme
  ThemeData get darkTheme {
    return AppTheme.darkTheme(
      accentColor: _getAccentColor(),
      textScale: _textScale,
      isHighContrast: _isHighContrast,
      fontFamily: _fontFamily,
    );
  }

  /// Toggle between light and dark mode
  Future<void> toggleDarkMode({bool? forceDark}) async {
    if (forceDark != null) {
      _isDarkMode = forceDark;
    } else {
      _isDarkMode = !_isDarkMode;
    }
    
    if (_isDarkMode) {
      _useSystemTheme = false;
    }
    
    await _updateSystemUI();
    await _saveThemePreferences();
    notifyListeners();
    
    LoggerService.info('Theme mode changed to: ${_isDarkMode ? 'Dark' : 'Light'}', tag: 'ThemeProvider');
  }

  /// Set accent color
  Future<void> setAccentColor(String colorName) async {
    if (_accentColor != colorName) {
      _accentColor = colorName;
      await _saveThemePreferences();
      notifyListeners();
      
      LoggerService.info('Accent color changed to: $colorName', tag: 'ThemeProvider');
    }
  }

  /// Set text scale factor
  Future<void> setTextScale(double scale) async {
    if (_textScale != scale) {
      _textScale = scale.clamp(0.8, 1.4); // Limit scale between 80% and 140%
      await _saveThemePreferences();
      notifyListeners();
      
      LoggerService.info('Text scale changed to: ${(_textScale * 100).round()}%', tag: 'ThemeProvider');
    }
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    _isHighContrast = !_isHighContrast;
    await _saveThemePreferences();
    notifyListeners();
    
    LoggerService.info('High contrast mode: ${_isHighContrast ? 'Enabled' : 'Disabled'}', tag: 'ThemeProvider');
  }

  /// Toggle reduced animations
  Future<void> toggleReduceAnimations() async {
    _reduceAnimations = !_reduceAnimations;
    await _saveThemePreferences();
    notifyListeners();
    
    LoggerService.info('Reduce animations: ${_reduceAnimations ? 'Enabled' : 'Disabled'}', tag: 'ThemeProvider');
  }

  /// Set font family
  Future<void> setFontFamily(String family) async {
    if (_fontFamily != family) {
      _fontFamily = family;
      await _saveThemePreferences();
      notifyListeners();
      
      LoggerService.info('Font family changed to: $family', tag: 'ThemeProvider');
    }
  }

  /// Toggle system theme following
  Future<void> toggleUseSystemTheme() async {
    _useSystemTheme = !_useSystemTheme;
    
    if (_useSystemTheme) {
      // Follow system theme
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _isDarkMode = brightness == Brightness.dark;
    }
    
    await _updateSystemUI();
    await _saveThemePreferences();
    notifyListeners();
    
    LoggerService.info('Use system theme: ${_useSystemTheme ? 'Enabled' : 'Disabled'}', tag: 'ThemeProvider');
  }

  /// Update theme based on system brightness (when system theme is enabled)
  Future<void> updateFromSystem(Brightness systemBrightness) async {
    if (_useSystemTheme) {
      final newDarkMode = systemBrightness == Brightness.dark;
      if (_isDarkMode != newDarkMode) {
        _isDarkMode = newDarkMode;
        await _updateSystemUI();
        notifyListeners();
        
        LoggerService.info('System theme updated to: ${_isDarkMode ? 'Dark' : 'Light'}', tag: 'ThemeProvider');
      }
    }
  }

  /// Reset theme to defaults
  Future<void> resetToDefaults() async {
    _isDarkMode = false;
    _accentColor = 'freshGreen';
    _textScale = 1.0;
    _isHighContrast = false;
    _reduceAnimations = false;
    _fontFamily = 'poppins';
    _useSystemTheme = true;
    
    await _updateSystemUI();
    await _saveThemePreferences();
    notifyListeners();
    
    LoggerService.info('Theme reset to defaults', tag: 'ThemeProvider');
  }

  /// Get available accent colors
  Map<String, Color> getAvailableAccentColors() {
    return {
      'freshGreen': AppColors.freshGreen,
      'organicGreen': AppColors.organicGreen,
      'marketOrange': AppColors.marketOrange,
      'ecoBlue': AppColors.ecoBlue,
      'naturalBrown': AppColors.naturalBrown,
      'harvestYellow': AppColors.harvestYellow,
    };
  }

  /// Get available font families
  List<String> getAvailableFontFamilies() {
    return ['poppins', 'inter', 'roboto', 'system'];
  }

  /// Update system UI overlay style
  Future<void> _updateSystemUI() async {
    final brightness = _isDarkMode ? Brightness.dark : Brightness.light;
    final statusBarBrightness = _isDarkMode ? Brightness.light : Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: brightness,
        statusBarIconBrightness: statusBarBrightness,
        systemNavigationBarColor: _isDarkMode ? AppColors.darkBackground : Colors.white,
        systemNavigationBarIconBrightness: statusBarBrightness,
      ),
    );
  }

  /// Get accent color
  Color _getAccentColor() {
    final colors = getAvailableAccentColors();
    return colors[_accentColor] ?? AppColors.freshGreen;
  }

  /// Load theme preferences from storage
  Future<void> _loadThemePreferences() async {
    try {
      _isDarkMode = await StorageService.getBool('theme_dark_mode', defaultValue: false);
      _accentColor = await StorageService.getString('theme_accent_color') ?? 'freshGreen';
      _textScale = (await StorageService.getInt('theme_text_scale', defaultValue: 100)) / 100.0;
      _isHighContrast = await StorageService.getBool('theme_high_contrast', defaultValue: false);
      _reduceAnimations = await StorageService.getBool('theme_reduce_animations', defaultValue: false);
      _fontFamily = await StorageService.getString('theme_font_family') ?? 'poppins';
      _useSystemTheme = await StorageService.getBool('theme_use_system', defaultValue: true);
      
      // If using system theme, check current system brightness
      if (_useSystemTheme) {
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        _isDarkMode = brightness == Brightness.dark;
      }
      
      await _updateSystemUI();
      
      LoggerService.info('Theme preferences loaded', tag: 'ThemeProvider');
    } catch (e) {
      LoggerService.error('Failed to load theme preferences', error: e, tag: 'ThemeProvider');
      // Use defaults on error
    }
  }

  /// Save theme preferences to storage
  Future<void> _saveThemePreferences() async {
    try {
      await Future.wait([
        StorageService.saveBool('theme_dark_mode', _isDarkMode),
        StorageService.saveString('theme_accent_color', _accentColor),
        StorageService.saveInt('theme_text_scale', (_textScale * 100).round()),
        StorageService.saveBool('theme_high_contrast', _isHighContrast),
        StorageService.saveBool('theme_reduce_animations', _reduceAnimations),
        StorageService.saveString('theme_font_family', _fontFamily),
        StorageService.saveBool('theme_use_system', _useSystemTheme),
      ]);
      
      LoggerService.info('Theme preferences saved', tag: 'ThemeProvider');
    } catch (e) {
      LoggerService.error('Failed to save theme preferences', error: e, tag: 'ThemeProvider');
    }
  }
} 