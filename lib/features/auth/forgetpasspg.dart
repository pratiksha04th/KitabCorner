import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'loginpg.dart';

// ----------------- FORGOT PASSWORD PAGE -----------------
class ForgotPasswordPage extends StatefulWidget {
  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Reset link sent to your email")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Something went wrong")),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ✅ Reuse HeaderIcon from loginpg.dart
                  const HeaderIcon(title: "Forgot Password?"),

                  const SizedBox(height: 10),
                  Text(
                    "Enter your registered email to receive a reset link",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Email Input
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email_outlined),
                      labelText: "E-mail",
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ✅ GradientButton with loading state
                  GradientButton(
                    text: isLoading ? "Sending..." : "Send Reset Link",
                    onPressed: isLoading ? null : _resetPassword,
                  ),

                  const SizedBox(height: 20),

                  // Back to Login
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Remember your password? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => LoginPage()),
                          );
                        },
                        child: const Text(
                          "Log in",
                          style: TextStyle(
                            color: Colors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- GRADIENT BUTTON -----------------
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed; // ✅ nullable

  const GradientButton({
    required this.text,
    this.onPressed,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.cyan,
              Colors.greenAccent,
            ],
          )
              : null,
          color: isEnabled ? null : Colors.grey, // Disabled look
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.6),
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- HEADER ICON -----------------
class HeaderIcon extends StatelessWidget {
  final String title;
  const HeaderIcon({required this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.cyan, Colors.greenAccent],
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: const Icon(Icons.lock_reset, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
