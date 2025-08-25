class Recipe {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final List<String> ingredients;
  final List<String> steps;
  final String description;
  final String author; // Nuevo campo para el autor

  Recipe({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.ingredients,
    required this.steps,
    required this.description,
    required this.author, // Añadido al constructor
  });

  factory Recipe.fromFirestore(Map<String, dynamic> data, String documentId) {
    return Recipe(
      id: documentId,
      name: data['title'] ?? 'Sin nombre',
      category: data['categoria'] ?? 'Sin categoría',
      imageUrl: data['image'] ?? 'assets/images/default.png',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      steps: (data['steps'] != null && data['steps'] is List)
          ? (data['steps'] as List)
          .whereType<Map<String, dynamic>>()
          .map((step) => step['description']?.toString() ?? 'Paso sin descripción')
          .toList()
          : [],
      description: data['description'] ?? 'Sin descripción',
      author: data['author'] ?? '', // Añadido para el autor
    );
  }
}