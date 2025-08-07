import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/main_screen.dart';
import 'services/admin_university_service.dart';

void main() async {
  // S'assurer que Flutter est initialisé
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialisation Firebase avec gestion d'erreurs
  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyAqLUzTamS0BlpE7Ypo34Cxt12GoSfiWFM",
          authDomain: "orienta2025-3cdd7.firebaseapp.com",
          projectId: "orienta2025-3cdd7",
          storageBucket: "orienta2025-3cdd7.firebasestorage.app",
          messagingSenderId: "612366433401",
          appId: "1:612366433401:web:c5df25a540477c34eea8a8",
          measurementId: "G-9C6V0CJCX9",
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    print('✅ Firebase initialisé avec succès');
  } catch (e) {
    print('⚠️ Erreur Firebase: $e - L\'app fonctionnera en mode offline');
  }
  
  // Charger les universités personnalisées
  await AdminUniversityService.loadCustomUniversities();

  runApp(const OrientaApp());
}

class OrientaApp extends StatelessWidget {
  const OrientaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AppProvider(),
      child: MaterialApp(
        title: 'Orienta',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(
              0xFF2E7D32,
            ), // Vert pour représenter l'espoir et la croissance
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: false,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          cardTheme: const CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        home: const MainScreen(),
      ),
    );
  }
}
