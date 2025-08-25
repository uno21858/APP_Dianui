class UserProfile {
  final String name;
  final String email;
  final String avatarUrl;

  UserProfile({
    required this.name,
    required this.email,
    required this.avatarUrl,
  });
}

// Datos de prueba
final UserProfile currentUser = UserProfile(
  name: 'Lorenzo Orrante',
  email: 'prueba@gmail.com',
  avatarUrl: 'assets/images/logo.jpeg', // Ruta a una imagen local
);
