import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/nutritionist.dart';

class NutritionistDetailPage extends StatefulWidget {
  final Nutritionist nutritionist;

  const NutritionistDetailPage({super.key, required this.nutritionist});

  @override
  State<NutritionistDetailPage> createState() => _NutritionistDetailPageState();
}

class _NutritionistDetailPageState extends State<NutritionistDetailPage> {
  // Obtener el horario del nutriólogo
  @override
  void initState() {
    super.initState();
    _fetchInformacionNutriologo();
  }

  String? horarioAtencion;
  String? nombreNutriologo;
  String? experienciaNutriologo;


  Future<void> _fetchInformacionNutriologo() async {
    try {
      // Obtener el UID del nutriólogo
      final uid = widget.nutritionist.uid;
      final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('informacion_nutriologo')
        .doc('perfil')
        .get();

      if (doc.exists) {
        final data = doc.data()!;
        final horarioInicio = data['horarioInicio'];
        final horarioFin = data['horarioFin'];

        setState(() {
          nombreNutriologo = data['nombre'];
          experienciaNutriologo = data['experiencia'];
          if (horarioInicio != null && horarioFin != null) {
            horarioAtencion = '${data['horarioInicio']} - ${data['horarioFin']}';
          } else {
            horarioAtencion = 'No disponible';
          }
        });
      }
    } catch (e) {
      setState(() {
        horarioAtencion = 'No disponible';
      });
    }
  }

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  Future<void> _selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _scheduleAppointment() async {
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una fecha y hora antes de agendar.')),
      );
      return;
    }

    final String userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    await FirebaseFirestore.instance.collection('consultas').add({
      'userId': userId,
      'nutritionist': widget.nutritionist.name,
      'date': DateFormat('yyyy-MM-dd').format(_selectedDate!),
      'time': _selectedTime!.format(context),
      'createdAt': Timestamp.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consulta agendada con éxito.')),
      );
    }

    _openGoogleCalendar();
  }

  Future<void> _openGoogleCalendar() async {
    if (_selectedDate == null || _selectedTime == null) return;

    final String startDateTime = DateFormat("yyyyMMdd'T'HHmmss").format(_selectedDate!);
    final String endDateTime = DateFormat("yyyyMMdd'T'HHmmss").format(
      _selectedDate!.add(const Duration(hours: 1)),
    );

    final String eventName = 'Consulta con ${widget.nutritionist.name}';
    final String eventDetails = 'Consulta de nutrición agendada en la app.';
    
    final Uri googleCalendarUri = Uri.parse(
      'https://www.google.com/calendar/render?action=TEMPLATE'
      '&text=$eventName'
      '&details=$eventDetails'
      '&dates=$startDateTime/$endDateTime',
    );

    if (await canLaunchUrl(googleCalendarUri)) {
      await launchUrl(googleCalendarUri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir Google Calendar.')),
      );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.nutritionist.name,
          style: TextStyle(color: Colors.white),
          ),
        backgroundColor: const Color.fromARGB(255, 2, 80, 145),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              children: [
                // Imagen de doctor
                CircleAvatar(
                  radius: 60, // Tamaño más grande para la imagen
                  backgroundColor: Colors.grey[300], // Fondo gris por defecto
                  backgroundImage: widget.nutritionist.profileImage.isNotEmpty
                      ? NetworkImage(widget.nutritionist.profileImage)
                      : null, // Cargar imagen si existe
                  child: widget.nutritionist.profileImage.isEmpty
                      ? const Icon(Icons.person, size: 60, color: Colors.white) // Ícono si no hay imagen
                      : null,
                ),
                SizedBox(width: 20),

                // Experiencia profesional
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        experienciaNutriologo ?? 'No disponible',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  )
                )
              ],
            ),

            const SizedBox(height: 20),
            // Horario disponible
            Text(
              'Horario disponible',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),

            // 📌 Información Detallada
            Row(
              children: [
                Icon(Icons.schedule, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Horario: ${horarioAtencion ?? "No disponible"}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 📌 Descripción del Nutriólogo
            Row(
              children: [
                const Text(
                  'Datos del nutriólogo',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            _buildInfoRow(Icons.person, widget.nutritionist.name),
            const SizedBox(height: 20),

            // 📌 Selección de Fecha y Hora
            _buildSectionTitle('Selecciona una fecha'),
            ElevatedButton(
              onPressed: () => _selectDate(context),
              child: Text(_selectedDate == null
                  ? 'Elegir fecha'
                  : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
            ),
            const SizedBox(height: 20),

            _buildSectionTitle('Selecciona una hora'),
            ElevatedButton(
              onPressed: () => _selectTime(context),
              child: Text(_selectedTime == null
                  ? 'Elegir hora'
                  : _selectedTime!.format(context)),
            ),
            const SizedBox(height: 30),

            // 📌 Botón de Agendar Consulta
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _scheduleAppointment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 2, 80, 145),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text(
                  'Agendar Consulta',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 5),
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 20)),
        ],
      ),
    );
  }
}
