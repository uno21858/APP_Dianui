import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import para formatear la fecha

class BlogArticle {
  final String id;
  final String title;
  final String author;
  final Timestamp date; // Ahora es Timestamp en lugar de String
  final String description;
  final String content;
  final String category;
  final int likes; // Nuevo campo para los likes

  BlogArticle({
    required this.id,
    required this.title,
    required this.author,
    required this.date,
    required this.description,
    required this.content,
    required this.category,
    required this.likes,
  });

  // Método para crear una instancia desde Firestore
  factory BlogArticle.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) {
      throw Exception("Documento vacío o inválido");
    }

    return BlogArticle(
      id: doc.id, // Asigna el ID del documento
      title: data['title'] ?? 'Sin título',
      author: data['author'] ?? 'Autor desconocido',
      date: data['date'] is Timestamp ? data['date'] : Timestamp.now(), // Maneja Timestamp correctamente
      description: data['description'] ?? 'Sin descripción',
      content: data['content'] ?? 'Sin contenido',
      category: data['category'] ?? 'General',
      likes: (data['likes'] ?? 0).toInt(), // Asegura que los likes sean un entero
    );
  }

  // Método para formatear la fecha correctamente
  String getFormattedDate() {
    return DateFormat('dd/MM/yyyy').format(date.toDate());
  }
}

// Método para obtener los artículos desde Firestore
Future<List<BlogArticle>> fetchBlogArticles() async {
  try {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('blog').get();
    if (querySnapshot.docs.isEmpty) {
      return [];
    }
    return querySnapshot.docs.map((doc) => BlogArticle.fromFirestore(doc)).toList();
  } catch (e) {
    print('Error al obtener publicaciones: $e');
    return [];
  }
}
