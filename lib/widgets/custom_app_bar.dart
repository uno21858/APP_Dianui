import 'package:flutter/material.dart';
import '/screens/settings/settings_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(50);
}

class _CustomAppBarState extends State<CustomAppBar> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data() as Map<String, dynamic>;
        if (data.containsKey('photoUrl')) {
          if (mounted) {
            setState(() {
              imageUrl = data['photoUrl'];
            });
          }
        }
      }
    } catch (e) {
      print("❌ Error cargando la foto de usuario: $e");
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    Uint8List imageBytes = await imageFile.readAsBytes();

    img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      img.Image resizedImage = img.copyResize(image, width: 600);
      Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));

      File compressedFile = File('${imageFile.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      String filePath = 'user_photos/${user!.uid}.jpg';

      try {
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(filePath).putFile(compressedFile);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({'photoUrl': downloadUrl});

        if (mounted) {
          setState(() {
            imageUrl = downloadUrl;
          });
        }
      } catch (e) {
        print("❌ Error al subir la imagen: $e");
      }
    }
  }

 @override
Widget build(BuildContext context) {
  return PreferredSize(
    preferredSize: const Size.fromHeight(50),
    child: Stack(
      fit: StackFit.expand,
      children: [
        // Fondo con imagen + transparencia
        Opacity(
          opacity: 1, // 🔹 Ajusta el valor entre 0 (totalmente transparente) y 1 (opaco)
          child: Image.asset(
            'assets/design/BannerSuperior7.png',
            fit: BoxFit.cover,
          ),
        ),
       AppBar(
        backgroundColor: const Color.fromARGB(0, 255, 255, 255), // Hacer transparente para que se vea la imagen
        elevation: 0,
        toolbarHeight: 50,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              _getIconForTitle(widget.title),
              size: 50,
              color: const Color.fromARGB(255, 0, 0, 0),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.title,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 0, 0, 0)),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color.fromARGB(255, 0, 0, 0), size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      ]
    ),
    
  );
}



  /// **🔹 Función para obtener un icono dinámico según el título**
  IconData _getIconForTitle(String title) {
    switch (title) {
      case "Nutriólogos":
        return Icons.local_dining;
      case "Recetas":
        return Icons.food_bank;
      case "Blogs":
        return Icons.article;
      case "Consejos":
        return Icons.lightbulb;
      case "Perfil":
        return Icons.account_circle;
      case "Crear Consejo":
        return Icons.lightbulb;
      default:
        return Icons.person;
    }
  }
}
