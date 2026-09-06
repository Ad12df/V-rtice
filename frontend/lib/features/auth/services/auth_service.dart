import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de Perfil de Usuario con soporte RBAC (Admin / User)
class UserProfile {
  final String id;
  final String role;
  final String? fullName;
  final String? username;
  final String? email;
  final DateTime? birthdate;
  final String? avatarUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.role,
    this.fullName,
    this.username,
    this.email,
    this.birthdate,
    this.avatarUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isUser => role.toLowerCase() == 'user';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      role: (json['role'] as String?) ?? 'user',
      fullName: json['full_name'] as String?,
      username: json['username'] as String?,
      email: json['email'] as String?,
      birthdate: json['birthdate'] != null
          ? DateTime.tryParse(json['birthdate'] as String)
          : null,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'full_name': fullName,
      'username': username,
      'email': email,
      'birthdate': birthdate?.toIso8601String().split('T').first,
      'avatar_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

/// Servicio de autenticación oficial integrado con Supabase Auth y Profiles (RBAC)
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final GoTrueClient _auth = Supabase.instance.client.auth;
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Registrar nuevo usuario con Correo, Contraseña, Nombre Completo, Username y Fecha de Nacimiento
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    DateTime? birthdate,
    String? avatarUrl,
  }) async {
    final metadata = <String, dynamic>{
      'full_name': fullName.trim(),
      'name': fullName.trim(),
      'display_name': fullName.trim(),
      'username': username.trim().toLowerCase().replaceAll(' ', '_'),
      'role': 'user',
    };

    if (birthdate != null) {
      metadata['birthdate'] = birthdate.toIso8601String().split('T').first;
    }
    if (avatarUrl != null) {
      metadata['avatar_url'] = avatarUrl;
    }

    return await _auth.signUp(
      email: email.trim(),
      password: password,
      data: metadata,
    );
  }

  /// Obtener el perfil del usuario actual desde la tabla 'profiles'
  Future<UserProfile?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  /// Verificar si el usuario autenticado actual tiene rol de Administrador
  Future<bool> isCurrentUserAdmin() async {
    final profile = await getCurrentUserProfile();
    return profile?.isAdmin ?? false;
  }

  /// Actualizar los datos del perfil propio
  Future<void> updateProfile({
    String? fullName,
    String? username,
    DateTime? birthdate,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No hay sesión activa');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName.trim();
    if (username != null) updates['username'] = username.trim();
    if (birthdate != null) {
      updates['birthdate'] = birthdate.toIso8601String().split('T').first;
    }
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.length > 1) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }
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
