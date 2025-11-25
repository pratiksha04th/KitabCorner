import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class welcomepagethree extends StatelessWidget {
  const welcomepagethree({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11),
          image: const DecorationImage(
            image: AssetImage('assets/images/background.png'), // same background
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SafeArea(
            child: Container(
              height: 500,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Top image
                  SizedBox(
                    height: 250,
                    child: Image.asset(
                      'assets/images/pic3.jpg', // your new image
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Title
                  const Text(
                    "Choose Your Book",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle / description
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      "Pick your favorite books from our wide range of categories.",
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Next button
                  ElevatedButton(
                    onPressed: () {
                      context.go('/login');
                    },
                    child: const Text("Next",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),
                    ),
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
