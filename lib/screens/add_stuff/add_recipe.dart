import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Modelo para la receta
class Recipe {
  String title;
  String description;
  List<String> ingredients;
  List<String> steps;
  String category;
  String imageUrl;

  Recipe({
    this.title = '',
    this.description = '',
    this.ingredients = const [], // Esto crea una lista inmutable
    this.steps = const [], // Esto crea una lista inmutable
    this.category = '',
    this.imageUrl = '',
  });

  // Constructor que crea listas modificables
  Recipe.withModifiableLists({
    this.title = '',
    this.description = '',
    List<String>? ingredients,
    List<String>? steps,
    this.category = '',
    this.imageUrl = '',
  }) : ingredients = ingredients ?? [], // Lista vacía modificable
        steps = steps ?? []; // Lista vacía modificable

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'ingredients': ingredients,
      'steps': steps,
      'category': category,
      'image': imageUrl,
      'author': FirebaseAuth.instance.currentUser!.uid,
      'timestamp': Timestamp.now(),
    };
  }
}

// Provider para manejar el estado de agregar recetas
class RecipeFormProvider with ChangeNotifier {
  // Inicializar con el constructor que provee listas modificables
  Recipe _recipe = Recipe.withModifiableLists();
  File? _imageFile;
  bool _isLoading = false;
  bool _isNutriologo = false;
  List<String> _errors = [];

  Recipe get recipe => _recipe;
  File? get imageFile => _imageFile;
  bool get isLoading => _isLoading;
  bool get isNutriologo => _isNutriologo;
  List<String> get errors => _errors;

  // Lista de categorías disponibles
  final List<String> categories = [
    'Desayuno',
    'Comida',
    'Cena',
    'Colación',
    'Postre',
    'Vegetariano',
    'Vegano',
    'Otros',
  ];

  void updateTitle(String value) {
    _recipe.title = value;
    notifyListeners();
  }

  void updateDescription(String value) {
    _recipe.description = value;
    notifyListeners();
  }

  void updateIngredient(int index, String value) {
    if (index < _recipe.ingredients.length) {
      _recipe.ingredients[index] = value;
    }
    notifyListeners();
  }

  void addIngredient() {
    _recipe.ingredients.add('');
    notifyListeners();
  }

  void removeIngredient(int index) {
    if (_recipe.ingredients.length > 1) {
      _recipe.ingredients.removeAt(index);
      notifyListeners();
    }
  }

  void updateStep(int index, String value) {
    if (index < _recipe.steps.length) {
      _recipe.steps[index] = value;
    }
    notifyListeners();
  }

  void addStep() {
    _recipe.steps.add('');
    notifyListeners();
  }

  void removeStep(int index) {
    if (_recipe.steps.length > 1) {
      _recipe.steps.removeAt(index);
      notifyListeners();
    }
  }

  void setCategory(String value) {
    _recipe.category = value;
    notifyListeners();
  }

  Future<void> checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      _setLoading(true);
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        _isNutriologo = data['nutritionist'] ?? false;
      }
    } catch (e) {
      _addError("Error verificando los permisos: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        File image = File(pickedFile.path);
        int sizeInMB = image.lengthSync() ~/ (1024 * 1024);

        if (sizeInMB > 5) {
          _addError("La imagen debe ser menor a 5MB");
          return;
        }

        _imageFile = image;
        notifyListeners();
      }
    } catch (e) {
      _addError("Error al seleccionar imagen: $e");
    }
  }

  Future<bool> saveRecipe() async {
    _errors = [];

    if (!_isNutriologo) {
      _addError("Solo los nutriólogos pueden publicar recetas");
      return false;
    }

    if (_recipe.title.trim().isEmpty) {
      _addError("Debes agregar un título a la receta");
    }

    if (_recipe.description.trim().isEmpty) {
      _addError("La descripción es obligatoria");
    }

    if (_recipe.ingredients.isEmpty || _recipe.ingredients.any((ing) => ing.trim().isEmpty)) {
      _addError("Todos los ingredientes deben estar completos");
    }

    if (_recipe.steps.isEmpty || _recipe.steps.any((step) => step.trim().isEmpty)) {
      _addError("Todos los pasos deben estar completos");
    }

    if (_recipe.category.isEmpty) {
      _addError("Selecciona una categoría");
    }

    if (_errors.isNotEmpty) {
      notifyListeners();
      return false;
    }

    try {
      _setLoading(true);

      if (_imageFile != null) {
        String fileName = "recipes/${DateTime.now().millisecondsSinceEpoch}.jpg";
        Reference ref = FirebaseStorage.instance.ref().child(fileName);
        UploadTask uploadTask = ref.putFile(_imageFile!);
        TaskSnapshot snapshot = await uploadTask;
        _recipe.imageUrl = await snapshot.ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('recetas')
          .add(_recipe.toMap());

      return true;
    } catch (e) {
      _addError("Error al guardar la receta: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _addError(String error) {
    _errors.add(error);
    notifyListeners();
  }

  void clearErrors() {
    _errors = [];
    notifyListeners();
  }
}

class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({Key? key}) : super(key: key);

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _ingredientControllers = [];
  final List<TextEditingController> _stepControllers = [];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    // Limpiar controladores de ingredientes y pasos
    for (var controller in _ingredientControllers) {
      controller.dispose();
    }
    for (var controller in _stepControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final provider = RecipeFormProvider();
        provider.checkUserRole();
        // Inicializar con un ingrediente y un paso
        if (provider.recipe.ingredients.isEmpty) provider.addIngredient();
        if (provider.recipe.steps.isEmpty) provider.addStep();
        return provider;
      },
      child: Consumer<RecipeFormProvider>(
        builder: (context, provider, _) {
          // Actualizar los controladores con los valores actuales del provider
          if (_titleController.text != provider.recipe.title) {
            _titleController.text = provider.recipe.title;
          }
          if (_descriptionController.text != provider.recipe.description) {
            _descriptionController.text = provider.recipe.description;
          }

          // Asegurarse de que hay suficientes controladores para ingredientes
          _ensureControllers(_ingredientControllers, provider.recipe.ingredients.length);
          // Asegurarse de que hay suficientes controladores para pasos
          _ensureControllers(_stepControllers, provider.recipe.steps.length);

          return Scaffold(
            appBar: AppBar(
              title: const Text("Nueva Receta"),
              backgroundColor: Colors.blue[900],
              foregroundColor: Colors.white,
              elevation: 3,
            ),
            body: provider.isLoading && provider.errors.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _buildForm(context, provider),
          );
        },
      ),
    );
  }

  // Método para asegurar que tenemos suficientes controladores
  void _ensureControllers(List<TextEditingController> controllers, int count) {
    // Agregar controladores si faltan
    while (controllers.length < count) {
      controllers.add(TextEditingController());
    }
    // Remover controladores extra
    if (controllers.length > count) {
      for (int i = controllers.length - 1; i >= count; i--) {
        controllers[i].dispose();
        controllers.removeAt(i);
      }
    }
  }

  Future<void> _saveRecipe(BuildContext context, RecipeFormProvider provider) async {
    final FocusScopeNode currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus) {
      currentFocus.unfocus();
    }

    final success = await provider.saveRecipe();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Receta guardada correctamente!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      _showErrorDialog(context, provider);
    }
  }

  void _showErrorDialog(BuildContext context, RecipeFormProvider provider) {
    if (provider.errors.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text("Atención"),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: provider.errors.map((error) =>
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error)),
                    ],
                  ),
                )
            ).toList(),
          ),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            onPressed: () {
              provider.clearErrors();
              Navigator.pop(context);
            },
            child: const Text("ENTENDIDO"),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, RecipeFormProvider provider) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!provider.isNutriologo)
              _buildPermissionWarning(),

            const SizedBox(height: 20),
            _buildImagePicker(context, provider),
            const SizedBox(height: 24),

            _buildBasicInfoSection(context, provider),
            const SizedBox(height: 24),

            _buildCategorySection(context, provider),
            const SizedBox(height: 24),

            _buildIngredientsSection(context, provider),
            const SizedBox(height: 24),

            _buildStepsSection(context, provider),
            const SizedBox(height: 32),

            if (provider.isNutriologo)
              _buildSaveButton(context, provider),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 36),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Solo los nutriólogos verificados pueden crear y publicar recetas.",
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context, RecipeFormProvider provider) {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: provider.isNutriologo ? provider.pickImage : null,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                image: provider.imageFile != null
                    ? DecorationImage(
                  image: FileImage(provider.imageFile!),
                  fit: BoxFit.cover,
                )
                    : null,
              ),
              child: provider.imageFile == null
                  ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 50,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Añadir foto",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Máximo 5MB",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              )
                  : null,
            ),
          ),
          if (provider.imageFile != null)
            TextButton.icon(
              onPressed: provider.pickImage,
              icon: const Icon(Icons.edit),
              label: const Text("Cambiar imagen"),
            ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, RecipeFormProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  "Información básica",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              maxLines: 1,
              onChanged: provider.updateTitle,
              enabled: provider.isNutriologo,
              decoration: InputDecoration(
                labelText: "Título de la receta",
                hintText: "Ej. Ensalada mediterránea con garbanzos",
                prefixIcon: Icon(Icons.title, color: Colors.green.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                ),
                filled: true,
                fillColor: provider.isNutriologo ? Colors.white : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              style: TextStyle(
                color: provider.isNutriologo ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              onChanged: provider.updateDescription,
              enabled: provider.isNutriologo,
              decoration: InputDecoration(
                labelText: "Descripción",
                hintText: "Breve descripción de la receta, beneficios, etc.",
                prefixIcon: Icon(Icons.description, color: Colors.green.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade400),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green.shade600, width: 2),
                ),
                filled: true,
                fillColor: provider.isNutriologo ? Colors.white : Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              style: TextStyle(
                color: provider.isNutriologo ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(BuildContext context, RecipeFormProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  "Categoría",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: provider.categories.map((category) {
                return ChoiceChip(
                  label: Text(category),
                  selected: provider.recipe.category == category,
                  onSelected: provider.isNutriologo
                      ? (selected) {
                    if (selected) {
                      provider.setCategory(category);
                    }
                  }
                      : null,
                  selectedColor: Colors.green.shade100,
                  backgroundColor: Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                    side: BorderSide(
                      color: provider.recipe.category == category
                          ? Colors.green.shade300
                          : Colors.grey.shade300,
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: provider.recipe.category == category
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                    fontWeight: provider.recipe.category == category
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context, RecipeFormProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  "Ingredientes",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.recipe.ingredients.length,
              itemBuilder: (context, index) {
                // Sincronizar controlador con valor actual
                if (_ingredientControllers.length > index &&
                    _ingredientControllers[index].text != provider.recipe.ingredients[index]) {
                  _ingredientControllers[index].text = provider.recipe.ingredients[index];
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ingredientControllers.length > index ?
                          _ingredientControllers[index] : TextEditingController(text: provider.recipe.ingredients[index]),
                          onChanged: (value) => provider.updateIngredient(index, value),
                          decoration: InputDecoration(
                            hintText: "Ej: 200g de pechuga de pollo",
                            labelText: "Ingrediente ${index + 1}",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            suffixIcon: index > 0 ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: provider.isNutriologo ? () => provider.removeIngredient(index) : null,
                            ) : null,
                          ),
                          enabled: provider.isNutriologo,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: provider.isNutriologo ? provider.addIngredient : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text("Añadir Ingrediente"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepsSection(BuildContext context, RecipeFormProvider provider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                const Text(
                  "Pasos de Preparación",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.recipe.steps.length,
              itemBuilder: (context, index) {
                // Sincronizar controlador con valor actual
                if (_stepControllers.length > index &&
                    _stepControllers[index].text != provider.recipe.steps[index]) {
                  _stepControllers[index].text = provider.recipe.steps[index];
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        radius: 16,
                        child: Text("${index + 1}", style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold
                        )),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _stepControllers.length > index ?
                          _stepControllers[index] : TextEditingController(text: provider.recipe.steps[index]),
                          onChanged: (value) => provider.updateStep(index, value),
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: "Describe este paso...",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: index > 0 ? IconButton(
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: provider.isNutriologo ? () => provider.removeStep(index) : null,
                            ) : null,
                          ),
                          enabled: provider.isNutriologo,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: provider.isNutriologo ? provider.addStep : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.add, size: 20),
                label: const Text("Añadir Paso"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, RecipeFormProvider provider) {
    return ElevatedButton(
      onPressed: provider.isLoading ? null : () => _saveRecipe(context, provider),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.green.shade700,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 3,
      ),
      child: provider.isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          strokeWidth: 2.5,
        ),
      )
          : const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.save),
          SizedBox(width: 12),
          Text(
            "PUBLICAR RECETA",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}