import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminChoiceScreen extends StatelessWidget {
  const AdminChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🌀 Gradient background
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Choose Login Type",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2F80ED),
                  ),
                ),
                const SizedBox(height: 30),

                // 🧑‍💼 Admin button
                _GradientButton(
                  text: "Login as Admin",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                  ),
                  onPressed: () {
                    // ✅ Use GoRouter instead of Navigator
                    context.pushReplacement('/admin_security_check');
                  },
                ),
                const SizedBox(height: 20),

                // 👤 User button
                _GradientButton(
                  text: "Login as User",
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6FCF97), Color(0xFF27AE60)],
                  ),
                  onPressed: () {
                    // ✅ Navigate with GoRouter for consistency
                    context.pushReplacement('/home');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// 🔘 Reusable Gradient Button Widget
class _GradientButton extends StatelessWidget {
  final String text;
  final LinearGradient gradient;
  final VoidCallback onPressed;

  const _GradientButton({
    required this.text,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
      ),
      onPressed: onPressed,
      child: Ink(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          height: 50,
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
