import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Proveedor de estado reactivo y persistente para la configuración global de Next Trip.
/// Gestiona Modo de Tema (Oscuro/Claro/Sistema), Escala de Fuente (font_scale),
/// Idioma (i18n: es, en, zh, ru, pt), Capa de Tráfico y Notificaciones con persistencia
/// offline-first (SharedPreferences) y sincronización reactiva en la nube con Supabase (public.user_settings).
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  static SettingsProvider get instance => _instance;
  SettingsProvider._internal();

  static const String _keyThemeMode = 'vertice_setting_theme_mode';
  static const String _keyTextScaleFactor = 'vertice_setting_text_scale';
  static const String _keyLocaleLanguage = 'vertice_setting_locale_lang';
  static const String _keyTrafficLayer = 'vertice_setting_traffic_layer';
  static const String _keyNotifications = 'vertice_setting_notifications';

  /// Códigos ISO 639-1 soportados oficialmente
  static const Set<String> supportedLanguageCodes = {'es', 'en', 'zh', 'ru', 'pt'};

  // Valores predeterminados
  ThemeMode _themeMode = ThemeMode.dark;
  double _textScaleFactor = 1.0;
  Locale _locale = const Locale('es');
  bool _trafficLayerEnabled = true;
  bool _notificationsEnabled = true;
  bool _isLoaded = false;
  bool _authListenerConfigured = false;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _textScaleFactor;
  double get textScaleFactor => _textScaleFactor;
  Locale get locale => _locale;
  bool get trafficLayerEnabled => _trafficLayerEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoaded => _isLoaded;

  SupabaseClient? get _supabase {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Carga la configuración inicial:
  /// 1. Inmediatamente desde SharedPreferences (Offline-First, sin bloquear la UI)
  /// 2. Asíncronamente sincroniza con public.user_settings si hay sesión activa en Supabase
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // 1. Cargar Tema
      final themeIndex = prefs.getInt(_keyThemeMode);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.dark;
      }

      // 2. Cargar Escala de Fuente (font_scale)
      final scale = prefs.getDouble(_keyTextScaleFactor);
      if (scale != null) {
        _textScaleFactor = scale.clamp(0.80, 1.30);
      } else {
        _textScaleFactor = 1.0;
      }

      // 3. Cargar Idioma (es, en, zh, ru, pt)
      final langCode = prefs.getString(_keyLocaleLanguage);
      if (langCode != null && supportedLanguageCodes.contains(langCode)) {
        _locale = Locale(langCode);
      } else {
        _locale = const Locale('es');
      }

      // 4. Cargar capa de tráfico y notificaciones
      _trafficLayerEnabled = prefs.getBool(_keyTrafficLayer) ?? true;
      _notificationsEnabled = prefs.getBool(_keyNotifications) ?? true;

      _isLoaded = true;
      notifyListeners();

      // Configurar escucha de autenticación para sincronizar al iniciar sesión
      _setupAuthListener();

      // Sincronización asíncrona con Supabase en segundo plano
      syncWithSupabase();
    } catch (e) {
      debugPrint('[SettingsProvider] Error al cargar configuración local: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  void _setupAuthListener() {
    if (_authListenerConfigured) return;
    try {
      final client = _supabase;
      if (client != null) {
        _authListenerConfigured = true;
        client.auth.onAuthStateChange.listen((data) {
          if (data.session != null) {
            syncWithSupabase();
          }
        });
      }
    } catch (_) {}
  }

  /// Sincroniza las preferencias con public.user_settings en Supabase
  Future<void> syncWithSupabase() async {
    try {
      final client = _supabase;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return;

      final response = await client
          .from('user_settings')
          .select()
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final lang = response['language'] as String?;
        final theme = response['theme_mode'] as String?;
        final fontScaleVal = response['font_scale'] != null
            ? (response['font_scale'] as num).toDouble()
            : null;
        final traffic = response['traffic_layer_enabled'] as bool?;
        final notifs = response['notifications_enabled'] as bool?;

        bool changed = false;
        final prefs = await SharedPreferences.getInstance();

        // Sincronizar idioma
        if (lang != null && supportedLanguageCodes.contains(lang)) {
          if (_locale.languageCode != lang) {
            _locale = Locale(lang);
            await prefs.setString(_keyLocaleLanguage, lang);
            changed = true;
          }
        }

        // Sincronizar tema
        if (theme != null) {
          final mode = _parseThemeMode(theme);
          if (_themeMode != mode) {
            _themeMode = mode;
            await prefs.setInt(_keyThemeMode, mode.index);
            changed = true;
          }
        }

        // Sincronizar escala tipográfica (font_scale)
        if (fontScaleVal != null) {
          final clamped = fontScaleVal.clamp(0.80, 1.30);
          if ((_textScaleFactor - clamped).abs() > 0.01) {
            _textScaleFactor = clamped;
            await prefs.setDouble(_keyTextScaleFactor, clamped);
            changed = true;
          }
        }

        // Sincronizar tráfico
        if (traffic != null && _trafficLayerEnabled != traffic) {
          _trafficLayerEnabled = traffic;
          await prefs.setBool(_keyTrafficLayer, traffic);
          changed = true;
        }

        // Sincronizar notificaciones
        if (notifs != null && _notificationsEnabled != notifs) {
          _notificationsEnabled = notifs;
          await prefs.setBool(_keyNotifications, notifs);
          changed = true;
        }

        if (changed) {
          notifyListeners();
        }
      } else {
        // Usuarios preexistentes sin fila en user_settings: ejecutar upsert idempotente
        await client.from('user_settings').upsert({
          'user_id': user.id,
          'language': _locale.languageCode,
          'theme_mode': _themeModeToString(_themeMode),
          'font_scale': _textScaleFactor,
          'traffic_layer_enabled': _trafficLayerEnabled,
          'notifications_enabled': _notificationsEnabled,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('[SettingsProvider] Sincronización offline con Supabase (ignorado): $e');
    }
  }

  /// Cambia el modo de tema, lo persiste en SharedPreferences y sincroniza con Supabase
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar modo de tema local: $e');
    }

    _upsertRemoteSetting('theme_mode', _themeModeToString(mode));
  }

  /// Cambia la escala de texto (font_scale), la persiste en disco y sincroniza con Supabase
  Future<void> setFontScale(double factor) async {
    final clamped = factor.clamp(0.80, 1.30);
    if ((_textScaleFactor - clamped).abs() < 0.001) return;
    _textScaleFactor = clamped;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTextScaleFactor, clamped);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar factor de escala: $e');
    }

    _upsertRemoteSetting('font_scale', clamped);
  }

  /// Alias de compatibilidad hacia atrás para setFontScale
  Future<void> setTextScaleFactor(double factor) => setFontScale(factor);

  /// Cambia el idioma activo (es, en, zh, ru, pt), actualiza Locale en caliente,
  /// persiste en disco local y sincroniza asíncronamente con Supabase
  Future<void> setLocale(Locale newLocale) async {
    final code = newLocale.languageCode;
    if (!supportedLanguageCodes.contains(code)) return;
    if (_locale.languageCode == code) return;

    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocaleLanguage, code);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar preferencia de idioma: $e');
    }

    _upsertRemoteSetting('language', code);
  }

  /// Alterna la visibilidad de la capa de tráfico y persiste la preferencia
  Future<void> setTrafficLayerEnabled(bool enabled) async {
    if (_trafficLayerEnabled == enabled) return;
    _trafficLayerEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyTrafficLayer, enabled);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar estado de capa de tráfico: $e');
    }

    _upsertRemoteSetting('traffic_layer_enabled', enabled);
  }

  /// Alterna las notificaciones y persiste la preferencia
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyNotifications, enabled);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar notificaciones: $e');
    }

    _upsertRemoteSetting('notifications_enabled', enabled);
  }

  void _upsertRemoteSetting(String column, dynamic value) {
    try {
      final client = _supabase;
      final user = client?.auth.currentUser;
      if (client == null || user == null) return;

      client.from('user_settings').upsert({
        'user_id': user.id,
        column: value,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).catchError((err) {
        debugPrint('[SettingsProvider] Upsert asíncrono no crítico falló: $err');
      });
    } catch (_) {}
  }

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _parseThemeMode(String mode) {
    switch (mode.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }
}
