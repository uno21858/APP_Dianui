class Nutritionist {
  final String uid;
  final String name;
  final double rating;
  final bool isAvailable;
  final String schedule;
  final String profileImage;
  final String? specialty; // Campo opcional
  final String? occupation; // Campo opcional para filtrar

  Nutritionist({
    required this.uid,
    required this.name,
    required this.rating,
    required this.isAvailable,
    required this.schedule,
    required this.profileImage,
    this.specialty,
    this.occupation,
  });

  factory Nutritionist.fromMap(Map<String, dynamic> data) {
    return Nutritionist(
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Sin nombre',
      rating: (data['rating'] ?? 0).toDouble(),
      isAvailable: data['isAvailable'] ?? false,
      schedule: data['schedule'] ?? 'No disponible',
      profileImage: data['profileImage'] ?? '',
      specialty: data['specialty'],
      occupation: data['occupation'],
    );
  }
}