import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/core/constants/environment.dart';
import 'package:vertice/core/theme/app_theme.dart';
import 'package:vertice/features/auth/presentation/screens/auth_screen.dart';
import 'package:vertice/features/map/presentation/screens/map_screen.dart';
import 'package:vertice/features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización oficial de Supabase con URL y Anon Key configuradas
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Environment.supabaseAnonKey,
  );

  // Configuración de la barra de estado inmersiva para interfaz táctica oscura
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

/// Guardián de Autenticación reactivo que evalúa la sesión activa de Supabase Auth
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return const MapScreen(isGuest: false);
        }
        return const AuthScreen();
      },
    );
  }
}
