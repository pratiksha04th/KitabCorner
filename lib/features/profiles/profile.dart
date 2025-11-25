import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:kitab_corner/features/home/library.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';
import 'settings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _userDoc;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    _fetchUserDoc();
  }

  Future<void> _fetchUserDoc() async {
    if (_user == null) {
      setState(() => _loading = false);
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();

    if (doc.exists) {
      _userDoc = doc.data();

      // ✅ Update provider with latest data from Firestore
      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).setUserData(
          username: _userDoc!['username'] ?? _user?.displayName ?? 'User',
          photoUrl: _userDoc!['photoUrl'] ?? _user?.photoURL ?? '',
        );
      }
    }

    setState(() => _loading = false);
  }

  // ✅ Confirmation dialog before sign out
  Future<void> _confirmSignOut() async {
    final bool? shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1D22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Confirm Logout",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to log out?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("No", style: TextStyle(color: Color(0xFF2CD1C8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      _signOut();
    }
  }

  // ✅ Proper Sign Out — navigates back to login screen
  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final username = userProvider.username ?? _user?.displayName ?? 'User';
    final photoUrl = userProvider.photoUrl ?? _user?.photoURL ?? '';
    final email = _user?.email ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [Colors.cyan, Colors.greenAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
          ),
        ),
        title: const Text(
          'Profile',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),

      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFF2CD1C8)),
      )
          : RefreshIndicator(
        onRefresh: _fetchUserDoc,
        color: const Color(0xFF2CD1C8),
        backgroundColor: const Color(0xFF1A1D22),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ✅ Profile Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF14171C),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF2CD1C8),
                        backgroundImage: (photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl.isEmpty)
                            ? Text(
                          username.isNotEmpty
                              ? username[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email,
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ My Library
                ListTile(
                  leading: const Icon(Icons.library_books,
                      color: Color(0xFF2CD1C8)),
                  title: const Text('My Library',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LibraryScreen()),
                    );
                    _fetchUserDoc();
                  },
                ),

                // ✅ Account Settings
                ListTile(
                  leading: const Icon(Icons.settings,
                      color: Color(0xFF2CD1C8)),
                  title: const Text('Account Settings',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen()),
                    );
                    await _fetchUserDoc();
                  },
                ),

                const SizedBox(height: 20),
                const Divider(color: Colors.white24),

                const SizedBox(height: 20),

                // ✅ Sign Out Button with Confirmation
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2CD1C8),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _confirmSignOut,
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Log Out",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
