import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dianui/core/providers/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/../screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'feedback_page.dart';
import 'edit_profile_page.dart';
import 'language_region_page.dart';

import 'widgets/settings_tile.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _handleLogout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error al cerrar sesión: $e");
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrio un error al cerrar sesión')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 2, 80, 145),
      ),
      backgroundColor: Colors.white,
      body: ListView(
        children: [
          const SizedBox(height: 16),
          
          // Botón para cambiar a modo oscuro
          SwitchListTile(
            title: const Text('Modo Oscuro'),
            subtitle: const Text('Activa el tema oscuro para la aplicación.'),
            value: themeProvider.themeMode == ThemeMode.dark,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
            activeColor: Colors.green,
          ),

          const SizedBox(height: 10),
          
          // Editar perfil
          SettingsTile(
            text: 'Perfil',
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => EditProfilePage()));
            }
          ),

          const SizedBox(height: 10),
          //Cambiar idioma para internalizacion
          SettingsTile(
            text: 'Idioma y Región',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LanguageRegionPage())

              );
            }
          ),

          const SizedBox(height: 10),

          // Notificaciones
          SettingsTile(
            text: 'Notificaciones',
            onTap: () {
              // Accion de notificaciones
            }
          ),

          const SizedBox(height: 10),

          // Botón para llevar a la página de soporte
          SettingsTile(
            text: 'Soporte',
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackPage())
                );
            }
          ),

          const SizedBox(height: 10),

          // Política de privacidad
          SettingsTile(
            text: 'Políticas de Privacidad',
            onTap: () {
              // Acción de políticas de privacidad
            }
          ),

          const SizedBox(height: 16),

          // Términos y condiciones
          SettingsTile(
            text: 'Términos y Condiciones',
            onTap: () {
              // Acción de los términos y condiciones
            }
          ),

          const SizedBox(height: 10),

          // Información de la App
          SettingsTile(
            text: 'Información de la App',
            onTap: () {
              // Acción de la información de la aplicación
            }
          ),

          const SizedBox(height: 10),

          // Acerca de
          SettingsTile(
            text: 'Acerca de',
            onTap: () {
              // Acción de Acerca de
            }
          ),

          const SizedBox(height: 10),

          // Botón para cerrar sesión
          SettingsTile(
            text: 'Cerrar sesión',
            onTap: () {
              _handleLogout(context);
            }
          ),

          const SizedBox(height: 10),

          // Botón para eliminar cuenta
          SettingsTile(
            text: 'Eliminar cuenta',
            onTap: () {
              // Acción para eliminar cuenta
            }
          ),

          const SizedBox(height: 20),

          // Logotipo de dianui
          Image.asset(
            'assets/images/logo_login.png',
            height: 80,
          ),
        ],
      ),
    );
  }
}