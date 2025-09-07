import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  File? _imageFile;
  String? _currentProfileImage;
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  final List<String> _cities = [
    'Ciudad de México',
    'Guadalajara',
    'Monterrey',
    'Puebla',
    'Tijuana',
    'León',
    'Querétaro',
    'Mérida',
    'Cancún',
    'Otras',
  ];

  String? _selectedCity;
  String? _selectedOccupation;

  final List<String> _occupations = [
    'Estudiante',
    'Profesional',
    'Deportista',
    'Nutriólogo',
    'Entrenador',
    'Otro'
  ];

  // 🔹 NUEVA FUNCIONALIDAD: Riesgos familiares
  List<String> _selectedFamilyRisks = [];
  final List<String> _familyRisks = [
    'Diabetes',
    'Hipertensión',
    'Obesidad',
    'Enfermedad cardíaca',
    'Colesterol alto',
    'Cáncer',
    'Osteoporosis',
    'Enfermedad renal',
    'Accidente cerebrovascular',
    'Enfermedad hepática',
    'Depresión',
    'Alzheimer',
    'Artritis',
    'Ninguno',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        // Intentar buscar en la colección 'usuarios' si no existe en 'users'
        userDoc = await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(user.uid)
            .get();
      }

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;

        // Carga los riesgos familiares desde la subcolección de Firestore
        final QuerySnapshot riesgosSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('riesgos_familiares')
            .orderBy('orden')
            .get();

        final List<String> riesgosFromFirestore = riesgosSnapshot.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['riesgo'] as String)
            .toList();

        setState(() {
          _nameController.text = userData['name'] ?? '';
          _ageController.text = userData['age']?.toString() ?? '';
          _phoneController.text = userData['phone'] ?? '';
          _selectedCity = userData['city'];
          _selectedOccupation = userData['occupation'];
          _currentProfileImage = userData['profileImage'];
          // Cargar riesgos familiares desde subcolección
          _selectedFamilyRisks = riesgosFromFirestore;
        });
      }
    } catch (e) {
      print("Error al cargar datos del usuario: $e");
      _showNotification("No se pudieron cargar los datos", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 800,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 800,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imageFile = File(pickedFile.path);
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      _showNotification('Por favor ingresa tu nombre', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showNotification('No hay usuario autenticado.', isError: true);
        return;
      }

      // Mapa para almacenar actualizaciones
      final Map<String, dynamic> updates = {
        'name': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity ?? 'N/A',
        'occupation': _selectedOccupation,
        'updatedAt': FieldValue.serverTimestamp(),
        // Actualizar riesgos familiares
        'familyRisks': _selectedFamilyRisks,
      };

      // Subir imagen si se seleccionó una nueva
      if (_imageFile != null) {
        final String fileName = 'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = ref.putFile(_imageFile!);
        final TaskSnapshot snapshot = await uploadTask;
        final String imageUrl = await snapshot.ref.getDownloadURL();
        updates['profileImage'] = imageUrl;
      }

      // Actualizar en Firestore (intentar en ambas colecciones)
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update(updates);
      } catch (e) {
        // Si falla, intentar con la otra colección
        await FirebaseFirestore.instance.collection('usuarios').doc(user.uid).update(updates);
      }

      _showNotification('¡Perfil actualizado correctamente!');
      Navigator.pop(context);
    } catch (e) {
      _showNotification('Error al guardar el perfil: $e', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showNotification(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void _showPickerModal(BuildContext context, List<String> options, String title, Function(String) onSelected, String? currentValue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final bool isSelected = options[index] == currentValue;
                    return ListTile(
                      title: Text(options[index]),
                      trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                      onTap: () {
                        onSelected(options[index]);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 🔹 NUEVO MÉTODO: Modal para selección múltiple de riesgos familiares
  void _showMultiSelectModal(
    BuildContext context,
    List<String> options,
    String title,
    Function(List<String>) onSelected,
    List<String> currentValues,
  ) {
    List<String> tempSelected = List.from(currentValues);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${tempSelected.length} seleccionados',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempSelected.clear();
                                });
                              },
                              child: const Text('Limpiar'),
                            ),
                            TextButton(
                              onPressed: () {
                                onSelected(tempSelected);
                                Navigator.pop(context);
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final bool isSelected = tempSelected.contains(option);

                        // Manejar "Ninguno" como opción exclusiva
                        final bool isNone = option == 'Ninguno';
                        final bool hasNone = tempSelected.contains('Ninguno');

                        return ListTile(
                          title: Text(option),
                          leading: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              setModalState(() {
                                if (isNone) {
                                  // Si selecciona "Ninguno", limpia otras selecciones
                                  if (value == true) {
                                    tempSelected.clear();
                                    tempSelected.add(option);
                                  } else {
                                    tempSelected.remove(option);
                                  }
                                } else {
                                  // Si selecciona otro riesgo, quita "Ninguno"
                                  if (value == true) {
                                    tempSelected.remove('Ninguno');
                                    tempSelected.add(option);
                                  } else {
                                    tempSelected.remove(option);
                                  }
                                }
                              });
                            },
                            activeColor: Theme.of(context).primaryColor,
                          ),
                          onTap: () {
                            setModalState(() {
                              if (isNone) {
                                if (isSelected) {
                                  tempSelected.remove(option);
                                } else {
                                  tempSelected.clear();
                                  tempSelected.add(option);
                                }
                              } else {
                                if (isSelected) {
                                  tempSelected.remove(option);
                                } else {
                                  tempSelected.remove('Ninguno');
                                  tempSelected.add(option);
                                }
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryColor.withOpacity(0.05),
              backgroundColor,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar (Imagen de perfil)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [primaryColor, primaryColor.withOpacity(0.7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3.0),
                        child: ClipOval(
                          child: _imageFile != null
                              ? Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                            width: 114,
                            height: 114,
                          )
                              : _currentProfileImage != null && _currentProfileImage!.isNotEmpty
                              ? Image.network(
                            _currentProfileImage!,
                            fit: BoxFit.cover,
                            width: 114,
                            height: 114,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.person,
                                  size: 70,
                                  color: Colors.grey,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        (loadingProgress.expectedTotalBytes ?? 1)
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                              : Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.person,
                              size: 70,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              primaryColor,
                              primaryColor.withOpacity(0.8),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadowColor: Colors.black38,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información personal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAnimatedTextField(
                          _nameController,
                          "Nombre completo",
                          Icons.person,
                        ),
                        const SizedBox(height: 16),
                        _buildAnimatedTextField(
                          _ageController,
                          "Edad",
                          Icons.cake,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _buildAnimatedTextField(
                          _phoneController,
                          "Teléfono",
                          Icons.phone,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shadowColor: Colors.black38,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Información adicional',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Ciudad
                        _buildSelectionField(
                          title: "Ciudad",
                          value: _selectedCity ?? "Selecciona tu ciudad",
                          icon: Icons.location_city,
                          onTap: () => _showPickerModal(
                            context,
                            _cities,
                            'Selecciona tu ciudad',
                                (value) => setState(() => _selectedCity = value),
                            _selectedCity,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Ocupación
                        _buildSelectionField(
                          title: "Ocupación",
                          value: _selectedOccupation ?? "Selecciona tu ocupación",
                          icon: Icons.work,
                          onTap: () => _showPickerModal(
                            context,
                            _occupations,
                            'Selecciona tu ocupación',
                                (value) => setState(() => _selectedOccupation = value),
                            _selectedOccupation,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Riesgos familiares (nueva sección)
                        _buildMultiSelectField(
                          title: "Riesgos familiares",
                          values: _selectedFamilyRisks,
                          icon: Icons.family_restroom,
                          onTap: () => _showMultiSelectModal(
                            context,
                            _familyRisks,
                            'Selecciona los riesgos familiares',
                                (values) => setState(() => _selectedFamilyRisks = values),
                            _selectedFamilyRisks,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Botón de guardar
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                      shadowColor: primaryColor.withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.0,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save),
                        SizedBox(width: 10),
                        Text(
                          'GUARDAR CAMBIOS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType? keyboardType,
      }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Theme.of(context).primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        keyboardType: keyboardType,
      ),
    );
  }

  Widget _buildSelectionField({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isSelected = title == "Ciudad"
        ? _selectedCity != null
        : _selectedOccupation != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectField({
    required String title,
    required List<String> values,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final bool isSelected = values.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: values.map((value) {
                      return Chip(
                        label: Text(
                          value,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }
}

