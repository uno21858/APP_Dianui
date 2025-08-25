import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/blog_article.dart';
import '../../widgets/custom_app_bar.dart';

class BlogDetailPage extends StatelessWidget {
  final BlogArticle article;

  const BlogDetailPage({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: article.title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título del artículo
            Text(
              article.title,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // Información del autor, fecha y categoría
            Row(
              children: [
                const Icon(Icons.person, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  article.author,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  DateFormat('dd MMMM yyyy').format(article.date.toDate()), // Formato bonito
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.label, size: 18, color: Colors.grey),
                const SizedBox(width: 5),
                Text(
                  article.category,
                  style: const TextStyle(fontSize: 14, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Descripción (si existe)
            if (article.description.isNotEmpty) ...[
              Text(
                article.description,
                style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black87),
              ),
              const SizedBox(height: 20),
            ],

            // Contenido del artículo
            Text(
              article.content,
              style: const TextStyle(fontSize: 16, color: Colors.black),
              textAlign: TextAlign.justify,
            ),

            const SizedBox(height: 30),

            // Sección de likes
            Row(
              children: [
                const Icon(Icons.favorite, color: Colors.red, size: 22),
                const SizedBox(width: 5),
                Text(
                  '${article.likes} Me gusta',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
