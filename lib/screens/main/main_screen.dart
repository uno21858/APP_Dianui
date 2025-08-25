import 'package:dianui/screens/main/nutritionists_page.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'blog_page.dart';
import 'recipes_page.dart';
import 'package:dianui/screens/main/profile_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const NutritionistsPage(),
    const RecipesPage(),
    const BlogPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

@override
Widget build(BuildContext context) {
  return Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    ),
    child: Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Stack(
        children: [
          
          Positioned.fill(
            child: Opacity(
              opacity: 1, // 🔹 Control de transparencia
              child: Image.asset(
                'assets/design/BannerInferior2.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          BottomNavigationBar(
            items: [
              BottomNavigationBarItem(
                
                icon: Container(
                    margin: const EdgeInsets.only(top: 20), 
                    child: Image.asset(
                      'assets/design/IconoDianui.png',
                      height: 24,
                      color: _selectedIndex == 0 ? Colors.black : null, 
                    ),
                  ),
                  label: 'Inicio',
                ),
              BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top:20),
                    child:Icon(Icons.person),
                    ), 
                    label: 'Nutriólogos',
              ),
              BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top:20),
                    child:Icon(Icons.article),
                    ), 
                    label: 'Recetas',
              ),
              BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top:20),
                    child:Icon(Icons.restaurant_menu),
                    ), 
                    label: 'Blog',
              ),
              BottomNavigationBarItem(
                  icon: Container(
                    margin: const EdgeInsets.only(top:20),
                    child:Icon(Icons.account_circle),
                    ), 
                    label: 'Perfil',
              ),
            ],
            currentIndex: _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent, // 🔹 Dejar fondo transparente
            elevation: 0,
            selectedItemColor: Colors.grey,
            unselectedItemColor: Colors.black,
            onTap: _onItemTapped,
          ),
        ],
      ),
    ),
  );
}
}
