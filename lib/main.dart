import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core & Firebase
import 'core/providers.dart';
import 'core/router.dart';
import 'firebase_options.dart';
import 'providers/user_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔹 Hot restart safe Firebase initialization
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      debugPrint('Firebase already initialized.');
    } else {
      rethrow; // unexpected errors
    }
  }

  // ✅ Run the app
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ...AppProviders.providers,
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppRouter.router;

    return MaterialApp.router(
      title: 'KitabCorner',
      debugShowCheckedModeBanner: false,

      // ✅ Theme setup
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: Colors.cyan,
      ),
      themeMode: ThemeMode.system,

      // ✅ Router setup
      routerConfig: router,
    );
  }
}
