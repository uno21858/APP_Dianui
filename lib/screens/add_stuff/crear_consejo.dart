import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../widgets/custom_app_bar.dart';

class SubirConsejoPage extends StatefulWidget {
  const SubirConsejoPage({super.key});

  @override
  State<SubirConsejoPage> createState() => _SubirConsejoPageState();
}

class _SubirConsejoPageState extends State<SubirConsejoPage> {
  final TextEditingController _consejoController = TextEditingController();
  final List<String> _categoriasPredefinidas = [
    "Salud general",
    "Nutrición",
    "Ejercicio",
    "Bienestar mental",
    "Sueño",
    "Hidratación",
    "Otro",
  ];
  String _categoriaSeleccionada = "Salud general";
  bool _isLoading = false;

  Future<void> _subirConsejo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showNotification('Debes iniciar sesión para publicar un consejo.', isError: true);
      return;
    }

    if (_consejoController.text.isEmpty) {
      _showNotification('Escribe un consejo antes de enviar.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔹 Obtener nombre del usuario desde Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String authorName = userDoc.exists ? userDoc['name'] ?? 'Anónimo' : 'Anónimo';

      await FirebaseFirestore.instance.collection('consejos').add({
        'texto': _consejoController.text.trim(),
        'categoria': _categoriaSeleccionada.toLowerCase(),
        'autor': authorName,
        'fecha': Timestamp.now(),
      });

      setState(() => _isLoading = false);
      _consejoController.clear();

      _showNotification("Consejo publicado con éxito", isError: false);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });

    } catch (e) {
      _showNotification('Error al publicar el consejo: $e', isError: true);
      setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!mounted) return; // ⚠️ Evita errores si el widget ya no está en el árbol

    ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Evita notificaciones superpuestas

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isError ? Colors.red[600] : Colors.green[600],
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                isError ? Icons.error_outline : Icons.check_circle_outline,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent, // Fondo transparente
        elevation: 0, // Sin sombra
        behavior: SnackBarBehavior.floating, // Flotante
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Crear Consejo'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Comparte un Consejo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Selecciona una categoría:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 10),
              // Lista de categorías predefinidas
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _categoriasPredefinidas.map((categoria) {
                  return ChoiceChip(
                    label: Text(categoria),
                    selected: _categoriaSeleccionada == categoria,
                    selectedColor: Colors.green,
                    onSelected: (selected) {
                      setState(() {
                        _categoriaSeleccionada = categoria;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _consejoController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Escribe tu consejo',
                  hintText: 'Ej: Bebe al menos 2 litros de agua al día.',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _subirConsejo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  'Publicar Consejo',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}