import 'package:flutter/material.dart';

final ThemeData lightMode = ThemeData(
  brightness: Brightness.light,
  fontFamily: 'Poppins', // Optional custom font
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.light,

    // Primary = main accent (AppBar, Buttons)
    //primary: Color(0xFF214E25),
    primary: Color(0xFF214E25),
    onPrimary: Colors.white,

    // Secondary = highlight colour (See All, badges)
    secondary: Color(0xFFDD3A5C),
    onSecondary: Colors.white,

    // Surface = app background or scaffold background
    surface: Color(0xFF93B84D),
    onSurface: Color(0xFF214E25),

    // Tertiary = used for variety (buttons, icons)
    tertiary: Color(0xFF7CC242),
    onTertiary: Colors.white,

    // Error = red or alerts
    error: Color(0xFFE56972),
    onError: Colors.white,

    // Other optional Material 3 roles
    primaryContainer: Color(0xFF93B84D),
    onPrimaryContainer: Colors.white,

    secondaryContainer: Color(0xFFE56972),
    onSecondaryContainer: Color(0xFF214E25),

    // Surface Containers for cards/blocks
    surfaceContainerLow: Color(0xFFD0E8DB), // e.g. vendor cards
    surfaceContainer: Color(0xFFD9D9D9), // higher elevated containers

    // Accent outlines & shadows
    outline: Color(0xFFB44450),
    inverseSurface: Color(0xFF214E25),
    onInverseSurface: Colors.white,
    inversePrimary: Color(0xFF1993EA),
    shadow: Colors.black45,
    scrim: Colors.black38,
  ),
);

final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Poppins',
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    // Primary = main accent (AppBar, Buttons)
    primary: Color(0xFF214E25), // Lighter green
    onPrimary: Colors.white, // Deep green text

    // Secondary = highlight colour (See All, badges)
    secondary: Color(0xFFE56972), // Vibrant red-pink
    onSecondary: Colors.white,

    // Surface = scaffold background
    surface: Color(0xFF214E25), // Deep green
    onSurface: Color(0xFFD0E8DB), // Soft mint text

    // Tertiary = variety (buttons, icons)
    tertiary: Color(0xFF7CBF9D),
    onTertiary: Colors.black,

    // Error = red or alerts
    error: Color(0xFFB44450),
    onError: Colors.white,

    // Primary container = background highlight
    primaryContainer: Color(0xFF7CC242),
    onPrimaryContainer: Colors.black,

    // Secondary container
    secondaryContainer: Color(0xFFDD3A5C),
    onSecondaryContainer: Colors.white,

    // Surface Containers for cards/blocks
    surfaceContainerLow: Color(0xFF2C3B2D), // very dark greenish background
    surfaceContainer: Color(0xFFD0E8DB), // card backgrounds

    // Outlines and accents
    outline: Color(0xFFD9D9D9),
    inverseSurface: Color(0xFFFFE7D1),
    onInverseSurface: Color(0xFF214E25),
    inversePrimary: Color(0xFF1993EA), // Optional action blue
    shadow: Colors.black87,
    scrim: Colors.black54,
  ),
);


/*
Dark mode previous version
final ThemeData darkMode = ThemeData(
  brightness: Brightness.dark,
  useMaterial3: true,
  colorScheme: const ColorScheme(
    brightness: Brightness.dark,

    primary: Color(0xFF93B84D),
    onPrimary: Colors.black,

    secondary: Color(0xFF7CBF9D),
    onSecondary: Colors.black,

    //surface: Color(0xFF214E25),
    //onSurface: Colors.white,
    surface: Color(0xFF2E4F36),
    onSurface: Colors.white,

    error: Color(0xFFE56972),
    onError: Colors.white,

    tertiary: Color(0xFF1993EA),
    onTertiary: Colors.white,

    primaryContainer: Color(0xFFBFD79F),
    onPrimaryContainer: Colors.black,

    secondaryContainer: Color(0xFF9FD0B9),
    onSecondaryContainer: Colors.black,

    surfaceVariant: Color(0xFF374A3D),
    onSurfaceVariant: Colors.white70,
    outline: Color(0xFF9FD0B9),
    inverseSurface: Color(0xFFD0E8DB),
    onInverseSurface: Color(0xFF214E25),
    inversePrimary: Color(0xFF7CC242),
    shadow: Colors.black54,
    scrim: Colors.black87,
  ),
  textTheme: ThemeData.dark().textTheme.copyWith(
        bodyLarge: const TextStyle(color: Colors.white),
        bodyMedium: const TextStyle(color: Colors.white70),
      ),
);
*/