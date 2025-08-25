import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  final TextEditingController _pesoController = TextEditingController();
  final TextEditingController _comidaController = TextEditingController();
  final TextEditingController _ejercicioController = TextEditingController();
  double _aguaLitros = 0;
  double _suenoHoras = 0;
  String _estadoAnimo = 'Feliz';

  final Map<String, bool> _habitos = {
    'Beber 2L de agua': false,
    'Dormir 8 horas': false,
    'Comer frutas y verduras': false,
    'Evitar azúcar procesada': false,
  };

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _guardarSeguimiento() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final data = {
      'userId': user.uid,
      'fecha': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'peso': double.tryParse(_pesoController.text),
      'estadoAnimo': _estadoAnimo,
      'comida': _comidaController.text,
      'ejercicio': _ejercicioController.text,
      'agua': _aguaLitros,
      'sueno': _suenoHoras,
      'habitos': _habitos,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance.collection('seguimiento').add(data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento guardado exitosamente')),
      );

      _pesoController.clear();
      _comidaController.clear();
      _ejercicioController.clear();
      setState(() {
        _aguaLitros = 0;
        _suenoHoras = 0;
        _estadoAnimo = 'Feliz';
        _habitos.updateAll((key, value) => false);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseCardStyle = BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withValues(),
          spreadRadius: 2,
          blurRadius: 5,
          offset: const Offset(0, 3),
        )
      ],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Seguimiento', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 2, 80, 145),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Progreso del Usuario'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: baseCardStyle,
                child: TextFormField(
                  controller: _pesoController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Peso actual (kg)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty ? 'Ingresa tu peso' : null,
                ),
              ),
              _buildSectionTitle('Registro Diario'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: baseCardStyle,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _estadoAnimo,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Feliz', 'Triste', 'Cansado', 'Motivado', 'Estresado']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) => setState(() => _estadoAnimo = value!),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _comidaController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: '¿Qué comiste hoy?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _ejercicioController,
                      decoration: const InputDecoration(
                        labelText: '¿Hiciste ejercicio? ¿Qué tipo?',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: baseCardStyle,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Litros de agua'),
                    Slider(
                      value: _aguaLitros,
                      min: 0,
                      max: 4,
                      divisions: 8,
                      label: '${_aguaLitros.toStringAsFixed(1)}L',
                      onChanged: (value) => setState(() => _aguaLitros = value),
                    ),
                    const Text('Horas de sueño'),
                    Slider(
                      value: _suenoHoras,
                      min: 0,
                      max: 12,
                      divisions: 12,
                      label: '${_suenoHoras.toStringAsFixed(0)}h',
                      onChanged: (value) => setState(() => _suenoHoras = value),
                    ),
                  ],
                ),
              ),
              _buildSectionTitle('Hábitos'),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: baseCardStyle,
                child: Column(
                  children: _habitos.keys.map((h) {
                    return CheckboxListTile(
                      title: Text(h),
                      value: _habitos[h],
                      onChanged: (value) => setState(() => _habitos[h] = value!),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Icon(Icons.save),
                  label: const Text('Guardar Seguimiento'),
                  onPressed: _isLoading ? null : _guardarSeguimiento,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
