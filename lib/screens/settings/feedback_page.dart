import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main/main_screen.dart';

// define a custom Form Widget
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  FeedbackPageState createState() {
    return FeedbackPageState();
  }
}

// Define a corresponding state class
// This class holds data related to the form
class FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedValue = 'Sugerencia';
  final TextEditingController _messageController = TextEditingController();

  // Variable para desactivar el botón mientras se mandan los datos
  bool _isSending = false;

  // Obtener datos del usuario
  User? user;
  String? email;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    email = user?.email;
  }

  // Liberar espacio en memoria
  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        if (_messageController.text.isNotEmpty) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('¿Descartar mensaje?'),
              content: const Text('Tienes un mensaje sin enviar. ¿Deseas salir sin enviarlo? El mensaje se borrará.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Salir'),
                ),
              ],
            ),
          );

          if (shouldExit == true && context.mounted) {
            Navigator.of(context).pop(); // Cierra la pantalla
          }
        } else {
          Navigator.of(context).pop(); // No hay mensaje, cierra directamente
        }
      },
      child: Scaffold(
      appBar: AppBar(
          title: const Text(
            'Soporte',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color.fromARGB(255, 2, 80, 145),
        ),
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: <Widget>[
                // Logo centrado arriba
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    height: 100,
                    )
                ),

                // Title
                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Envianos tu feedback",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    )
                  )
                ),

                const SizedBox(height: 16),

                const Text(
                  "Tu opinión es muy importante para nosotros. Por favor, cuéntanos cómo podemos mejorar o si encontraste algún problema.",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.left, // O left/center según prefieras
                ),

                const SizedBox(height: 16),
                // This is the place to add texform fields and elevated buttons
                TextFormField(
                  // Obtener el mensaje
                  controller: _messageController,
                  // Define the minimum and maximum caracters
                  maxLength: 300,
                  // TextFormField decoration
                  decoration: InputDecoration(
                    hintText: "Escribe tu sugerencia o comentario en este cuadro.",
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 10,
                  // The validator receives the text that the user has entered.
                  validator: (value) {
                    if (value == null || value.trim().length < 20) {
                      return 'Debes tener al menos 20 carácteres';
                    }
                    return null;
                  },
                ),

                // Blank space
                const SizedBox(height: 16),

                // Categorizar las sugerencias
                DropdownButtonFormField<String>(
                  value: _selectedValue,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Sugerencia',
                      child: Row(
                        children: const [
                          Icon(Icons.lightbulb_outline),
                          SizedBox(width: 8),
                          Text('Sugerencia'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Bug',
                      child: Row(
                        children: const [
                          Icon(Icons.bug_report),
                          SizedBox(width: 8),
                          Text('Bug'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Otro',
                      child: Row(
                        children: const [
                          Icon(Icons.more_horiz),
                          SizedBox(width: 8),
                          Text('Otro'),
                        ],
                      ),
                    ),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona una categoría';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedValue = value;
                    });
                  },
                ),

                // Blank space
                const SizedBox(height: 16),

                // Send button
                ElevatedButton(
                  onPressed: _isSending
                    ? null
                    : () async {
                    // Verificar si existe el usuario
                      if (user == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Debes iniciar sesión para enviar feedback')),
                        );
                        return;
                      }

                    // Verificar si todos los datos dentro de form están completos y son válidos
                    if (_formKey.currentState!.validate()) {
                      try {
                        // Desactivar el botón antes de enviar los datos
                        setState(() {
                          _isSending = true;
                        });

                        // Código de Firestore
                        await FirebaseFirestore.instance.collection('feedback').add({
                          'mensaje': _messageController.text.trim(),
                          'categoria': _selectedValue,
                          'fecha': Timestamp.now(),
                          'email': email,
                          'uid': user?.uid,
                        });

                        // Mostrar un mensaje rápido de qué el feedback se ha enviado
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('¡Feedback enviado!')),
                          );
                        }

                        // Limpiar campos
                        setState(() {
                          _messageController.clear();
                          _selectedValue = 'Sugerencia';
                        });

                        // Regresar a la pantalla de inicio
                        if (context.mounted) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => MainScreen()),
                            (Route<dynamic> route) => false,
                          );
                        }

                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al enviar el feedback: $e')),
                          );
                        }
                      } finally {
                        setState(() {
                          _isSending = false;
                        });
                      }
                    }
                  },
                  // Style the button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 2, 80, 145),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    )
                  ),
                  // Send button text
                  child: _isSending
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                    : const Text('Enviar', style: TextStyle(color: Colors.white)),
                )
              ],
            )
          ),
        ),
      ),
    );
  }
}