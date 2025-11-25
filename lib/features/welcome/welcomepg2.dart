import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class welcomepagetwo extends StatelessWidget {
  const welcomepagetwo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          image: const DecorationImage(
            image: AssetImage('assets/images/background.png'), // background image behind content
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: Container(
              height: 500,
              width: 300,
              decoration: BoxDecoration(
                  borderRadius:BorderRadius.circular(15),
                  color: Colors.white
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 250,
                    child: Image.asset(
                      'assets/images/pic2.jpg', // replace with your image
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Online Books",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Read anywhere, anytime with our collection of online books.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      context.go('/welcome3');
                    },
                    child: const Text("Next"),
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
