import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgetpasspg.dart';
import 'signinpg.dart';
import '../home/home_screen.dart';
import '../admin/admin_choice_screen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> createUserDocIfNotExists(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'username': user.displayName ?? 'User',
        'email': user.email ?? "",
        'photoUrl':"",
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


  Future<void> _login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;

      if (user != null) {

        // 🔥 Ensure Firestore user doc exists
        await createUserDocIfNotExists(user);

        // 🔥 Re-fetch token if admin claim exists
        await user.getIdToken(true);

        if (user.email == "pt9413387@gmail.com") {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      }

    } on FirebaseAuthException catch (e) {
      String message = "Login failed. Please try again.";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else if (e.code == 'invalid-email') {
        message = "Invalid email address.";
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      setState(() => isLoading = false);
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
          child: Container(
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.9),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const HeaderIcon(title: "Welcome Back"),

                  const SizedBox(height: 10),
                  Text(
                    "Log in to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),

                  const SizedBox(height: 30),

                  // Email Input
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _inputDecoration("E-mail", Icons.email_outlined),
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Remember Me + Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: rememberMe,
                            onChanged: (val) => setState(() => rememberMe = val ?? false),
                          ),
                          const Text("Remember me"),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                          );
                        },
                        child: const Text("Forgot password?"),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  GradientButton(
                    text: isLoading ? "Logging in..." : "Log in",
                    onPressed: isLoading ? null : _login,
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text("OR", style: TextStyle(color: Colors.grey[600])),
                      ),
                      Expanded(child: Divider(thickness: 1, color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Sign Up
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don’t have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => SignUpPage()),
                          );
                        },
                        child: const Text(
                          "Sign Up",
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: Colors.grey[100],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

// Gradient Button
class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;

  const GradientButton({required this.text, required this.onPressed, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 55,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.cyan, Colors.greenAccent],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// Header Icon
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
            gradient: LinearGradient(colors: [Colors.cyan, Colors.greenAccent]),
          ),
          padding: const EdgeInsets.all(22),
          child: const Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
