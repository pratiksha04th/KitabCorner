import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loginpg.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool agreeToTerms = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  String passwordStrength = "";

  // =====================
  // Validation Functions
  // =====================
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) return "Username is required";
    if (value.length < 3) return "Username must be at least 3 characters";
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return "Only letters, numbers & underscores allowed";
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return "Email is required";
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return "Password is required";
    if (value.length < 8) return "At least 8 characters required";
    if (!RegExp(r'^(?=.*[A-Z])').hasMatch(value)) return "Must contain uppercase letter";
    if (!RegExp(r'^(?=.*[a-z])').hasMatch(value)) return "Must contain lowercase letter";
    if (!RegExp(r'^(?=.*\d)').hasMatch(value)) return "Must contain a number";
    if (!RegExp(r'^(?=.*[!@#\$&*~])').hasMatch(value)) {
      return "Must contain a special character (!@#\$&*~)";
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value != passwordController.text) return "Passwords do not match";
    return null;
  }

  // =====================
  // Password Strength Check
  // =====================
  void _checkPasswordStrength(String password) {
    String strength;
    if (password.isEmpty) {
      strength = "";
    } else if (password.length < 6) {
      strength = "Weak";
    } else if (RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d).{6,}$').hasMatch(password)) {
      strength = "Medium";
    } else if (RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$')
        .hasMatch(password)) {
      strength = "Strong";
    } else {
      strength = "Weak";
    }

    setState(() => passwordStrength = strength);
  }

  Color _getStrengthColor() {
    switch (passwordStrength) {
      case "Weak":
        return Colors.red;
      case "Medium":
        return Colors.orange;
      case "Strong":
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  Future<void> createUserDocIfNotExists(User user) async {
    final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'username': user.displayName ?? 'User',
        'email': user.email ?? "",
        'photoUrl': user.photoURL ?? "",
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }


  // =====================
  // Sign Up Function
  // =====================
  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate() || !agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fix errors and agree to terms")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "username": usernameController.text.trim(),
          "email": emailController.text.trim(),
          "photoUrl": "",
          "createdAt": FieldValue.serverTimestamp(),
        });

      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Account created successfully!")),
      );
    } on FirebaseAuthException catch (e) {
      String message = "An error occurred";
      if (e.code == 'weak-password') {
        message = "The password provided is too weak.";
      } else if (e.code == 'email-already-in-use') {
        message = "The account already exists for that email.";
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
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
              ],
            ),
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const HeaderIcon(title: "Create Account"),

                    const SizedBox(height: 10),
                    Text("Sign up to get started",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Colors.grey[600])),

                    const SizedBox(height: 30),

                    // Username
                    TextFormField(
                      controller: usernameController,
                      validator: _validateUsername,
                      decoration: _inputDecoration("Username", Icons.person_outline),
                    ),
                    const SizedBox(height: 20),

                    // Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      decoration: _inputDecoration("E-mail", Icons.email_outlined),
                    ),
                    const SizedBox(height: 20),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscurePassword,
                      validator: _validatePassword,
                      onChanged: _checkPasswordStrength,
                      decoration: _inputDecoration("Password", Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscurePassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscurePassword = !obscurePassword),
                        ),
                      ),
                    ),
                    if (passwordStrength.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          "Strength: $passwordStrength",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _getStrengthColor(),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Confirm Password
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirmPassword,
                      validator: _validateConfirmPassword,
                      decoration: _inputDecoration("Confirm Password", Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => obscureConfirmPassword = !obscureConfirmPassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Terms & Conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: agreeToTerms,
                          onChanged: (val) => setState(() => agreeToTerms = val ?? false),
                        ),
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              text: "I read and agree to the ",
                              style: const TextStyle(fontSize: 14),
                              children: [
                                TextSpan(
                                  text: "terms and conditions",
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Create Account Button
                    GradientButton(
                      text: isLoading ? "Creating..." : "Create Account",
                      onPressed: isLoading ? null: () => _signUp(),
                    ),

                    const SizedBox(height: 15),

                    // Already have account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Already have an account? "),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
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
