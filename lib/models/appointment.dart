// Definir un conjunto limitado de valores posibles
enum AppointmentStatus {
  pendiente,
  confirmada,
  cancelada,
  completada,
}

class Appointment {
  // Definir los atributos de la cita
  final String id;
  final String userId;
  final String nutritionistId;
  final DateTime dateTime;
  final AppointmentStatus status;
  final String? notes;

  // Constructor
  Appointment({
    required this.id,
    required this.userId,
    required this.nutritionistId,
    required this.dateTime,
    required this.status,
    required this.notes,
  });

  // Convertir a formato para subir a firestore
  Map <String, dynamic> toMap() => {
    'userId': userId,
    'nutritionistId': nutritionistId,
    'dateTime': dateTime.toIso8601String(),
    'status': status,
    'notes': notes,
  };

  // Convertir los datos a una instancia de la clase Appointment
  factory Appointment.fromMap(String id, Map<String, dynamic> map) => Appointment(
    id: id,
    userId: map['userId'],
    nutritionistId: map['nutritionistId'],
    dateTime: DateTime.parse(map['dateTime']),
    status: AppointmentStatus.values.firstWhere(
      (e) => e.name == map['status'],
    ),
    notes: map['notes'],
  );
}