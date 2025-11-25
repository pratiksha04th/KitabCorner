import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitab_corner/features/home/read_pg.dart';
import 'player_screen.dart';
import 'models/book_model.dart';
import 'package:open_filex/open_filex.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  // 🔹 Fetch user library from Firestore
  Stream<List<Book>> _libraryStream() {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("library")
        .snapshots()
        .map((snap) =>
        snap.docs.map((doc) => Book.fromMap(doc.id, doc.data())).toList());
  }

  // 🔹 Remove a book
  Future<void> _removeBook(String bookId) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("library")
        .doc(bookId)
        .delete();
  }

  // 🔹 Download & Open PDF
  Future<void> _downloadFile(BuildContext context, String url) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final savePath = "${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.pdf";

      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
        ),
      );

      final file = File(savePath);
      await file.writeAsBytes(response.data!);

      await OpenFilex.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF Downloaded & Opened")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error downloading PDF: $e")),
      );
    }
  }

  // 🔹 Bottom sheet options (same as HomeScreen)
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
            Text(
              book.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 16),

            // 📖 Read
            ListTile(
              leading: const Icon(Icons.menu_book_outlined, color: Color(0xFF2CD1C8)),
              title: const Text("Read the Book", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReadPage(book: book.toMap()),
                  ),
                );
              },
            ),

            // 🎧 Listen
            ListTile(
              leading: const Icon(Icons.headphones, color: Color(0xFF2CD1C8)),
              title: const Text("Listen", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PlayerScreen(
                      book: {
                        ...book.toMap(),
                        'elapsed': 0,
                        'duration': 2700,
                      },
                    ),
                  ),
                );
              },
            ),

            // ⬇ Download PDF
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Color(0xFF2CD1C8)),
              title: const Text("Download PDF", style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                if (book.pdfUrl != null && book.pdfUrl!.isNotEmpty) {
                  _downloadFile(context, book.pdfUrl!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Downloading PDF...")),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("PDF not available")),
                  );
                }
              },

            ),

            // ❌ Remove from Library
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
              title: const Text("Remove from Library",
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _removeBook(book.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Removed from Library")),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgPrimary = Color(0xFF0D1117);
    final accentGradient = [Colors.cyan, Colors.greenAccent];

    return Scaffold(
      backgroundColor: bgPrimary,
      appBar: AppBar(
        backgroundColor: bgPrimary,
        elevation: 0,
        leading: IconButton(
          icon: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: accentGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(bounds),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: accentGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: Text(
            "Library",
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),

      // 🔹 Library Book Stream
      body: StreamBuilder<List<Book>>(
        stream: _libraryStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2CD1C8)),
            );
          }

          final books = snapshot.data!;

          if (books.isEmpty) {
            return const Center(
              child: Text(
                "Your library is empty.",
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            itemBuilder: (context, index) {
              final book = books[index];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book.cover,
                    width: 55,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(book.title,
                    style: const TextStyle(color: Colors.white)),
                subtitle: Text(book.author,
                    style: const TextStyle(color: Colors.white70)),
                onTap: () => _showBookOptions(context, book),
              );
            },
          );
        },
      ),
    );
  }
}
