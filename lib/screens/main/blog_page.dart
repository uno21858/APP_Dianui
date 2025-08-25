import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/blog_article.dart';
import '../../widgets/fab_nutriologo.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/blog_detail_page.dart';
import 'package:intl/intl.dart'; // Para formatear la fecha

class BlogPage extends StatefulWidget {
  const BlogPage({super.key});

  @override
  _BlogPageState createState() => _BlogPageState();
}

class _BlogPageState extends State<BlogPage> {
  late Stream<List<BlogArticle>> _blogArticles;
  String? selectedCategory;
  bool sortByNewest = true;
  bool sortByLikes = false;
  bool isUpdatingLike = false; // Estado para evitar múltiples clics rápidos
  final List<String> categories = [
    'Todas',
    'Nutrición General',
    'Dietas',
    'Suplementación',
    'Salud Digestiva',
    'Pérdida de Peso',
    'Rendimiento Deportivo'
  ];

  @override
  void initState() {
    super.initState();
    _blogArticles = fetchBlogArticles();
  }

  Stream<List<BlogArticle>> fetchBlogArticles() {
    return FirebaseFirestore.instance.collection('blog').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => BlogArticle.fromFirestore(doc)).toList();
    });
  }

  Future<void> toggleLike(String articleId, int currentLikes) async {
    if (isUpdatingLike) return; // Evitar múltiples clics rápidos
    setState(() {
      isUpdatingLike = true;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        isUpdatingLike = false;
      });
      return;
    }

    final userLikesRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('likes').doc(articleId);
    final articleRef = FirebaseFirestore.instance.collection('blog').doc(articleId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userLikeDoc = await transaction.get(userLikesRef);
      final articleDoc = await transaction.get(articleRef);
      if (!articleDoc.exists) return;

      int currentLikes = articleDoc['likes'] ?? 0;

      if (userLikeDoc.exists) {
        transaction.delete(userLikesRef);
        transaction.update(articleRef, {'likes': currentLikes - 1});
      } else {
        transaction.set(userLikesRef, {'likedAt': FieldValue.serverTimestamp()});
        transaction.update(articleRef, {'likes': currentLikes + 1});
      }
    });

    setState(() {
      isUpdatingLike = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Blog'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<String>(
                  value: selectedCategory,
                  hint: const Text('Filtrar por categoría'),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCategory = newValue == 'Todas' ? null : newValue;
                    });
                  },
                  items: categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(sortByNewest ? Icons.arrow_downward : Icons.arrow_upward),
                      onPressed: () {
                        setState(() {
                          sortByNewest = !sortByNewest;
                          sortByLikes = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.favorite),
                      color: sortByLikes ? Colors.red : Colors.grey,
                      onPressed: () {
                        setState(() {
                          sortByLikes = !sortByLikes;
                          sortByNewest = false;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<BlogArticle>>(
              stream: _blogArticles,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar los artículos'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay publicaciones disponibles'));
                }

                List<BlogArticle> articles = snapshot.data!;

                if (selectedCategory != null) {
                  articles = articles.where((article) => article.category == selectedCategory).toList();
                }

                if (sortByLikes) {
                  articles.sort((a, b) => b.likes.compareTo(a.likes));
                } else {
                  articles.sort((a, b) => sortByNewest ? b.date.compareTo(a.date) : a.date.compareTo(b.date));
                }

                return ListView.builder(
                  itemCount: articles.length,
                  itemBuilder: (context, index) {
                    final article = articles[index];
                    String formattedDate = DateFormat('dd/MM/yyyy').format(article.date.toDate());
                    
                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        title: Text(article.title),
                        subtitle: Text('Por ${article.author} | $formattedDate | ${article.category}'),
                        trailing: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(FirebaseAuth.instance.currentUser?.uid)
                            .collection('likes')
                            .doc(article.id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          bool isLiked = snapshot.hasData && snapshot.data!.exists;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('${article.likes}'),
                              IconButton(
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                                color: isLiked ? Colors.red : Colors.grey,
                                onPressed: isUpdatingLike ? null : () => toggleLike(article.id, article.likes),
                              ),
                            ],
                          );
                        },
                      ),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BlogDetailPage(article: article),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const NutriologoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
