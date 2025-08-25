import 'package:flutter/material.dart';

class ConsultaPage extends StatelessWidget {
  const ConsultaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consulta'),
        backgroundColor: const Color.fromARGB(255, 2, 80, 145),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consulta Nutricional',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí puedes encontrar nutriólogos certificados que te ayudarán a mejorar tu alimentación y salud.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: const [
                  NutriologoCard(
                    name: 'Dra. María González',
                    specialty: 'Nutrición Clínica',
                    imageUrl: 'assets/images/default.png',
                  ),
                  NutriologoCard(
                    name: 'Dr. Juan Pérez',
                    specialty: 'Nutrición Deportiva',
                    imageUrl: 'assets/images/default.png',
                  ),
                  NutriologoCard(
                    name: 'Lic. Ana López',
                    specialty: 'Nutrición Infantil',
                    imageUrl: 'assets/images/default.png',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Aquí puedes implementar la navegación para agendar consulta
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 80, 145),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Agendar Consulta',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NutriologoCard extends StatelessWidget {
  final String name;
  final String specialty;
  final String imageUrl;

  const NutriologoCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage(imageUrl),
        ),
        title: Text(
          name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(specialty),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          // Aquí puedes navegar a los detalles del nutriólogo
        },
      ),
    );
  }
}
