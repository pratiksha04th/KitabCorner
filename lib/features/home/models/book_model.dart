class Book {
  final String id;
  final String title;
  final String author;
  final String cover;     // Network Image URL
  final String desc;
  final String category;
  final String? pdfUrl;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.cover,
    required this.desc,
    required this.category,
    this.pdfUrl,
  });

  factory Book.fromMap(String id, Map<String, dynamic> map) {
    return Book(
      id: id,
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      cover: map['cover'] ?? '',
      desc: map['desc'] ?? '',
      category: map['category'] ?? 'All',
      pdfUrl: map['pdfUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover': cover,
      'desc': desc,
      'category': category,
      'pdfUrl': pdfUrl,
    };
  }
}
