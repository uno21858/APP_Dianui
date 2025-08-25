import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddBlogPage extends StatefulWidget {
  const AddBlogPage({super.key});

  @override
  _AddBlogPageState createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  String? _selectedCategory;
  bool _isSubmitting = false;
  final List<String> _categories = [
    'Nutrición General',
    'Dietas',
    'Suplementación',
    'Salud Digestiva',
    'Pérdida de Peso',
    'Rendimiento Deportivo'
  ];

  Future<void> _publishArticle() async {
    if (!_formKey.currentState!.validate() || _selectedCategory == null) return;

    setState(() => _isSubmitting = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Obtener el nombre del usuario actual
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String authorName = userDoc['name'] ?? 'Autor desconocido';

      // Obtener la fecha actual en hora de México
      Timestamp currentTimestamp = Timestamp.now();
      
      // Crear la nueva publicación
      await FirebaseFirestore.instance.collection('blog').add({
        'title': _titleController.text.trim(),
        'author': authorName,
        'date': currentTimestamp,
        'description': _descriptionController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'likes': 0
      });

      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Publicación añadida con éxito.')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nueva Publicación')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value!.isEmpty ? 'Ingrese un título' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción breve'),
                validator: (value) => value!.isEmpty ? 'Ingrese una descripción' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Contenido'),
                validator: (value) => value!.isEmpty ? 'Ingrese el contenido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Categoría'),
                value: _selectedCategory,
                items: _categories.map((category) => DropdownMenuItem(
                  value: category,
                  child: Text(category),
                )).toList(),
                onChanged: (value) => setState(() => _selectedCategory = value),
                validator: (value) => value == null ? 'Seleccione una categoría' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _publishArticle,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Publicar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}