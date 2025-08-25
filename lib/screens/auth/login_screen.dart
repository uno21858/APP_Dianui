import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:dianui/screens/main/main_screen.dart';
import 'package:dianui/screens/auth/register_screen.dart';
import 'password_recovery_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Asegurar que Firebase esté inicializado antes de ejecutar la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dianui',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, ingresa tu correo y contraseña."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        // 🚨 Verificar si el usuario ha confirmado su correo
        if (!user.emailVerified) {
          await user.sendEmailVerification(); // Opción: reenviar verificación
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Debes verificar tu correo antes de iniciar sesión. Se ha enviado un nuevo correo de verificación."),
              backgroundColor: Colors.orange,
            ),
          );
          return; // Detener el inicio de sesión
        }

        debugPrint("Inicio de sesión exitoso: ${user.uid}");

        // 🔹 Guardar sesión en SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = "Error al iniciar sesión";
      if (e.code == 'user-not-found') {
        errorMessage = "Usuario no encontrado";
      } else if (e.code == 'wrong-password') {
        errorMessage = "Contraseña incorrecta";
      } else if (e.code == 'invalid-email') {
        errorMessage = "Correo electrónico inválido";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Demasiados intentos. Intenta más tarde.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ocurrió un error inesperado."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Forzar el tema claro para la pantalla de inicio de sesión
    return Theme(
      data: ThemeData.light().copyWith(
        // Asegurar que los colores del tema claro se apliquen correctamente
        scaffoldBackgroundColor: Colors.white,
        textTheme: ThemeData.light().textTheme,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SingleChildScrollView( // Permite desplazamiento si el contenido es mayor que la pantalla
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                    'assets/images/logo_login.png', width: 225, height: 150),
                const Text(
                  'BIENVENIDA',
                  style: TextStyle(fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF025091)),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Ingresa Para Continuar',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
                ),
                const SizedBox(height: 15),
                // Campo de texto: Correo electrónico
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _emailController,
                    autocorrect: false,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 68, 2, 105),
                        fontWeight: FontWeight.w300,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.green, width: 2.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Campo de texto: Contraseña
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _passwordController,
                    autocorrect: false,
                    textAlign: TextAlign.center,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      labelStyle: const TextStyle(
                        color: Color.fromARGB(255, 68, 2, 105),
                        fontWeight: FontWeight.w300,
                      ),
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _signIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 2, 80, 145),
                    minimumSize: const Size(300, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero),
                  ),
                  child: const Text(
                    'INICIAR SESIÓN',
                    style: TextStyle(
                        fontSize: 24, color: Colors.lightGreenAccent),
                  ),
                ),
                Container(color: const Color(0xFF646E6E), width: 300, height: 6),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ModernRegisterScreen()),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w300,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PasswordRecoveryScreen()),
                    );
                  },
                  child: const Text(
                    '¿Olvidaste tu contraseña?',
                    style: TextStyle(color: Colors.black,
                        fontWeight: FontWeight.w300,
                        fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}