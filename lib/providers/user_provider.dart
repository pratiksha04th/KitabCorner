import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  User? _user;
  String? _username;
  String? _photoUrl;

  UserProvider() {
    _loadUser();
  }

  User? get user => _user;
  String get username => _username ?? _user?.displayName ?? "User";
  String? get photoUrl => _photoUrl ?? _user?.photoURL;

  /// 🔹 Load initial Firebase user data
  Future<void> _loadUser() async {
    _user = FirebaseAuth.instance.currentUser;
    _username = _user?.displayName;
    _photoUrl = _user?.photoURL;
    await _syncFromFirestore();
    notifyListeners();
  }

  /// 🔹 Fetch and sync user data from Firestore
  Future<void> _syncFromFirestore() async {
    if (_user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      final data = doc.data();
      if (data != null) {
        _username = data['username'] ?? _username;
        _photoUrl = data['photoUrl'] ?? _photoUrl;
      }
    }
  }

  /// 🔹 Manually refresh Firebase user & Firestore
  Future<void> refreshUser() async {
    await _user?.reload();
    _user = FirebaseAuth.instance.currentUser;
    await _syncFromFirestore();
    _username = _user?.displayName ?? _username;
    _photoUrl = _user?.photoURL ?? _photoUrl;
    notifyListeners();
  }

  /// 🔹 Update username both in FirebaseAuth & Firestore
  Future<void> updateUsername(String name) async {
    if (_user == null) return;

    await _user!.updateDisplayName(name);
    _username = name;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .set({'username': name}, SetOptions(merge: true));

    notifyListeners();
  }

  /// 🔹 Update photo both in FirebaseAuth & Firestore
  Future<void> updatePhoto(String url) async {
    if (_user == null) return;

    await _user!.updatePhotoURL(url);
    _photoUrl = url;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .set({'photoUrl': url}, SetOptions(merge: true));

    notifyListeners();
  }

  /// 🔹 Allow setting username/photo manually (used in ProfileScreen)
  void setUserData({String? username, String? photoUrl}) {
    if (username != null) _username = username;
    if (photoUrl != null) _photoUrl = photoUrl;
    notifyListeners();
  }

  /// 🔹 Clear on sign out
  void clearUser() {
    _user = null;
    _username = null;
    _photoUrl = null;
    notifyListeners();
  }
}
