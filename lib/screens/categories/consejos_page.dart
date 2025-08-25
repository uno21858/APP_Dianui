import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/custom_app_bar.dart';

class ConsejosPage extends StatefulWidget {
  const ConsejosPage({super.key});

  @override
  State<ConsejosPage> createState() => _ConsejosPageState();
}

class _ConsejosPageState extends State<ConsejosPage> {
  String _categoriaSeleccionada = ''; // Filtro de categoría

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Evita notificaciones superpuestas

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                maxLines: 2, // Evita que el mensaje sea demasiado largo
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating, // Mejora la visibilidad
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Consejos'),
      body: Column(
        children: [
          // Barra de búsqueda por categoría
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (valor) =>
                  setState(() => _categoriaSeleccionada = valor.toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Buscar por categoría',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.search),
              ),
            ),
          ),
          // Lista de consejos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('consejos')
                  .orderBy('fecha', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  _showNotification('Error al cargar los consejos.',
                      isError: true); // Notificación de error
                  return const Center(
                      child: Text('Error al cargar los consejos.'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text('No hay consejos disponibles.'));
                }

                final consejos = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _categoriaSeleccionada.isEmpty ||
                      data['categoria']
                          .toString()
                          .toLowerCase()
                          .contains(_categoriaSeleccionada);
                }).toList();

                if (consejos.isEmpty) {
                  return const Center(
                      child: Text('No hay consejos en esta categoría.'));
                }

                return ListView.builder(
                  itemCount: consejos.length,
                  itemBuilder: (context, index) {
                    final data = consejos[index].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(data['texto']),
                        subtitle: Text(
                            'Categoría: ${data['categoria']} - Autor: ${data['autor']}'),
                        leading: const Icon(Icons.lightbulb),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}