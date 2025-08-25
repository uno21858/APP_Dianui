import 'package:flutter/material.dart';
import '/../widgets/fab_nutriologo.dart';
import '/../models/nutritionist.dart';
import '/../widgets/custom_app_bar.dart';
import '/../screens/details/nutritionist_detail_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NutritionistsPage extends StatefulWidget {
  const NutritionistsPage({super.key});

  @override
  State<NutritionistsPage> createState() => _NutritionistsPageState();
}

class _NutritionistsPageState extends State<NutritionistsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Nutritionist> nutritionists = [];
  List<Nutritionist> filteredNutritionists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNutritionists();
    _searchController.addListener(_filterNutritionists);
  }

  Future<void> _fetchNutritionists() async {
    try {
      // Consultar la colección de usuarios
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('nutritionist', isEqualTo: true)
          .get();

      // Combinar resultados de ambas colecciones
      List<Nutritionist> allNutritionists = [];

      for (var doc in usersSnapshot.docs) {
        final userId = doc.id;
        final userData = doc.data();

        // Obtener información del nutriólogo
        final perfilSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('informacion_nutriologo')
          .doc('perfil')
          .get();
        
        final perfilData = perfilSnapshot.data();

        allNutritionists.add(Nutritionist.fromMap({
          'uid': userId,
          'name': perfilData?['nombre'] ?? userData['name'] ?? 'No disponible',
          // Podriamos agregarlo después: 'rating': userData['rating'] ?? 5.0,
          'isAvailable': userData['isAvailable'] ?? true,
          'schedule': (perfilData?['horarioInicio'] != null &&
                      perfilData?['horarioFin'] != null)
              ? '${perfilData?['horarioInicio']} - ${perfilData?['horarioFin']}'
              : userData['schedule'] ?? 'Horario no disponible',
          'profileImage': userData['profileImage'] ?? '',
          'specialty': perfilData?['especialidad'] ?? userData['specialty'] ?? 'Nutrición general',
          'occupation': perfilData?['titulo'] ?? userData['occupation'] ?? 'Nutriólogo',
        }));
      }

      setState(() {
        nutritionists = allNutritionists;
        filteredNutritionists = allNutritionists;
        _isLoading = false;
      });

    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterNutritionists() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredNutritionists = nutritionists.where((nutritionist) {
        return nutritionist.name.toLowerCase().contains(query) ||
            (nutritionist.specialty?.toLowerCase().contains(query) ?? false) ||
            (nutritionist.occupation?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Nutriólogos'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, especialidad o ocupación...',
                prefixIcon: const Icon(Icons.search, color: Colors.blue),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            )
                : filteredNutritionists.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    _searchController.text.isEmpty
                        ? 'No hay nutriólogos disponibles'
                        : 'No se encontraron resultados',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: filteredNutritionists.length,
              itemBuilder: (context, index) {
                final nutritionist = filteredNutritionists[index];
                return _buildNutritionistCard(nutritionist);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: const NutriologoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildNutritionistCard(Nutritionist nutritionist) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NutritionistDetailPage(
                nutritionist: nutritionist,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Foto de perfil con manejo de errores
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: nutritionist.profileImage.isNotEmpty
                    ? Image.network(
                  nutritionist.profileImage,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Si la imagen falla, mostrar un placeholder
                    return Container(
                      width: 60,
                      height: 60,
                      color: nutritionist.isAvailable
                          ? Colors.green[100]
                          : Colors.red[100],
                      child: Icon(
                        Icons.person,
                        size: 30,
                        color: nutritionist.isAvailable
                            ? Colors.green
                            : Colors.red,
                      ),
                    );
                  },
                )
                    : Container(
                  width: 60,
                  height: 60,
                  color: nutritionist.isAvailable
                      ? Colors.green[100]
                      : Colors.red[100],
                  child: Icon(
                    Icons.person,
                    size: 30,
                    color: nutritionist.isAvailable
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Información del nutriólogo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nutritionist.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 18, color: Colors.blue[600]),
                        Text(' ${nutritionist.schedule}'),
                      ],
                    ),
                    if (nutritionist.specialty != null &&
                        nutritionist.specialty!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Especialidad: ${nutritionist.specialty!}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    if (nutritionist.occupation != null &&
                        nutritionist.occupation!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Ocupación: ${nutritionist.occupation!}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Indicador de disponibilidad
              Icon(
                nutritionist.isAvailable ? Icons.check_circle : Icons.cancel,
                color: nutritionist.isAvailable ? Colors.green : Colors.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}