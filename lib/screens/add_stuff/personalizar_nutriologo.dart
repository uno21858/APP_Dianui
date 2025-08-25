import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

// Modelo de datos para el perfil del nutriólogo
class NutriologoPerfilModel {
  String nombre;
  String telefono;
  String direccion;
  String titulo;
  String semestre;
  String universidad;
  String especialidad;
  String experiencia;
  String horarioInicio;
  String horarioFin;
  String profileImage;

  NutriologoPerfilModel({
    this.nombre = '',
    this.telefono = '',
    this.direccion = '',
    this.titulo = '',
    this.semestre = '',
    this.universidad = '',
    this.especialidad = '',
    this.experiencia = '',
    this.horarioInicio = '08 AM',
    this.horarioFin = '05 PM',
    this.profileImage = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'direccion': direccion,
      'titulo': titulo,
      'semestre': semestre,
      'universidad': universidad,
      'especialidad': especialidad,
      'experiencia': experiencia,
      'horarioInicio': horarioInicio,
      'horarioFin': horarioFin,
      'profileImage': profileImage,
    };
  }

  factory NutriologoPerfilModel.fromMap(Map<String, dynamic> map) {
    return NutriologoPerfilModel(
      nombre: map['nombre'] ?? '',
      telefono: map['telefono'] ?? '',
      direccion: map['direccion'] ?? '',
      titulo: map['titulo'] ?? '',
      semestre: map['semestre'] ?? '',
      universidad: map['universidad'] ?? '',
      especialidad: map['especialidad'] ?? '',
      experiencia: map['experiencia'] ?? '',
      horarioInicio: map['horarioInicio'] ?? '08 AM',
      horarioFin: map['horarioFin'] ?? '05 PM',
      profileImage: map['profileImage'] ?? '',
    );
  }
}

// Provider para manejar el estado del perfil
class NutriologoPerfilProvider with ChangeNotifier {
  NutriologoPerfilModel _perfil = NutriologoPerfilModel();
  bool _isLoading = false;
  bool _isEditing = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  NutriologoPerfilModel get perfil => _perfil;
  bool get isLoading => _isLoading;
  bool get isEditing => _isEditing;

  void setEditing(bool value) {
    _isEditing = value;
    notifyListeners();
  }

  Future<void> loadProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      var doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('informacion_nutriologo')
          .doc('perfil')
          .get();

      if (doc.exists) {
        _perfil = NutriologoPerfilModel.fromMap(doc.data() ?? {});
      }
    } catch (e) {
      print('Error al cargar datos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfileData() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('informacion_nutriologo')
          .doc('perfil')
          .set(_perfil.toMap());

      _isEditing = false;
    } catch (e) {
      print('Error al guardar datos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateField(String field, String value) {
    switch (field) {
      case 'nombre':
        _perfil.nombre = value;
        break;
      case 'telefono':
        _perfil.telefono = value;
        break;
      case 'direccion':
        _perfil.direccion = value;
        break;
      case 'titulo':
        _perfil.titulo = value;
        break;
      case 'semestre':
        _perfil.semestre = value;
        break;
      case 'universidad':
        _perfil.universidad = value;
        break;
      case 'especialidad':
        _perfil.especialidad = value;
        break;
      case 'experiencia':
        _perfil.experiencia = value;
        break;
      case 'horarioInicio':
        _perfil.horarioInicio = value;
        break;
      case 'horarioFin':
        _perfil.horarioFin = value;
        break;
      case 'profileImage':
        _perfil.profileImage = value;
        break;
    }
    notifyListeners();
  }

  Future<void> uploadProfileImage() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      _isLoading = true;
      notifyListeners();

      final ImagePicker _picker = ImagePicker();
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        File file = File(image.path);
        final storageRef = _storage.ref().child('profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}');
        UploadTask uploadTask = storageRef.putFile(file);

        await uploadTask.whenComplete(() async {
          String downloadUrl = await storageRef.getDownloadURL();
          _perfil.profileImage = downloadUrl;
          notifyListeners();
        });
      }
    } catch (e) {
      print('Error al subir imagen: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class NutriologoPerfilScreen extends StatelessWidget {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NutriologoPerfilProvider()..loadProfileData(),
      child: Consumer<NutriologoPerfilProvider>(
        builder: (context, provider, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Perfil Profesional'),
              backgroundColor: Colors.blue.shade800,
              foregroundColor: Colors.white,
              elevation: 3,
              actions: [
                IconButton(
                  icon: Icon(provider.isEditing ? Icons.check : Icons.edit),
                  onPressed: () {
                    if (provider.isEditing) {
                      if (_formKey.currentState!.validate()) {
                        provider.saveProfileData();
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Perfil actualizado correctamente'))
                        );
                      }
                    } else {
                      provider.setEditing(true);
                    }
                  },
                )
              ],
            ),
            body: provider.isLoading
                ? Center(child: CircularProgressIndicator())
                : _buildProfileForm(context, provider),
          );
        },
      ),
    );
  }

  Widget _buildProfileForm(BuildContext context, NutriologoPerfilProvider provider) {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            _buildProfileHeader(context, provider),
            SizedBox(height: 16),
            _buildPersonalInfoSection(context, provider),
            SizedBox(height: 24),
            _buildProfessionalSection(context, provider),
            SizedBox(height: 32),
            if (provider.isEditing)
              _buildSaveButton(context, provider),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, NutriologoPerfilProvider provider) {
    return Column(
      children: [
        GestureDetector(
          onTap: provider.isEditing ? () => provider.uploadProfileImage() : null,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade700, width: 3),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26, offset: Offset(0, 5))],
                ),
                child: ClipOval(
                  child: provider.perfil.profileImage.isNotEmpty
                      ? Image.network(
                    provider.perfil.profileImage,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                            : null,
                      ));
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(Icons.person, size: 70, color: Colors.grey),
                  )
                      : Icon(Icons.person, size: 70, color: Colors.grey),
                ),
              ),
              if (provider.isEditing)
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Text(
          provider.perfil.nombre.isEmpty
              ? 'Completa tu perfil profesional'
              : provider.perfil.nombre,
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.shade700,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            provider.perfil.especialidad.isEmpty
                ? 'Nutriólogo'
                : provider.perfil.especialidad,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildPersonalInfoSection(BuildContext context, NutriologoPerfilProvider provider) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_pin, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text('Información Personal',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800
                    )
                ),
              ],
            ),
            Divider(thickness: 1, color: Colors.blue.shade100),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Nombre Completo',
              icon: Icons.person,
              initialValue: provider.perfil.nombre,
              enabled: provider.isEditing,
              validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              onChanged: (value) => provider.updateField('nombre', value),
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              initialValue: provider.perfil.telefono,
              enabled: provider.isEditing,
              validator: (value) => value!.isEmpty ? 'Este campo es obligatorio' : null,
              onChanged: (value) => provider.updateField('telefono', value),
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Dirección Profesional',
              icon: Icons.location_on,
              initialValue: provider.perfil.direccion,
              enabled: provider.isEditing,
              onChanged: (value) => provider.updateField('direccion', value),
            ),
            SizedBox(height: 16),
            Text('Horario de atención',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700
                )
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Desde',
                    options: _getTimeOptions(),
                    value: provider.perfil.horarioInicio,
                    enabled: provider.isEditing,
                    onChanged: (value) => provider.updateField('horarioInicio', value!),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildDropdown(
                    label: 'Hasta',
                    options: _getTimeOptions(),
                    value: provider.perfil.horarioFin,
                    enabled: provider.isEditing,
                    onChanged: (value) => provider.updateField('horarioFin', value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalSection(BuildContext context, NutriologoPerfilProvider provider) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.blue.shade700),
                SizedBox(width: 8),
                Text('Formación Profesional',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800
                    )
                ),
              ],
            ),
            Divider(thickness: 1, color: Colors.blue.shade100),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Título Profesional',
              icon: Icons.workspace_premium,
              initialValue: provider.perfil.titulo,
              enabled: provider.isEditing,
              onChanged: (value) => provider.updateField('titulo', value),
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Universidad/Institución',
              icon: Icons.business,
              initialValue: provider.perfil.universidad,
              enabled: provider.isEditing,
              onChanged: (value) => provider.updateField('universidad', value),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Semestre (si aplica)',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                    initialValue: provider.perfil.semestre,
                    enabled: provider.isEditing,
                    onChanged: (value) => provider.updateField('semestre', value),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Especialidad',
                    icon: Icons.medical_services,
                    initialValue: provider.perfil.especialidad,
                    enabled: provider.isEditing,
                    onChanged: (value) => provider.updateField('especialidad', value),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildTextField(
              label: 'Experiencia profesional',
              icon: Icons.work,
              initialValue: provider.perfil.experiencia,
              enabled: provider.isEditing,
              maxLines: 5,
              onChanged: (value) => provider.updateField('experiencia', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, NutriologoPerfilProvider provider) {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          provider.saveProfileData();
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Perfil actualizado correctamente'))
          );
        }
      },
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.blue.shade800,
        elevation: 3,
      ),
      child: Text(
        'GUARDAR CAMBIOS',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required String initialValue,
    required bool enabled,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> options,
    required String value,
    required bool enabled,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: options.map((option) =>
          DropdownMenuItem(value: option, child: Text(option))
      ).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }

  List<String> _getTimeOptions() {
    List<String> times = [];
    for (int i = 1; i <= 12; i++) {
      times.add('${i.toString().padLeft(2, '0')} AM');
      times.add('${i.toString().padLeft(2, '0')} PM');
    }
    return times;
  }
}