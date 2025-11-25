import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:go_router/go_router.dart';

class AdminSecurityCheck extends StatefulWidget {
  const AdminSecurityCheck({super.key});

  @override
  State<AdminSecurityCheck> createState() => _AdminSecurityCheckState();
}

class _AdminSecurityCheckState extends State<AdminSecurityCheck> {
  final List<TextEditingController> _pinControllers =
  List.generate(6, (_) => TextEditingController());
  final String _correctPin = '102934';
  String? _errorText;

  final String registeredEmail = 'pt9413387@gmail.com';

  @override
  void dispose() {
    for (var controller in _pinControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _verifyPin() {
    String enteredPin = _pinControllers.map((controller) => controller.text).join();

    if (enteredPin == _correctPin) {
      context
          .pushReplacement(
        '/admin_screen',
      );
    } else {
      setState(() => _errorText = 'Incorrect PIN. Try again.');
    }
  }

  Future<void> _sendPinEmail() async {
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendSecurityPin');
      final response = await callable.call({
        'email': registeredEmail,
        'pin': _correctPin,
      });

      final data = response.data;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['success']
            ? 'Your security PIN has been sent to $registeredEmail'
            : 'Failed to send PIN. Try again later.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send PIN. Try again later.')),
      );
    }
  }
  void _showForgotPinDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Forgot Security PIN?",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "We will send your security PIN to:\n\n$registeredEmail",
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2F80ED),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context); // close dialog
                await _sendPinEmail();  // send email
              },
              child: const Text("Send PIN"),
            ),
          ],
        );
      },
    );
  }


  Widget _buildPinBox(int index) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black26.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _pinControllers[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          obscureText: true,
          decoration: const InputDecoration(
            counterText: '',
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          onChanged: (value) {
            if (value.isNotEmpty && index < 5) {
              FocusScope.of(context).nextFocus();
            } else if (value.isEmpty && index > 0) {
              FocusScope.of(context).previousFocus();
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(Icons.security, size: 40, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      const Text("Admin Security Check",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text("Enter your 6-digit PIN to continue",
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 24),

                      Row(children: List.generate(6, _buildPinBox)),

                      if (_errorText != null) ...[
                        const SizedBox(height: 12),
                        Text(_errorText!, style: const TextStyle(color: Colors.red)),
                      ],
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: _verifyPin,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)]),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text("Verify PIN",
                                  style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      GestureDetector(
                        onTap: () => _showForgotPinDialog(),
                        child: const Text("Forgot Security PIN?",
                            style: TextStyle(
                              color: Color(0xFF2F80ED),
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
