import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Sistema de Internacionalización (i18n) para VÉRTICE.
/// Soporta Español ('es') e Inglés ('en') con tipado estricto y fallback seguro.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('es'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('es'),
    Locale('en'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      // General & Common
      'appName': 'GeoTurismo',
      'appSubtitle': 'Cartografía Táctica & Turismo en El Salvador',
      'cancel': 'CANCELAR',
      'accept': 'ACEPTAR',
      'confirm': 'CONFIRMAR',
      'close': 'CERRAR',
      'save': 'GUARDAR',
      'delete': 'ELIMINAR',
      'loading': 'CARGANDO...',
      'pleaseWait': 'Por favor espera...',
      'error': 'ERROR',
      'success': 'ÉXITO',
      'warning': 'ADVERTENCIA',
      'retry': 'REINTENTAR',

      // Auth
      'authTitle': 'GEOTURISMO // ENLACE TÁCTICO',
      'authSubtitle': 'Sistema de Cartografía y Exploración',
      'login': 'INICIAR SESIÓN',
      'register': 'REGISTRARSE',
      'email': 'Correo Electrónico',
      'password': 'Clave de Acceso',
      'confirmPassword': 'Confirmar Clave',
      'fullName': 'Nombre Completo',
      'username': 'Nombre de Usuario',
      'birthdate': 'Fecha de Nacimiento',
      'noAccount': '¿No tienes cuenta táctica? Regístrate',
      'haveAccount': '¿Ya posees credenciales? Inicia sesión',
      'passwordMinLength': 'Mínimo 8 caracteres',
      'passwordsDontMatch': 'Las claves no coinciden',
      'fieldRequired': 'Campo obligatorio',
      'invalidEmail': 'Ingresa un correo válido',
      'loginSuccess': 'Enlace establecido con éxito.',
      'registerSuccess': 'Operador registrado correctamente.',
      'sessionExpired': 'Sesión caducada. Por favor autentícate de nuevo.',

      // Map
      'tacticalMap': 'MAPA TÁCTICO',
      'searchPlaceholder': 'Buscar cumbres, ruinas, volcanes...',
      'operator': 'OPERADOR',
      'operatorPosition': 'POSICIÓN DEL OPERADOR',
      'targetDistance': 'DISTANCIA AL OBJETIVO',
      'difficulty': 'DIFICULTAD',
      'category': 'CATEGORÍA',
      'exploration': 'EXPLORACIÓN',
      'reconnaissance': 'RECONOCIMIENTO DE CAMPO',
      'focus': 'ENFOCAR',
      'traceRoute': 'TRAZAR RUTA',
      'cancelRoute': 'CANCELAR RUTA',
      'deletePin': 'ELIMINAR PIN',
      'inspect': 'INSPECCIONAR',
      'pinAdded': 'PIN AÑADIDO',
      'outsideJurisdiction': 'Coordenada fuera de la jurisdicción táctica de El Salvador.',
      'gpsDisabledWarning': 'Activa el GPS de tu dispositivo para actualizar tu posición táctica real.',
      'gpsSettingsDisabled': 'GPS desactivado en ajustes. Actívalo para rastrear tu posición.',
      'gpsPending': 'GPS PENDIENTE',

      // Settings
      'settingsTitle': 'AJUSTES // SISTEMA',
      'profileTitle': 'PERFIL DE OPERADOR',
      'profilePhoto': 'FOTO DE PERFIL DE OPERADOR',
      'takePhoto': 'Tomar foto con la cámara',
      'chooseGallery': 'Elegir de la galería',
      'removePhoto': 'Eliminar foto actual',
      'identificationData': 'DATOS DE IDENTIFICACIÓN',
      'securityHeader': 'SEGURIDAD // CLAVE DE ACCESO',
      'newPassword': 'Nueva Clave',
      'updatePassword': 'ACTUALIZAR CLAVE',
      'passwordUpdated': 'Clave de acceso actualizada correctamente.',
      'systemPreferences': 'PREFERENCIAS DEL SISTEMA',
      'themeMode': 'MODO VISUAL',
      'themeDark': 'Oscuro Táctico',
      'themeLight': 'Claro Alto Contraste',
      'themeSystem': 'Sistema',
      'fontScale': 'TAMAÑO DE FUENTE',
      'fontSmall': 'Pequeño (0.85x)',
      'fontNormal': 'Normal (1.0x)',
      'fontLarge': 'Grande (1.25x)',
      'language': 'IDIOMA // LANGUAGE',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'gpsTracking': 'Rastreo GPS en tiempo real',
      'gpsTrackingActive': 'Activo — posición visible en mapa',
      'gpsTrackingInactive': 'Inactivo — sensor desconectado',
      'offlineMapCache': 'CACHÉ OFFLINE DE MAPAS',
      'offlineMapDesc': 'Almacena teselas de El Salvador para navegación sin conexión',
      'precacheTiles': 'DESCARGAR MAPA OFFLINE (ZOOM 8-11)',
      'precacheProgress': 'Descargando teselas:',
      'precacheSuccess': 'Mapa de El Salvador precacheado en disco.',
      'clearCache': 'LIMPIAR CACHÉ DE MAPA',
      'cacheCleared': 'Caché de mapas eliminado.',
      'signOut': 'CERRAR SESIÓN TÁCTICA',
      'signOutConfirmTitle': 'DESCONECTAR ENLACE',
      'signOutConfirmMessage': '¿Deseas cerrar la sesión táctica actual?',
      'systemFooter': 'SISTEMA DE CARTOGRAFÍA // SV-2026',
    },
    'en': {
      // General & Common
      'appName': 'GeoTurismo',
      'appSubtitle': 'Tactical Cartography & Tourism in El Salvador',
      'cancel': 'CANCEL',
      'accept': 'ACCEPT',
      'confirm': 'CONFIRM',
      'close': 'CLOSE',
      'save': 'SAVE',
      'delete': 'DELETE',
      'loading': 'LOADING...',
      'pleaseWait': 'Please wait...',
      'error': 'ERROR',
      'success': 'SUCCESS',
      'warning': 'WARNING',
      'retry': 'RETRY',

      // Auth
      'authTitle': 'GEOTURISMO // TACTICAL LINK',
      'authSubtitle': 'Cartography & Exploration System',
      'login': 'SIGN IN',
      'register': 'SIGN UP',
      'email': 'Email Address',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'fullName': 'Full Name',
      'username': 'Username',
      'birthdate': 'Birthdate',
      'noAccount': "Don't have an account? Sign up",
      'haveAccount': 'Already have credentials? Sign in',
      'passwordMinLength': 'Minimum 8 characters',
      'passwordsDontMatch': 'Passwords do not match',
      'fieldRequired': 'Required field',
      'invalidEmail': 'Enter a valid email address',
      'loginSuccess': 'Tactical link established.',
      'registerSuccess': 'Operator registered successfully.',
      'sessionExpired': 'Session expired. Please authenticate again.',

      // Map
      'tacticalMap': 'TACTICAL MAP',
      'searchPlaceholder': 'Search peaks, ruins, volcanoes...',
      'operator': 'OPERATOR',
      'operatorPosition': 'OPERATOR POSITION',
      'targetDistance': 'DISTANCE TO TARGET',
      'difficulty': 'DIFFICULTY',
      'category': 'CATEGORY',
      'exploration': 'EXPLORATION',
      'reconnaissance': 'FIELD RECON',
      'focus': 'FOCUS',
      'traceRoute': 'ROUTE TARGET',
      'cancelRoute': 'CANCEL ROUTE',
      'deletePin': 'DELETE PIN',
      'inspect': 'INSPECT',
      'pinAdded': 'PIN ADDED',
      'outsideJurisdiction': 'Coordinate outside tactical jurisdiction of El Salvador.',
      'gpsDisabledWarning': 'Enable device GPS to update your real-time tactical position.',
      'gpsSettingsDisabled': 'GPS disabled in settings. Enable it to track position.',
      'gpsPending': 'GPS PENDING',

      // Settings
      'settingsTitle': 'SETTINGS // SYSTEM',
      'profileTitle': 'OPERATOR PROFILE',
      'profilePhoto': 'OPERATOR PROFILE PHOTO',
      'takePhoto': 'Take photo with camera',
      'chooseGallery': 'Choose from gallery',
      'removePhoto': 'Remove current photo',
      'identificationData': 'IDENTIFICATION DATA',
      'securityHeader': 'SECURITY // ACCESS KEY',
      'newPassword': 'New Password',
      'updatePassword': 'UPDATE PASSWORD',
      'passwordUpdated': 'Password updated successfully.',
      'systemPreferences': 'SYSTEM PREFERENCES',
      'themeMode': 'THEME MODE',
      'themeDark': 'Tactical Dark',
      'themeLight': 'High-Contrast Light',
      'themeSystem': 'System',
      'fontScale': 'FONT SCALE',
      'fontSmall': 'Small (0.85x)',
      'fontNormal': 'Normal (1.0x)',
      'fontLarge': 'Large (1.25x)',
      'language': 'LANGUAGE // IDIOMA',
      'langSpanish': 'Español',
      'langEnglish': 'English',
      'gpsTracking': 'Real-Time GPS Tracking',
      'gpsTrackingActive': 'Active — position visible on map',
      'gpsTrackingInactive': 'Inactive — sensor disconnected',
      'offlineMapCache': 'OFFLINE MAP CACHE',
      'offlineMapDesc': 'Stores El Salvador tiles for offline navigation',
      'precacheTiles': 'PRE-CACHE MAP (ZOOM 8-11)',
      'precacheProgress': 'Downloading tiles:',
      'precacheSuccess': 'El Salvador map cached to disk.',
      'clearCache': 'CLEAR MAP CACHE',
      'cacheCleared': 'Map cache cleared.',
      'signOut': 'TACTICAL SIGN OUT',
      'signOutConfirmTitle': 'DISCONNECT LINK',
      'signOutConfirmMessage': 'Do you want to end the current tactical session?',
      'systemFooter': 'CARTOGRAPHY SYSTEM // SV-2026',
    },
  };

  String translate(String key) {
    final code = locale.languageCode;
    return _localizedValues[code]?[key] ??
        _localizedValues['es']?[key] ??
        key;
  }

  // Getters comunes
  String get appName => translate('appName');
  String get appSubtitle => translate('appSubtitle');
  String get cancel => translate('cancel');
  String get accept => translate('accept');
  String get confirm => translate('confirm');
  String get close => translate('close');
  String get save => translate('save');
  String get delete => translate('delete');
  String get loading => translate('loading');
  String get pleaseWait => translate('pleaseWait');
  String get error => translate('error');
  String get success => translate('success');
  String get warning => translate('warning');
  String get retry => translate('retry');

  // Auth
  String get authTitle => translate('authTitle');
  String get authSubtitle => translate('authSubtitle');
  String get login => translate('login');
  String get register => translate('register');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirmPassword');
  String get fullName => translate('fullName');
  String get username => translate('username');
  String get birthdate => translate('birthdate');
  String get noAccount => translate('noAccount');
  String get haveAccount => translate('haveAccount');
  String get passwordMinLength => translate('passwordMinLength');
  String get passwordsDontMatch => translate('passwordsDontMatch');
  String get fieldRequired => translate('fieldRequired');
  String get invalidEmail => translate('invalidEmail');
  String get loginSuccess => translate('loginSuccess');
  String get registerSuccess => translate('registerSuccess');
  String get sessionExpired => translate('sessionExpired');

  // Map
  String get tacticalMap => translate('tacticalMap');
  String get searchPlaceholder => translate('searchPlaceholder');
  String get operator => translate('operator');
  String get operatorPosition => translate('operatorPosition');
  String get targetDistance => translate('targetDistance');
  String get difficulty => translate('difficulty');
  String get category => translate('category');
  String get exploration => translate('exploration');
  String get reconnaissance => translate('reconnaissance');
  String get focus => translate('focus');
  String get traceRoute => translate('traceRoute');
  String get cancelRoute => translate('cancelRoute');
  String get deletePin => translate('deletePin');
  String get inspect => translate('inspect');
  String get pinAdded => translate('pinAdded');
  String get outsideJurisdiction => translate('outsideJurisdiction');
  String get gpsDisabledWarning => translate('gpsDisabledWarning');
  String get gpsSettingsDisabled => translate('gpsSettingsDisabled');
  String get gpsPending => translate('gpsPending');

  // Settings
  String get settingsTitle => translate('settingsTitle');
  String get profileTitle => translate('profileTitle');
  String get profilePhoto => translate('profilePhoto');
  String get takePhoto => translate('takePhoto');
  String get chooseGallery => translate('chooseGallery');
  String get removePhoto => translate('removePhoto');
  String get identificationData => translate('identificationData');
  String get securityHeader => translate('securityHeader');
  String get newPassword => translate('newPassword');
  String get updatePassword => translate('updatePassword');
  String get passwordUpdated => translate('passwordUpdated');
  String get systemPreferences => translate('systemPreferences');
  String get themeMode => translate('themeMode');
  String get themeDark => translate('themeDark');
  String get themeLight => translate('themeLight');
  String get themeSystem => translate('themeSystem');
  String get fontScale => translate('fontScale');
  String get fontSmall => translate('fontSmall');
  String get fontNormal => translate('fontNormal');
  String get fontLarge => translate('fontLarge');
  String get language => translate('language');
  String get langSpanish => translate('langSpanish');
  String get langEnglish => translate('langEnglish');
  String get gpsTracking => translate('gpsTracking');
  String get gpsTrackingActive => translate('gpsTrackingActive');
  String get gpsTrackingInactive => translate('gpsTrackingInactive');
  String get offlineMapCache => translate('offlineMapCache');
  String get offlineMapDesc => translate('offlineMapDesc');
  String get precacheTiles => translate('precacheTiles');
  String get precacheProgress => translate('precacheProgress');
  String get precacheSuccess => translate('precacheSuccess');
  String get clearCache => translate('clearCache');
  String get cacheCleared => translate('cacheCleared');
  String get signOut => translate('signOut');
  String get signOutConfirmTitle => translate('signOutConfirmTitle');
  String get signOutConfirmMessage => translate('signOutConfirmMessage');
  String get systemFooter => translate('systemFooter');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['es', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  AppLocalizations get loc => AppLocalizations.of(this);
}
