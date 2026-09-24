import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor de estado reactivo y persistente para la configuracion global de GeoTurismo.
/// Gestiona Modo de Tema (Oscuro/Claro/Sistema), Escala de Fuente e Idioma (i18n).
class SettingsProvider extends ChangeNotifier {
  static final SettingsProvider _instance = SettingsProvider._internal();
  static SettingsProvider get instance => _instance;
  SettingsProvider._internal();

  static const String _keyThemeMode = 'vertice_setting_theme_mode';
  static const String _keyTextScaleFactor = 'vertice_setting_text_scale';
  static const String _keyLocaleLanguage = 'vertice_setting_locale_lang';

  // Valores predeterminados tacticos
  ThemeMode _themeMode = ThemeMode.dark;
  double _textScaleFactor = 1.0;
  Locale _locale = const Locale('es');
  bool _isLoaded = false;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  Locale get locale => _locale;
  bool get isLoaded => _isLoaded;

  /// Carga la configuracion persistida desde SharedPreferences al iniciar la aplicacion
  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Cargar Tema
      final themeIndex = prefs.getInt(_keyThemeMode);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        _themeMode = ThemeMode.values[themeIndex];
      } else {
        _themeMode = ThemeMode.dark;
      }

      // Cargar Escala de Fuente
      final scale = prefs.getDouble(_keyTextScaleFactor);
      if (scale != null) {
        _textScaleFactor = scale.clamp(0.85, 1.25);
      } else {
        _textScaleFactor = 1.0;
      }

      // Cargar Idioma
      final langCode = prefs.getString(_keyLocaleLanguage);
      if (langCode == 'en') {
        _locale = const Locale('en');
      } else {
        _locale = const Locale('es');
      }

      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[SettingsProvider] Error al cargar configuracion: $e');
      _isLoaded = true;
      notifyListeners();
    }
  }

  /// Cambia el modo de tema y lo persiste en disco
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyThemeMode, mode.index);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar modo de tema: $e');
    }
  }

  /// Cambia la escala de texto entre los niveles definidos (0.85, 1.0, 1.25)
  Future<void> setTextScaleFactor(double factor) async {
    final clamped = factor.clamp(0.85, 1.25);
    if (_textScaleFactor == clamped) return;
    _textScaleFactor = clamped;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_keyTextScaleFactor, clamped);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar factor de escala: $e');
    }
  }

  /// Cambia el idioma activo (es / en) y lo persiste
  Future<void> setLocale(Locale newLocale) async {
    if (_locale.languageCode == newLocale.languageCode) return;
    _locale = newLocale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLocaleLanguage, newLocale.languageCode);
    } catch (e) {
      debugPrint('[SettingsProvider] Error al guardar preferencia de idioma: $e');
    }
  }
}
