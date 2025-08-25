// Pagina para selecionar idioma y region
import 'package:flutter/material.dart';
import '../main/main_screen.dart';



class LanguageRegionPage extends StatelessWidget {
  const LanguageRegionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idioma y Región'),
        backgroundColor: const Color.fromARGB(255, 2, 80, 145),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Funcionalidad en desarrollo',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const MainScreen()),
                );
              },
              child: const Text('Volver al inicio'),
            ),
          ],
        ),
      ),
    );
  }
}
