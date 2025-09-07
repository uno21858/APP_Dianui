import 'package:dianui/screens/main/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 🔹 Firestore
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'core/providers/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'package:dianui/core/services/chat_service.dart'; // 🔹 Chat Service
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🔹 Verificar conexión con Firestore
    FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);

    // 🔹 Habilitar Performance Monitoring
    FirebasePerformance.instance.setPerformanceCollectionEnabled(true);

    // 🔹 Configurar Crashlytics para capturar errores globales
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    print("isLoggedIn: $isLoggedIn");

    Widget initialScreen = isLoggedIn ? const MainScreen() : const LoginScreen();

    runApp(MyApp(initialScreen: initialScreen));
  } catch (e, stackTrace) {
    debugPrint("Error al inicializar Firebase: $e");
    FirebaseCrashlytics.instance.recordError(e, stackTrace); // 🔹 Reportar error en Crashlytics
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  final Widget initialScreen; // ⬅️ Pantalla inicial según el estado de login

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        Provider<ChatService>(create: (context) => ChatService()), // 🔹 Agregar ChatService
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Dianui',
            themeMode: themeProvider.themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            home: initialScreen,
          );
        },
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            "Error al inicializar Firebase. Revisa la consola.",
            style: TextStyle(fontSize: 18, color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
