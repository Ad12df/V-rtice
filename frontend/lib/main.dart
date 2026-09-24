import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/core/constants/environment.dart';
import 'package:vertice/core/localization/app_localizations.dart';
import 'package:vertice/core/providers/settings_provider.dart';
import 'package:vertice/core/theme/app_theme.dart';
import 'package:vertice/features/auth/presentation/screens/auth_screen.dart';
import 'package:vertice/features/map/services/map_cache_service.dart';
import 'package:vertice/features/shell/presentation/screens/app_shell.dart';
import 'package:vertice/features/splash/presentation/screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicialización oficial de Supabase con URL y Anon Key configuradas
  await Supabase.initialize(
    url: Environment.supabaseUrl,
    // ignore: deprecated_member_use
    anonKey: Environment.supabaseAnonKey,
  );

  // Carga reactiva de preferencias de usuario persistidas (Tema, Escala e Idioma)
  await SettingsProvider.instance.loadSettings();

  // Inicialización del almacén SQLite de caché offline para cartografía táctica
  await MapCacheService.instance.initialize();

  // Configuración de la barra de estado inmersiva para interfaz táctica oscura
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF0D1B2A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const VerticeApp());
}

class VerticeApp extends StatelessWidget {
  const VerticeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsProvider.instance,
      builder: (context, _) {
        final settings = SettingsProvider.instance;
        return MaterialApp(
          title: 'GeoTurismo',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          locale: settings.locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
          builder: (context, child) {
            final mediaQueryData = MediaQuery.of(context);
            return MediaQuery(
              data: mediaQueryData.copyWith(
                textScaler: TextScaler.linear(settings.textScaleFactor),
              ),
              child: child ?? const SizedBox.shrink(),
            );
          },
        );
      },
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
          return const AppShell();
        }
        return const AuthScreen();
      },
    );
  }
}
