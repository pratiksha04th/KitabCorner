import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/user_provider.dart';
import '../home/models/global_user.dart'; // ✅ NEW global notifier

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  File? _profileImage;
  final User? _user = FirebaseAuth.instance.currentUser;
  String _username = '';
  String _language = 'English';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _username = _user?.displayName ?? '';
    _loadLanguagePreference();
  }

  /// Load saved language from local storage
  Future<void> _loadLanguagePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _language = prefs.getString('selected_language') ?? 'English';
    });
  }

  /// Save language to local storage
  Future<void> _saveLanguagePreference(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_language', lang);
  }

  /// Pick and upload profile image to Firebase Storage
  Future<void> _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() {
      _profileImage = File(image.path);
      _uploading = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${_user!.uid}.jpg');

      await storageRef.putFile(_profileImage!);
      final photoUrl = await storageRef.getDownloadURL();

      await _user?.updatePhotoURL(photoUrl);

      if (mounted) {
        Provider.of<UserProvider>(context, listen: false).updatePhoto(photoUrl);
      }

      // ✅ Update global notifier
      userProfile.value = {
        ...userProfile.value,
        'photoUrl': photoUrl,
      };

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  /// Change username and sync with FirebaseAuth + Provider
  void _changeUsername() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller =
        TextEditingController(text: _username);
        return AlertDialog(
          backgroundColor: const Color(0xFF14202E),
          title: Text('Change Username',
              style: GoogleFonts.poppins(color: Colors.white)),
          content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter new username',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              Text('Cancel', style: GoogleFonts.poppins(color: Colors.cyan)),
            ),
            TextButton(
              onPressed: () async {
                final newName = controller.text.trim();
                if (newName.isNotEmpty) {
                  setState(() => _username = newName);
                  await _user?.updateDisplayName(newName);

                  if (mounted) {
                    Provider.of<UserProvider>(context, listen: false)
                        .updateUsername(newName);
                  }

                  // ✅ Update global notifier
                  userProfile.value = {
                    ...userProfile.value,
                    'username': newName,
                  };

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username updated!')),
                  );
                }
              },
              child: Text('Save',
                  style: GoogleFonts.poppins(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  /// Change password (via email reset link)
  void _changePassword() {
    final TextEditingController emailController =
    TextEditingController(text: _user?.email ?? '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF14202E),
          title: Text('Reset Password',
              style: GoogleFonts.poppins(color: Colors.white)),
          content: TextField(
            controller: emailController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Enter your registered email',
              hintStyle: TextStyle(color: Colors.white54),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              Text('Cancel', style: GoogleFonts.poppins(color: Colors.cyan)),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.sendPasswordResetEmail(
                    email: emailController.text.trim(),
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content:
                        Text('Password reset link sent to your email.')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Send Link',
                  style: GoogleFonts.poppins(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  /// Change app language
  void _changeLanguage() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLang = _language;
        return AlertDialog(
          backgroundColor: const Color(0xFF14202E),
          title: Text('Change Language',
              style: GoogleFonts.poppins(color: Colors.white)),
          content: DropdownButton<String>(
            value: tempLang,
            dropdownColor: const Color(0xFF14202E),
            items: ['English', 'Spanish', 'French', 'German', 'Hindi', 'Punjabi']
                .map((lang) => DropdownMenuItem(
              value: lang,
              child:
              Text(lang, style: const TextStyle(color: Colors.white)),
            ))
                .toList(),
            onChanged: (val) => setState(() => tempLang = val ?? 'English'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
              Text('Cancel', style: GoogleFonts.poppins(color: Colors.cyan)),
            ),
            TextButton(
              onPressed: () {
                setState(() => _language = tempLang);
                _saveLanguagePreference(tempLang);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Language changed to $_language',
                          style: const TextStyle(color: Colors.white))),
                );
              },
              child: Text('Save',
                  style: GoogleFonts.poppins(color: Colors.greenAccent)),
            ),
          ],
        );
      },
    );
  }

  /// About App
  void _showAboutApp() {
    showAboutDialog(
      context: context,
      applicationName: 'Kitab Corner',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.menu_book, color: Colors.cyan),
      applicationLegalese: '© 2025 Kitab Corner Team\nAll rights reserved.',
      children: const [
        Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Kitab Corner is your personal digital library app — explore, read, and manage your favorite books seamlessly. 📚',
          ),
        ),
      ],
    );
  }

  /// Help & Support → opens email
  Future<void> _openSupportEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@kitabcorner.app',
      queryParameters: {
        'subject': 'Help & Support - Kitab Corner App',
        'body':
        'Hi Kitab Corner Team,\n\nI need help with...\n\n(User: ${_user?.email ?? 'Guest'})'
      },
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email app.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgPrimary = Color(0xFF0D1117);
    const List<Color> accentGradient = [Colors.cyan, Colors.greenAccent];

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: accentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
          child: Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _uploading ? null : _pickProfileImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.cyan,
                    backgroundImage:
                    _profileImage != null ? FileImage(_profileImage!) : null,
                    child: _profileImage == null
                        ? Text(
                      _username.isNotEmpty
                          ? _username[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 40, color: Colors.white),
                    )
                        : null,
                  ),
                  if (_uploading)
                    const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white70),
              title: const Text('Change Username',
                  style: TextStyle(color: Colors.white)),
              onTap: _changeUsername,
            ),
            ListTile(
              leading: const Icon(Icons.lock, color: Colors.white70),
              title: const Text('Change Password',
                  style: TextStyle(color: Colors.white)),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.language, color: Colors.white70),
              title: const Text('Change Language',
                  style: TextStyle(color: Colors.white)),
              onTap: _changeLanguage,
            ),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70),
              title: const Text('About App',
                  style: TextStyle(color: Colors.white)),
              onTap: _showAboutApp,
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.white70),
              title: const Text('Help & Support',
                  style: TextStyle(color: Colors.white)),
              onTap: _openSupportEmail,
            ),
          ],
        ),
      ),
    );
  }
}
