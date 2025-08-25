import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/fab_nutriologo.dart';
import '../../models/recipe.dart';
import '../../widgets/custom_app_bar.dart';
import '../details/recipe_detail_page.dart';
import '../../core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  bool _gridView = false;
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Variables para la paginación
  int _limit = 25;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _showEmptyMessage = false;
  DocumentSnapshot? _lastDocument;
  List<Recipe> _allRecipes = [];

  // Lista de categorías
  final List<String> _categories = [
    'Todos',
    'Desayuno',
    'Comida',
    'Cena',
    'Snack',
    'Postre',
    'Vegetariano',
    'Vegano',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialRecipes();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialRecipes() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recetas')
          .orderBy('title')
          .limit(_limit)
          .get();

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (querySnapshot.docs.isNotEmpty) {
            _lastDocument = querySnapshot.docs.last;
            _allRecipes = querySnapshot.docs.map((doc) {
              return Recipe.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            }).toList();
            _showEmptyMessage = false;
          } else {
            _showEmptyMessage = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _showEmptyMessage = true;
        });
      }
    }
  }

  Future<void> _loadMoreRecipes() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('recetas')
          .orderBy('title')
          .startAfterDocument(_lastDocument!)
          .limit(_limit)
          .get();

      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          if (querySnapshot.docs.isEmpty) {
            _hasMore = false;
          } else {
            _lastDocument = querySnapshot.docs.last;
            _allRecipes.addAll(querySnapshot.docs.map((doc) {
              return Recipe.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
            }).toList());
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading more recipes: $e');
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadMoreRecipes();
    }
  }

  List<Recipe> get _filteredRecipes {
    return _allRecipes.where((recipe) {
      // Filtro por categoría
      if (_selectedCategory != null &&
          _selectedCategory!.isNotEmpty &&
          _selectedCategory != 'Todos') {
        if (recipe.category.toLowerCase() !=
            _selectedCategory!.toLowerCase()) {
          return false;
        }
      }
      // Filtro por búsqueda
      if (_searchController.text.isNotEmpty) {
        return recipe.name.toLowerCase().contains(
            _searchController.text.toLowerCase()) ||
            recipe.description.toLowerCase().contains(
                _searchController.text.toLowerCase());
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Recetas'),
      body: Column(
        children: [
          // Barra de búsqueda y botón de vista
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar recetas...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      hintStyle: TextStyle(
                        color: isDarkMode
                            ? Colors.grey[400]
                            : Colors.grey[600],
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear,
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    ),
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _gridView ? Icons.list : Icons.grid_view,
                      color: isDarkMode
                          ? Colors.grey[400]
                          : Colors.grey[700],
                    ),
                    onPressed: () {
                      setState(() {
                        _gridView = !_gridView;
                      });
                    },
                    tooltip: _gridView ? 'Vista de lista' : 'Vista de cuadrícula',
                  ),
                ),
              ],
            ),
          ),
          // Filtros de categoría
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category ||
                        (category == 'Todos' && _selectedCategory == null),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected
                            ? (category == 'Todos' ? null : category)
                            : null;
                      });
                    },
                    selectedColor: isDarkMode
                        ? Colors.green[800]
                        : Colors.green[100],
                    backgroundColor: isDarkMode
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: _selectedCategory == category
                          ? isDarkMode
                          ? Colors.white
                          : Colors.green[800]
                          : isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
          // Lista de recetas
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildContent(),
          ),
        ],
      ),
      floatingActionButton: const NutriologoFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildContent() {
    if (_showEmptyMessage || _allRecipes.isEmpty) {
      return Center(
        child: Text(
          'No se encontraron recetas',
          style: TextStyle(
            color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? Colors.white
                : Colors.black,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() => _isLoading = true);
        await _loadInitialRecipes();
      },
      child: _gridView ? _buildGridRecipes() : _buildListRecipes(),
    );
  }

  Widget _buildListRecipes() {
    final isDarkMode = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return ListView.builder(
      controller: _scrollController,
      itemCount: _filteredRecipes.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredRecipes.length) {
          return _buildLoadingIndicator();
        }

        final recipe = _filteredRecipes[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () => _navigateToDetail(recipe),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: _buildRecipeImage(recipe, height: 80, width: 80),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.category,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.description.length > 100
                              ? '${recipe.description.substring(0, 100)}...'
                              : recipe.description,
                          style: TextStyle(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        if (recipe.ingredients.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Ingredientes: ${recipe.ingredients.length}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDarkMode ? Colors.green[300] : Colors.green,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridRecipes() {
    final isDarkMode = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredRecipes.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _filteredRecipes.length) {
          return _buildLoadingIndicator();
        }

        final recipe = _filteredRecipes[index];
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(12.0),
            onTap: () => _navigateToDetail(recipe),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12.0)),
                    child: _buildRecipeImage(recipe, fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.category,
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      if (recipe.ingredients.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${recipe.ingredients.length} ingredientes',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDarkMode ? Colors.green[300] : Colors.green,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    final isDarkMode = Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: _hasMore
            ? CircularProgressIndicator(
          color: isDarkMode ? Colors.green[300] : Colors.green,
        )
            : Text(
          'No hay más recetas para mostrar',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeImage(Recipe recipe, {
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
  }) {
    if (recipe.imageUrl.isEmpty || !recipe.imageUrl.startsWith('http')) {
      return Image.asset(
        'assets/images/default.png',
        height: height,
        width: width,
        fit: fit,
      );
    }

    return Image.network(
      recipe.imageUrl,
      height: height,
      width: width,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/default.png',
          height: height,
          width: width,
          fit: fit,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
            color: Provider.of<ThemeProvider>(context).themeMode == ThemeMode.dark
                ? Colors.green[300]
                : Colors.green,
          ),
        );
      },
    );
  }

  void _navigateToDetail(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecipeDetailPage(recipe: recipe),
      ),
    );
  }
}