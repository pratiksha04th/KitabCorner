import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(seconds: 3)); // ⏳ Splash duration

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user != null) {
      // ✅ Logged in → Go to Home
      context.go('/home');
    } else {
      // 👋 Not logged in → Go to Welcome Page 1
      context.go('/welcome1');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            "assets/images/background.png",
            fit: BoxFit.cover,
          ),

          // Overlay Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Kitab Corner",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
