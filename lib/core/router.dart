import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitab_corner/features/admin/admin_screen.dart';
import 'package:kitab_corner/features/admin/admin_security_check.dart';

// Splash & Welcome Screens
import '../features/splash/splash_screen.dart';
import '../features/welcome/welcomepg1.dart';
import '../features/welcome/welcomepg2.dart';
import '../features/welcome/welcomepg3.dart';

// Auth Screens
import '../features/auth/loginpg.dart';

// 🧑‍💼 Admin Screen
import '../features/admin/admin_choice_screen.dart';

// Main App Screens
import '../features/home/home_screen.dart';
import '../features/home/read_pg.dart';
import '../features/home/player_screen.dart';
import '../features/home/library.dart';
import '../features/profiles/profile.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/', // SplashScreen is entry point

    routes: [
      // 🌀 Splash Screen
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // 👋 Welcome Screens
      GoRoute(
        path: '/welcome1',
        name: 'welcome1',
        builder: (context, state) => const welcomepageone(),
      ),
      GoRoute(
        path: '/welcome2',
        name: 'welcome2',
        builder: (context, state) => const welcomepagetwo(),
      ),
      GoRoute(
        path: '/welcome3',
        name: 'welcome3',
        builder: (context, state) => const welcomepagethree(),
      ),

      // 🔐 Login Page
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => LoginPage(),
      ),

      // admin
      GoRoute(
        path: '/admin',
        name: 'admin',
        builder: (context, state) => const AdminChoiceScreen(),
      ),

      // adminSecurityCheck
      GoRoute(
        path: '/admin_security_check',
        name: 'admin security check',
        builder: (context, state) => const AdminSecurityCheck(),
      ),

      // admin screen
      GoRoute(
        path: '/admin_screen',
        name: 'admin screen',
        builder: (context, state) => const AdminScreen(),
      ),

      // 🏠 Home Screen
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // 📖 Read Book Page
      GoRoute(
        path: '/read',
        name: 'read',
        builder: (context, state) =>
            ReadPage(book: state.extra as Map<String, dynamic>),
      ),

      // 🎧 Player Page
      GoRoute(
        path: '/player',
        name: 'player',
        builder: (context, state) =>
            PlayerScreen(book: state.extra as Map<String, dynamic>),
      ),

      // 📚 Library Page
      GoRoute(
        path: '/library',
        name: 'library',
        builder: (context, state) => const LibraryScreen(),
      ),

      // 👤 Profile Page
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
    ],

    // ❌ Fallback for invalid routes
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.toString()}'),
      ),
    ),
  );
}
