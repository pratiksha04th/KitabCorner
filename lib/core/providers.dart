import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import '../providers/user_provider.dart';
// Import your providers here
// import '../features/auth/providers/auth_provider.dart';
// import '../features/library/providers/library_provider.dart';

class AppProviders {
  static List<SingleChildWidget> get providers {
    return [
      // Example:
       ChangeNotifierProvider(create: (_) => UserProvider()),
      // ChangeNotifierProvider(create: (_) => LibraryProvider()),
    ];
  }
}
