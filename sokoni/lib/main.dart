import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sokoni/screens/splashScreen.dart';
import 'firebase_options.dart';

enum AppThemeMode { system, light, dark, colorful }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('app_theme_mode');
  final initialTheme = _stringToTheme(savedTheme) ?? AppThemeMode.system;

  runApp(MyApp(initialThemeMode: initialTheme));
}

AppThemeMode? _stringToTheme(String? str) {
  switch (str) {
    case 'light':
      return AppThemeMode.light;
    case 'dark':
      return AppThemeMode.dark;
    case 'colorful':
      return AppThemeMode.colorful;
    case 'system':
      return AppThemeMode.system;
    default:
      return null;
  }
}

String _themeToString(AppThemeMode mode) {
  return mode.toString().split('.').last;
}

class MyApp extends StatefulWidget {
  final AppThemeMode initialThemeMode;

  const MyApp({Key? key, required this.initialThemeMode}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppThemeMode _appThemeMode;

  @override
  void initState() {
    super.initState();
    _appThemeMode = widget.initialThemeMode;
  }

  void _changeTheme(AppThemeMode newTheme) async {
    setState(() {
      _appThemeMode = newTheme;
    });
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('app_theme_mode', _themeToString(newTheme));
  }

  ThemeMode get _themeMode {
    switch (_appThemeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.colorful:
        return ThemeMode.light; // handled specially below
    }
  }

  ThemeData get _lightTheme => ThemeData.light().copyWith(
    colorScheme: const ColorScheme.light(
      primary: Colors.green,
      secondary: Colors.lightGreen,
    ),
  );

  ThemeData get _darkTheme => ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: Colors.amber,
      secondary: Colors.amberAccent,
    ),
  );

  ThemeData get _colorfulTheme => ThemeData(
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSwatch(
      primarySwatch: Colors.deepPurple,
      accentColor: Colors.orange,
    ),
    scaffoldBackgroundColor: Colors.deepPurple[50],
  );

  @override
  Widget build(BuildContext context) {
    return ThemeSwitcher(
      appThemeMode: _appThemeMode,
      changeTheme: _changeTheme,
      colorfulTheme: _colorfulTheme,
      child: Builder(
        builder: (context) {
          final isColorful = _appThemeMode == AppThemeMode.colorful;

          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: isColorful ? _colorfulTheme : _lightTheme,
            darkTheme: _darkTheme,
            themeMode: isColorful ? ThemeMode.light : _themeMode,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

class ThemeSwitcher extends InheritedWidget {
  final AppThemeMode appThemeMode;
  final Function(AppThemeMode) changeTheme;
  final ThemeData? colorfulTheme;

  const ThemeSwitcher({
    Key? key,
    required this.appThemeMode,
    required this.changeTheme,
    required Widget child,
    this.colorfulTheme,
  }) : super(key: key, child: child);

  static ThemeSwitcher of(BuildContext context) {
    final ThemeSwitcher? result =
    context.dependOnInheritedWidgetOfExactType<ThemeSwitcher>();
    assert(result != null, 'No ThemeSwitcher found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(ThemeSwitcher oldWidget) =>
      appThemeMode != oldWidget.appThemeMode ||
          colorfulTheme != oldWidget.colorfulTheme;
}
