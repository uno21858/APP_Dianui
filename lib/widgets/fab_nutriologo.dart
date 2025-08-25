import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dianui/screens/add_stuff/add_recipe.dart';
import 'package:dianui/screens/add_stuff/add_blog.dart';
import 'package:dianui/screens/Nutriologo/pacientes.dart';
import 'package:dianui/screens/add_stuff/crear_consejo.dart';
import '../screens/add_stuff/personalizar_nutriologo.dart';

class NutriologoFAB extends StatefulWidget {
  const NutriologoFAB({super.key});

  @override
  State<NutriologoFAB> createState() => _NutriologoFABState();
}

class _NutriologoFABState extends State<NutriologoFAB> {
  User? user;
  bool isNutriologo = false;

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? updatedUser) {
      if (mounted) {
        setState(() {
          user = updatedUser;
        });
        if (user != null) {
          _checkUserRole();
        }
      }
    });
  }

  Future<void> _checkUserRole() async {
    if (user == null) return;
    try {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (userDoc.exists) {
        final dynamic roleData = userDoc['nutritionist'];
        setState(() {
          isNutriologo =
          roleData is bool ? roleData : roleData.toString().toLowerCase() == 'true';
        });
      }
    } catch (e) {
      print("Error obteniendo el rol: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isNutriologo) return const SizedBox.shrink();

    return FloatingActionButton(
      onPressed: () => _showNutriologoMenu(context),
      backgroundColor: Colors.blueAccent,
      elevation: 8, // Sombra más pronunciada
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Bordes redondeados
      ),
      child: const Icon(Icons.add, color: Colors.white, size: 32),
    );
  }

  void _showNutriologoMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Efecto de desenfoque
        child: Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground.resolveFrom(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              _menuItem(CupertinoIcons.book, "Agregar Receta", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const AddRecipeScreen()),
                );
              }),
              const Divider(),
              _menuItem(CupertinoIcons.doc_person, "Pacientes", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) =>  PacientesScreen()),
                );
              }),
              const Divider(),
              _menuItem(CupertinoIcons.lightbulb_fill, "Crear Consejo", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const SubirConsejoPage()),
                );
                // Implementar navegación a la agenda
              }),
              const Divider(),
              _menuItem(CupertinoIcons.at_circle, "Añadir a Blog", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => const AddBlogPage()),
                );

              }),
              const Divider(),
              _menuItem(CupertinoIcons.person_badge_plus, "Perfil de nutriologo", () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) =>  NutriologoPerfilScreen()),
                );

              }),
              const Divider(),
              _menuItem(CupertinoIcons.xmark, "Cerrar", () => Navigator.pop(context)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: CupertinoColors.activeBlue),
      title: Text(text, style: const TextStyle(fontSize: 18)),
      onTap: onTap,
    );
  }
}