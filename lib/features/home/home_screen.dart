// ignore_for_file: use_build_context_synchronously
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

// ✅ Correct imports
import 'models/book_model.dart';
import 'models/global_library.dart';
import 'models/global_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategory = 0;
  String searchQuery = "";
  late String username;

  @override
  void initState() {
    super.initState();
    username = userProfile.value['username'];
    userProfile.addListener(() {
      if (mounted) {
        setState(() {
          username = userProfile.value['username'];
        });
      }
    });
  }

  final List<Map<String, dynamic>> categories = [
    {'icon': Feather.grid, 'name': 'All'},
    {'icon': Feather.book_open, 'name': 'Novel'},
    {'icon': Feather.book, 'name': 'Education'},
    {'icon': MaterialCommunityIcons.book_open_page_variant, 'name': 'Religious'},

  ];

  // 🔹 Firestore stream for books
  Stream<List<Book>> _booksStream() {
    return FirebaseFirestore.instance
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
        snap.docs.map((d) => Book.fromMap(d.id, d.data())).toList());
  }

  // 🔹 Download and open PDF
  Future<void> _downloadAndOpenPdf(String url, {String? filename}) async {
    if (url.isEmpty) {
      _showSnack("No PDF URL found", Colors.orange);
      return;
    }

    try {
      if (kIsWeb) {
        _showSnack("Downloading not supported on Web", Colors.orange);
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final savePath =
          '${tempDir.path}/${filename ?? DateTime.now().millisecondsSinceEpoch}.pdf';

      final dio = Dio();
      final resp = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final file = File(savePath);
      await file.writeAsBytes(resp.data!);
      await OpenFilex.open(file.path);

      _showSnack("Downloaded & opened", Colors.green);
    } catch (e) {
      _showSnack("Download failed: $e", Colors.redAccent);
    }
  }

  // 🔹 Show SnackBar
  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  // 🔹 BottomSheet options
  void _showBookOptions(BuildContext context, Book book) {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF121418),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                book.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Read
            ListTile(
              leading:
              const Icon(Icons.menu_book_outlined, color: Color(0xFF2CD1C8)),
              title: const Text("Read the Book",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('read', extra: book.toMap());
              },
            ),

            // Listen
            ListTile(
              leading: const Icon(Icons.headphones, color: Color(0xFF2CD1C8)),
              title:
              const Text("Listen", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                context.pushNamed('player', extra: book.toMap());
              },
            ),

            // Download
            ListTile(
              leading: const Icon(Icons.file_download_outlined,
                  color: Color(0xFF2CD1C8)),
              title: const Text("Download (PDF)",
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
                  _downloadAndOpenPdf(
                    book.pdfUrl!,
                    filename: '${book.title.replaceAll(' ', '_')}.pdf',
                  );
                } else {
                  _showSnack("No PDF link available", Colors.orange);
                }
              },
            ),

            // Add to Library
            ListTile(
              leading: const Icon(Icons.library_add_outlined,
                  color: Color(0xFF2CD1C8)),
              title: const Text("Add to Library",
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);

                final uid = FirebaseAuth.instance.currentUser!.uid;

                final docRef = FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('library')
                    .doc(book.id);

                final doc = await docRef.get();

                if (!doc.exists) {
                  await docRef.set(book.toMap());
                  _showSnack("Added to Library", Colors.green);
                } else {
                  _showSnack("Already in Library", Colors.orange);
                }
              },
            ),

          ],
        ),
      ),
    );
  }

  // 🔹 Category chips
  Widget _buildCategoryChips() {
    return SizedBox(
      height: 55,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = selectedCategory == index;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                  colors: [Color(0xFF2CD1C8), Color(0xFF00FFC6)],
                )
                    : null,
                color: isSelected ? null : const Color(0xFF1A1D22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    categories[index]['icon'],
                    color: isSelected ? Colors.black : Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    categories[index]['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 🔹 Search bar
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.white54),
          border: InputBorder.none,
          hintText: "Search books, authors...",
          hintStyle: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }

  // 🔹 Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1115),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              colors: [Color(0xFF2CD1C8), Color(0xFF00FFC6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds);
          },
          child: Text(
            'KitabCorner',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          ValueListenableBuilder(
            valueListenable: userProfile,
            builder: (context, profile, _) {
              final photoUrl = profile['photoUrl'] ?? '';
              final username = profile['username'] ?? 'U';

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFF2CD1C8),
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  child: photoUrl.isEmpty
                      ? Text(
                    username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                      : null,
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hello, $username 👋",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              "Find your favourite category!",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildCategoryChips(),
            const SizedBox(height: 18),

            // 🔹 Carousel (Top Books)
            SizedBox(
              height: 170,
              child: StreamBuilder<List<Book>>(
                stream: _booksStream(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child:
                      CircularProgressIndicator(color: Color(0xFF2CD1C8)),
                    );
                  }

                  final books = snap.data!;
                  final filtered = selectedCategory == 0
                      ? books
                      : books
                      .where((b) =>
                  b.category == categories[selectedCategory]['name'])
                      .toList();

                  final display = filtered.take(6).toList();

                  if (display.isEmpty) {
                    return const Center(
                      child:
                      Text("No books", style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: display.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, i) {
                      final b = display[i];
                      return GestureDetector(
                        onTap: () => _showBookOptions(context, b),
                        child: Container(
                          width: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: b.cover.isNotEmpty
                                ? DecorationImage(
                              image: NetworkImage(b.cover),
                              fit: BoxFit.cover,
                            )
                                : null,
                          ),
                          child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                b.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 18),

            // 🔹 Featured List
            Expanded(
              child: StreamBuilder<List<Book>>(
                stream: _booksStream(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child:
                      CircularProgressIndicator(color: Color(0xFF2CD1C8)),
                    );
                  }

                  var books = snap.data!;
                  if (selectedCategory != 0) {
                    books = books
                        .where((b) =>
                    b.category == categories[selectedCategory]['name'])
                        .toList();
                  }
                  if (searchQuery.isNotEmpty) {
                    books = books
                        .where((b) =>
                    b.title.toLowerCase().contains(searchQuery) ||
                        b.author.toLowerCase().contains(searchQuery))
                        .toList();
                  }

                  if (books.isEmpty) {
                    return const Center(
                      child: Text("No books found",
                          style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.separated(
                    itemCount: books.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final book = books[idx];
                      return GestureDetector(
                        onTap: () => _showBookOptions(context, book),
                        child: Container(
                          height: 110,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1D22),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 75,
                                height: 90,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: book.cover.isNotEmpty
                                      ? DecorationImage(
                                    image: NetworkImage(book.cover),
                                    fit: BoxFit.cover,
                                  )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,
                                  children: [
                                    Text(book.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(book.author,
                                        style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(book.desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // 🔹 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F1115),
        selectedItemColor: const Color(0xFF2CD1C8),
        unselectedItemColor: Colors.white70,
        currentIndex: 0,
        onTap: (i) {
          if (i == 1) context.pushNamed('library');
          if (i == 2) context.pushNamed('profile');
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_rounded), label: "Library"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
