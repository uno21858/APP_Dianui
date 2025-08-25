import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:email_validator/email_validator.dart';

class ModernRegisterScreen extends StatefulWidget {
  const ModernRegisterScreen({super.key});

  @override
  State<ModernRegisterScreen> createState() => _ModernRegisterScreenState();
}

class _ModernRegisterScreenState extends State<ModernRegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controladores
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  // Variables de estado
  File? _imageFile;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedCity;
  String? _selectedOccupation;

  // Opciones
  final List<String> _cities = [
    'Ciudad de México', 'Guadalajara', 'Monterrey', 'Puebla',
    'Tijuana', 'León', 'Querétaro', 'Mérida', 'Cancún'
  ];

  final List<String> _occupations = [
    'Estudiante', 'Profesionista', 'Emprendedor',
    'Freelancer', 'Jubilado', 'Otro'
  ];

  // Estilos
  final Color _primaryColor = const Color(0xFF6C63FF);
  final Color _secondaryColor = const Color(0xFF4A44B7);
  final Color _accentColor = const Color(0xFFFF6584);
  final Color _backgroundColor = const Color(0xFFF8F9FA);
  final Color _textColor = const Color(0xFF2D3748);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) return null;

    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final fileName = 'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(_imageFile!);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      setState(() => _errorMessage = 'Error al subir imagen: ${e.toString()}');
      return null;
    }
  }

  bool _validateStep1() {
    if (_nameController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor ingresa tu nombre completo');
      return false;
    }
    if (!EmailValidator.validate(_emailController.text)) {
      setState(() => _errorMessage = 'Por favor ingresa un correo válido');
      return false;
    }
    return true;
  }

  bool _validateStep2() {
    if (_selectedCity == null) {
      setState(() => _errorMessage = 'Por favor selecciona tu ciudad');
      return false;
    }
    if (_selectedOccupation == null) {
      setState(() => _errorMessage = 'Por favor selecciona tu ocupación');
      return false;
    }
    return true;
  }

  bool _validateStep3() {
    if (_passwordController.text.length < 8) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 8 caracteres');
      return false;
    }
    if (!RegExp(r'[A-Z]').hasMatch(_passwordController.text)) {
      setState(() => _errorMessage = 'La contraseña debe contener al menos una mayúscula');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden');
      return false;
    }
    return true;
  }

  Future<void> _registerUser() async {
    if (!_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Crear usuario en Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Subir imagen si existe
      final imageUrl = await _uploadImage();

      // 3. Guardar datos en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'uid': userCredential.user!.uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _selectedCity,
        'occupation': _selectedOccupation,
        'age': _ageController.text.trim(),
        if (imageUrl != null) 'profileImage': imageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 4. Enviar email de verificación
      await userCredential.user!.sendEmailVerification();

      // 5. Mostrar éxito
      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getFirebaseErrorMessage(e));
    } catch (e) {
      setState(() => _errorMessage = 'Error desconocido: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getFirebaseErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'El correo ya está registrado';
      case 'invalid-email':
        return 'Correo electrónico no válido';
      case 'operation-not-allowed':
        return 'Operación no permitida';
      case 'weak-password':
        return 'Contraseña demasiado débil';
      default:
        return 'Error de autenticación: ${e.message}';
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: return _validateStep1();
      case 1: return _validateStep2();
      case 2: return _validateStep3();
      default: return false;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Registro Exitoso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: _primaryColor, size: 60),
            const SizedBox(height: 20),
            const Text('Hemos enviado un enlace de verificación a tu correo. Por favor verifica tu email.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              Navigator.pop(context); // Regresar a pantalla anterior
            },
            child: Text('Aceptar', style: TextStyle(color: _primaryColor)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 32),

              // Indicador de pasos
              _buildStepIndicator(),
              const SizedBox(height: 32),

              // Mensaje de error
              if (_errorMessage != null) _buildErrorCard(),

              // Contenido del paso actual
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStepContent(),
              ),

              // Botones de navegación
              const SizedBox(height: 32),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: _textColor),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(height: 16),
        Text(
          'Crea tu cuenta',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        Text(
          'Completa los siguientes pasos para registrarte',
          style: TextStyle(
            fontSize: 16,
            color: _textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: List.generate(3, (index) {
        final isActive = _currentStep == index;
        final isCompleted = _currentStep > index;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive || isCompleted ? _primaryColor : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, size: 18, color: Colors.white)
                      : Text(
                    (index + 1).toString(),
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['Información', 'Ubicación', 'Seguridad'][index],
                style: TextStyle(
                  color: isActive ? _primaryColor : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0: return _buildStep1();
      case 1: return _buildStep2();
      case 2: return _buildStep3();
      default: return Container();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        // Selector de imagen
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  image: _imageFile != null
                      ? DecorationImage(
                    image: FileImage(_imageFile!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _imageFile == null
                    ? Icon(
                  Icons.camera_alt,
                  size: 40,
                  color: _textColor.withOpacity(0.5),
                )
                    : null,
              ),
              if (_imageFile != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.edit, size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Campos de texto
        _buildModernTextField(
          controller: _nameController,
          label: 'Nombre completo',
          icon: Icons.person_outline,
          isRequired: true,
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _emailController,
          label: 'Correo electrónico',
          icon: Icons.email_outlined,
          isRequired: true,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => EmailValidator.validate(value!) ? null : 'Correo no válido',
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _phoneController,
          label: 'Teléfono (opcional)',
          icon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        // Selector de ciudad moderno
        _buildModernDropdown(
          value: _selectedCity,
          items: _cities,
          label: 'Ciudad',
          icon: Icons.location_on_outlined,
          onChanged: (value) => setState(() => _selectedCity = value),
        ),
        const SizedBox(height: 20),

        // Selector de ocupación moderno
        _buildModernDropdown(
          value: _selectedOccupation,
          items: _occupations,
          label: 'Ocupación',
          icon: Icons.work_outline,
          onChanged: (value) => setState(() => _selectedOccupation = value),
        ),
        const SizedBox(height: 20),

        // Selector de edad moderno
        _buildAgeSelector(),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        _buildModernTextField(
          controller: _passwordController,
          label: 'Contraseña',
          icon: Icons.lock_outline,
          isRequired: true,
          obscureText: true,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 20),
        _buildModernTextField(
          controller: _confirmPasswordController,
          label: 'Confirmar contraseña',
          icon: Icons.lock_outline,
          isRequired: true,
          obscureText: true,
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 24),
        _buildPasswordRequirements(),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        onChanged: onChanged,
        validator: validator,
        decoration: InputDecoration(
          labelText: isRequired ? '$label*' : label,
          labelStyle: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          prefixIcon: Icon(
            icon,
            color: _primaryColor,
            size: 22,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        style: TextStyle(
          fontSize: 16,
          color: _textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: DropdownButtonFormField<String>(
          value: value,
          icon: Icon(Icons.arrow_drop_down, color: _primaryColor),
          iconSize: 28,
          elevation: 2,
          style: TextStyle(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              color: _textColor.withOpacity(0.7),
              fontSize: 14,
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              icon,
              color: _primaryColor,
              size: 22,
            ),
          ),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(12),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: _textColor.withOpacity(0.9),
                  ),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          selectedItemBuilder: (BuildContext context) {
            return items.map<Widget>((String item) {
              return Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  value ?? 'Seleccionar',
                  style: TextStyle(
                    color: value != null ? _textColor : Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildAgeSelector() {
    return GestureDetector(
      onTap: () => _showAgePicker(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.cake_outlined,
                color: _primaryColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edad',
                      style: TextStyle(
                        fontSize: 12,
                        color: _textColor.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _ageController.text.isNotEmpty ? _ageController.text : 'Seleccionar edad',
                      style: TextStyle(
                        fontSize: 16,
                        color: _ageController.text.isNotEmpty ? _textColor : Colors.grey[600],
                        fontWeight: FontWeight.w500,
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
      ),
    );
  }

  void _showAgePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selecciona tu edad',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.check, color: _primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: _ageController.text.isNotEmpty
                      ? int.parse(_ageController.text)
                      : 18,
                ),
                onSelectedItemChanged: (int index) {
                  setState(() {
                    _ageController.text = index.toString();
                  });
                },
                children: List<Widget>.generate(
                  100,
                      (index) => Center(
                    child: Text(
                      index.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        color: _primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRequirements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Requisitos de contraseña:',
          style: TextStyle(
            color: _textColor.withOpacity(0.7),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildRequirementItem(
          'Mínimo 8 caracteres',
          _passwordController.text.length >= 8,
        ),
        _buildRequirementItem(
          'Al menos una mayúscula',
          RegExp(r'[A-Z]').hasMatch(_passwordController.text),
        ),
        _buildRequirementItem(
          'Las contraseñas coinciden',
          _passwordController.text.isNotEmpty &&
              _passwordController.text == _confirmPasswordController.text,
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: isMet ? Colors.green : Colors.transparent,
              border: Border.all(
                color: isMet ? Colors.green : Colors.grey,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.check,
                size: 14,
                color: isMet ? Colors.white : Colors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: isMet ? Colors.green : Colors.grey,
              fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: _primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _currentStep--;
                  _errorMessage = null;
                });
              },
              child: Text(
                'Regresar',
                style: TextStyle(color: _primaryColor),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              if (_currentStep < 2) {
                if (_validateCurrentStep()) {
                  setState(() {
                    _currentStep++;
                    _errorMessage = null;
                  });
                }
              } else {
                _registerUser();
              }
            },
            child: _isLoading
                ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : Text(
              _currentStep < 2 ? 'Continuar' : 'Registrarse',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}