import 'package:flutter/foundation.dart';

/// Global ValueNotifier to keep the local library in-memory and update UI.
ValueNotifier<List<Map<String, dynamic>>> libraryBooks =
ValueNotifier<List<Map<String, dynamic>>>([]);
