import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fresh_marikiti/models/user.dart';
import 'package:fresh_marikiti/screens/auth/login_screen.dart';
import 'package:fresh_marikiti/screens/auth/register_screen.dart';

class AppRouter {
  final User? user;
  final bool isAuthenticated;

  AppRouter({
    required this.user,
    required this.isAuthenticated,
  });

  late final router = GoRouter(
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      final path = state.uri.path;
      
      // If the user is not authenticated and not on an auth route, redirect to login
      if (!isAuthenticated &&
          !['/login', '/register'].contains(path)) {
        return '/login';
      }

      // If the user is authenticated and on an auth route, redirect to their role-specific home
      if (isAuthenticated &&
          ['/login', '/register'].contains(path)) {
        return _getHomeRouteForRole(user?.role);
      }

      // Allow the navigation to proceed
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Customer Routes
      GoRoute(
        path: '/customer',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Customer Home')),
        ),
      ),

      // Vendor Routes
      GoRoute(
        path: '/vendor',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Vendor Home')),
        ),
      ),

      // Rider Routes
      GoRoute(
        path: '/rider',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Rider Home')),
        ),
      ),

      // Connector Routes
      GoRoute(
        path: '/connector',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Connector Home')),
        ),
      ),

      // Admin Routes
      GoRoute(
        path: '/admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Admin Home')),
        ),
      ),

      // Vendor Admin Routes
      GoRoute(
        path: '/vendor-admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Vendor Admin Home')),
        ),
      ),
    ],
  );

  String _getHomeRouteForRole(UserRole? role) {
    switch (role) {
      case UserRole.customer:
        return '/customer';
      case UserRole.vendor:
        return '/vendor';
      case UserRole.rider:
        return '/rider';
      case UserRole.connector:
        return '/connector';
      case UserRole.admin:
        return '/admin';
      case UserRole.vendorAdmin:
        return '/vendor-admin';
      default:
        return '/login';
    }
  }
} 