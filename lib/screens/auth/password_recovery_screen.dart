import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Importa Firebase Auth

class PasswordRecoveryScreen extends StatefulWidget {
  const PasswordRecoveryScreen({super.key});

  @override
  State<PasswordRecoveryScreen> createState() => _PasswordRecoveryScreenState();
}

class _PasswordRecoveryScreenState extends State<PasswordRecoveryScreen> {
  final TextEditingController _emailController = TextEditingController();
  String _message = '';
  bool _isLoading = false;
  bool _isEmailValid = true; // Para manejar la validación visual

  Future<void> _recoverPassword() async {
    final email = _emailController.text.trim();

    // Validar si el email está vacío o tiene un formato incorrecto
    if (email.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _message = 'Correo electrónico inválido.';
        _isEmailValid = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = '';
      _isEmailValid = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      setState(() {
        _message = 'Se han enviado las instrucciones a tu correo.';
      });
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al enviar el correo de recuperación.';
      if (e.code == 'user-not-found') {
        errorMessage = 'No existe una cuenta con este correo electrónico.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Correo electrónico inválido.';
        _isEmailValid = false;
      }

      setState(() {
        _message = errorMessage;
      });
    } catch (e) {
      setState(() {
        _message = 'Ocurrió un error inesperado. Intenta nuevamente.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color.fromARGB(255, 2, 80, 145);

    // Forzar el tema claro para la pantalla de recuperación de contraseña
    return Theme(
      data: ThemeData.light().copyWith(
        // Asegurar que los colores del tema claro se apliquen correctamente
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme,
        cardColor: Colors.white,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Recuperar contraseña',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: primaryColor,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_reset,
                        size: 80,
                        color: primaryColor,
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Recuperar Contraseña',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Ingresa tu correo electrónico para recibir las instrucciones de recuperación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _emailController,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: TextStyle(color: Colors.grey[800]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _isEmailValid ? Colors.grey : Colors.red,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _isEmailValid ? Colors.grey : Colors.red,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _isEmailValid ? primaryColor : Colors.red,
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.email,
                            color: _isEmailValid ? primaryColor : Colors.red,
                          ),
                          errorText: _isEmailValid ? null : 'Correo inválido',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) {
                          setState(() {
                            _isEmailValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _recoverPassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                            'Recuperar Contraseña',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_message.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (!_isEmailValid || _message.contains('Error'))
                                ? Colors.red.withOpacity(0.1)
                                : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: (!_isEmailValid || _message.contains('Error'))
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 16,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}