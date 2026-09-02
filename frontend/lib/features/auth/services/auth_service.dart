import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio de autenticación oficial integrado con Supabase Auth
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoTrueClient _auth = Supabase.instance.client.auth;

  /// Obtener el usuario autenticado actual
  User? get currentUser => _auth.currentUser;

  /// Obtener la sesión activa
  Session? get currentSession => _auth.currentSession;

  /// Verificar si existe un usuario autenticado
  bool get isAuthenticated => _auth.currentUser != null;

  /// Stream de cambios de estado de autenticación
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// Iniciar sesión con Correo y Contraseña
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Registrar nuevo agente con Correo, Contraseña y Alias/Nombre
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await _auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'display_name': displayName.trim(),
        'alias': displayName.trim(),
      },
    );
  }

  /// Cerrar sesión actual
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Enviar enlace de restablecimiento de contraseña
  Future<void> resetPasswordForEmail(String email) async {
    await _auth.resetPasswordForEmail(
      email.trim(),
    );
  }
}
