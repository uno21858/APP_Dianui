import 'package:flutter/material.dart';
import '../../widgets/quick_access_button.dart';
import '../../widgets/fab_nutriologo.dart';
import '../categories/consulta_page.dart';
import '../categories/seguimiento_page.dart';
import '../categories/cocinar_page.dart';
import '../categories/consejos_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '/../screens/settings/settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String? imageUrl; // URL de la imagen del usuario

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_LA', null);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (userDoc.exists && userDoc['profileImage'] != null) {
      if (mounted) {
        setState(() {
          imageUrl = userDoc['profileImage'];
        });
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);

    // Read the image as bytes
    Uint8List imageBytes = await imageFile.readAsBytes();

    // Compress the image
    img.Image? image = img.decodeImage(imageBytes);
    if (image != null) {
      img.Image resizedImage = img.copyResize(image, width: 600); // Resize
      Uint8List compressedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85)); // Compress

      // Save compressed image to a new temporary file
      File compressedFile = File('${imageFile.path}_compressed.jpg');
      await compressedFile.writeAsBytes(compressedBytes);

      String filePath = 'profile_images/${user!.uid}.jpg';

      try {
        TaskSnapshot snapshot =
        await FirebaseStorage.instance.ref(filePath).putFile(compressedFile);
        String downloadUrl = await snapshot.ref.getDownloadURL();

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({'profileImage': downloadUrl});

        if (mounted) {
          setState(() {
            imageUrl = downloadUrl;
          });
        }
      } catch (e) {
        print("Error uploading image: $e");
      }
    }
  }

  Future<String?> _getUserName() async {
    if (user == null) return null;

    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    return userDoc.exists ? userDoc['name'] as String? : null;
  }

  String _getSaludo() {
    final horaActual = DateTime.now().hour;

    if (horaActual >= 6 && horaActual < 12) {
      return 'Buenos días';
    } else if (horaActual >= 12 && horaActual < 19) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/design/BannerSuperior7.png', // 🔁 Ruta de tu imagen
            fit: BoxFit.cover,
          ),
          // AppBar transparente sobre la imagen
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 90,
            title: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(width: 5),
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                        ? NetworkImage(imageUrl!) as ImageProvider
                        : null,
                    child: imageUrl == null || imageUrl!.isEmpty
                        ? const Icon(Icons.person, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_getSaludo()},',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    FutureBuilder<String?>(
                      future: _getUserName(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Text('Cargando...',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black));
                        } else if (snapshot.hasError || !snapshot.hasData) {
                          return const Text('Usuario desconocido',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black));
                        } else {
                          return Text(snapshot.data!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black));
                        }
                      },
                    ),
                  
                  ],
                ),
              ],
            ),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.black, size: 32),
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
        ],
      ),
    ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Categorías',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickAccessButton(
                    icon: Icons.search,
                    label: 'Consulta',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConsultaPage()),
                      );
                    },
                  ),
                  QuickAccessButton(
                    icon: Icons.bar_chart,
                    label: 'Seguimiento',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SeguimientoPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  QuickAccessButton(
                    icon: Icons.restaurant,
                    label: 'Cocinar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CocinarPage()),
                      );
                    },
                  ),
                  QuickAccessButton(
                    icon: Icons.lightbulb,
                    label: 'Consejos',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ConsejosPage()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Text(
                'Contenido Destacado',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: const Icon(Icons.article, color: Colors.blue),
                  title: const Text('Tips para un sueño saludable'),
                  subtitle: const Text('Por Dra. Josefina A. Pérez'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {},
                ),
              ),
              Card(
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: const Icon(Icons.restaurant_menu, color: Colors.green),
                  title: const Text('Hot Cakes de Avena'),
                  subtitle: const Text('Desayuno saludable y fácil de preparar'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: const NutriologoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}