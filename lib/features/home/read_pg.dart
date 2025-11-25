import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReadPage extends StatefulWidget {
  final Map<String, dynamic> book;
  const ReadPage({super.key, required this.book});

  @override
  State<ReadPage> createState() => _ReadPageState();
}

class _ReadPageState extends State<ReadPage> {
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = true;
  bool _hasError = false;

  @override
  Widget build(BuildContext context) {
    final String? pdfUrl = widget.book['pdfUrl'] as String?;
    final String title = widget.book['title'] ?? "Read Book";
    final String author = widget.book['author'] ?? "Unknown Author";
    final String desc = widget.book['desc'] ?? "";

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark, color: Colors.white),
            onPressed: () {
              _pdfViewerKey.currentState?.openBookmarkView();
            },
          ),
        ],
      ),
      body: pdfUrl != null && pdfUrl.isNotEmpty
          ? Column(
        children: [
          // Book info header
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1B2233),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.cyan,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("by $author",
                    style:
                    const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text(desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                    const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),

          // PDF Viewer
          Expanded(
            child: Stack(
              children: [
                SfPdfViewer.network(
                  pdfUrl,
                  key: _pdfViewerKey,
                  onDocumentLoaded: (details) {
                    setState(() => _isLoading = false);
                  },
                  onDocumentLoadFailed: (details) {
                    setState(() {
                      _isLoading = false;
                      _hasError = true;
                    });
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                if (_hasError)
                  const Center(
                    child: Text(
                      "Failed to load PDF",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
              ],
            ),
          ),
        ],
      )
          : const Center(
        child: Text(
          "PDF not available",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
