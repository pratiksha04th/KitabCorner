import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  File? _coverFile;
  Uint8List? _coverBytes;
  File? _pdfFile;
  Uint8List? _pdfBytes;

  bool _isUploading = false;
  String _selectedCategory = "Novel";
  final List<String> categories = ["Novel", "Education", "Religious"];

  final booksRef = FirebaseFirestore.instance.collection('books');

  // ✅ Pick Cover Image
  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      if (kIsWeb) {
        _coverBytes = result.files.single.bytes;
      } else {
        _coverFile = File(result.files.single.path!);
      }
      setState(() {});
    }
  }

  // ✅ Pick PDF File
  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    if (result != null) {
      if (kIsWeb) {
        _pdfBytes = result.files.single.bytes;
      } else {
        _pdfFile = File(result.files.single.path!);
      }
      setState(() {});
    }
  }

  // ✅ Upload File (cover or PDF)
  Future<String> _uploadFile({
    required String folder,
    File? file,
    Uint8List? bytes,
  }) async {
    // 🔴 1) FORCE the correct bucket here:
    final storage = FirebaseStorage.instanceFor(
      bucket: 'kitabcorner-be8ee.firebasestorage.app',
    );

    final fileName = '${DateTime.now().millisecondsSinceEpoch}';
    final ref = storage.ref().child('$folder/$fileName');

    final metadata = SettableMetadata(
      contentType: folder == 'book_pdfs' ? 'application/pdf' : 'image/png',
    );

    UploadTask uploadTask;

    if (kIsWeb && bytes != null) {
      uploadTask = ref.putData(bytes, metadata);
    } else if (file != null) {
      uploadTask = ref.putFile(file, metadata);
    } else {
      throw Exception("No file selected for upload");
    }

    try {
      // wait for upload to complete
      final snapshot = await uploadTask.whenComplete(() {});
      // get download URL
      final url = await snapshot.ref.getDownloadURL();
      return url;
    } on FirebaseException catch (e) {
      debugPrint('🔥 STORAGE ERROR: ${e.code}  ${e.message}');
      rethrow;
    }
  }



  // ✅ Add Book to Firestore
  Future<void> _addBook() async {
    if (!_formKey.currentState!.validate()) return;

    if ((kIsWeb && (_coverBytes == null || _pdfBytes == null)) ||
        (!kIsWeb && (_coverFile == null || _pdfFile == null))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please select both cover and PDF")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final coverUrl = await _uploadFile(
        folder: 'book_covers',
        file: _coverFile,
        bytes: _coverBytes,
      );

      final pdfUrl = await _uploadFile(
        folder: 'book_pdfs',
        file: _pdfFile,
        bytes: _pdfBytes,
      );

      await booksRef.add({
        'title': _titleController.text.trim(),
        'author': _authorController.text.trim(),
        'desc': _descController.text.trim(),
        'category': _selectedCategory,
        'cover': coverUrl,
        'pdfUrl': pdfUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _titleController.clear();
      _authorController.clear();
      _descController.clear();
      _coverFile = null;
      _coverBytes = null;
      _pdfFile = null;
      _pdfBytes = null;
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Book added successfully!"),
          backgroundColor: Color(0xFF2F80ED),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to add book: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  // ✅ Delete Book
  Future<void> _deleteBook(String id) async {
    try {
      await booksRef.doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑️ Book deleted"),
          backgroundColor: Colors.orangeAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to delete book: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ✅ Edit Book Dialog
  Future<void> _editBook(String id, Map<String, dynamic> oldData) async {
    final titleCtrl = TextEditingController(text: oldData['title']);
    final authorCtrl = TextEditingController(text: oldData['author']);
    final descCtrl = TextEditingController(text: oldData['desc']);
    String category = oldData['category'];
    File? newCover;
    Uint8List? newCoverBytes;
    File? newPdf;
    Uint8List? newPdfBytes;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Book"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: 'Author')),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              DropdownButtonFormField<String>(
                value: category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => category = val!,
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    withData: true,
                  );
                  if (result != null) {
                    if (kIsWeb) {
                      newCoverBytes = result.files.single.bytes;
                    } else {
                      newCover = File(result.files.single.path!);
                    }
                  }
                },
                child: const Text("Change Cover"),
              ),
              ElevatedButton(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                    withData: true,
                  );
                  if (result != null) {
                    if (kIsWeb) {
                      newPdfBytes = result.files.single.bytes;
                    } else {
                      newPdf = File(result.files.single.path!);
                    }
                  }
                },
                child: const Text("Change PDF"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String coverUrl = oldData['cover'];
              String pdfUrl = oldData['pdfUrl'];

              if (newCover != null || newCoverBytes != null) {
                coverUrl = await _uploadFile(
                  folder: 'book_covers',
                  file: newCover,
                  bytes: newCoverBytes,
                );
              }
              if (newPdf != null || newPdfBytes != null) {
                pdfUrl = await _uploadFile(
                  folder: 'book_pdfs',
                  file: newPdf,
                  bytes: newPdfBytes,
                );
              }

              await booksRef.doc(id).update({
                'title': titleCtrl.text.trim(),
                'author': authorCtrl.text.trim(),
                'desc': descCtrl.text.trim(),
                'category': category,
                'cover': coverUrl,
                'pdfUrl': pdfUrl,
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Book updated")),
                );
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  // ✅ Logout
  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (context.mounted) context.go('/welcome1'); // ⚙️ Redirect to start
  }

  // ✅ Switch to User Home
  void _switchToUser() {
    context.go('/home'); // ⚙️ GoRouter navigation instead of MaterialPageRoute
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        validator: (v) => v!.isEmpty ? "Enter $label" : null,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text("Admin Panel"),
          actions: [
            IconButton(
              icon: const Icon(Icons.switch_account),
              tooltip: "Switch to User Account",
              onPressed: _switchToUser,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _logout,
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "Add Book"),
              Tab(text: "Manage Books"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // ✅ Add Book Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField("Book Title", _titleController),
                    _buildTextField("Author", _authorController),
                    _buildTextField("Description", _descController, maxLines: 3),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickCover,
                      icon: const Icon(Icons.image),
                      label: const Text("Select Cover"),
                    ),
                    if ((kIsWeb && _coverBytes != null) || (!kIsWeb && _coverFile != null))
                      const Text("✅ Cover selected", style: TextStyle(color: Colors.green)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.picture_as_pdf),
                      label: const Text("Select PDF"),
                    ),
                    if ((kIsWeb && _pdfBytes != null) || (!kIsWeb && _pdfFile != null))
                      const Text("✅ PDF selected", style: TextStyle(color: Colors.green)),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isUploading ? null : _addBook,
                        child: _isUploading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text("Add Book"),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ✅ Manage Books Tab
            StreamBuilder<QuerySnapshot>(
              stream: booksRef.orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text("No books found"));
                }

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: data['cover'] != null
                            ? CachedNetworkImage(
                          imageUrl: data['cover'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.book),
                        title: Text(data['title']),
                        subtitle: Text(data['author']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.edit), onPressed: () => _editBook(id, data)),
                            IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteBook(id)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
