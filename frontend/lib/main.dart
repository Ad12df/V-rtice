import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vertice/core/theme/app_theme.dart';
import 'package:vertice/features/splash/presentation/screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de la barra de estado inmersiva para interfaz oscura
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0A0A0C),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VerticeApp());
}

class VerticeApp extends StatelessWidget {
  const VerticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vértice - Turismo Oculto',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
