import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vertice/core/localization/app_localizations.dart';
import 'package:vertice/core/providers/settings_provider.dart';
import 'package:vertice/features/map/services/map_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default tactical settings and persists changes', () async {
      final provider = SettingsProvider.instance;
      await provider.loadSettings();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.textScaleFactor, 1.0);
      expect(provider.locale.languageCode, 'es');

      // Modificar Tema
      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);

      // Modificar Escala de Texto
      await provider.setTextScaleFactor(1.25);
      expect(provider.textScaleFactor, 1.25);

      // Clamp de escala fuera de rango
      await provider.setTextScaleFactor(2.0);
      expect(provider.textScaleFactor, 1.25);

      await provider.setTextScaleFactor(0.5);
      expect(provider.textScaleFactor, 0.85);

      // Modificar Idioma
      await provider.setLocale(const Locale('en'));
      expect(provider.locale.languageCode, 'en');

      // Restaurar a valores estándar
      await provider.setThemeMode(ThemeMode.dark);
      await provider.setTextScaleFactor(1.0);
      await provider.setLocale(const Locale('es'));
    });
  });

  group('MapCacheService Tests', () {
    test('Calculates valid Slippy tile coordinates for El Salvador', () {
      final service = MapCacheService.instance;

      // San Salvador: lat ~ 13.6983, lng ~ -89.1914 at zoom 8
      final point = service.latLngToTileCoordinates(13.6983, -89.1914, 8);
      expect(point.x, greaterThan(0));
      expect(point.y, greaterThan(0));

      // Bounding box range (Zooms 8 to 11)
      final tiles = service.getElSalvadorTilesRange(minZoom: 8, maxZoom: 11);
      expect(tiles.isNotEmpty, isTrue);

      // Verificar que todos los zooms solicitados están cubiertos
      final zooms = tiles.map((t) => t.z).toSet();
      expect(zooms, containsAll([8, 9, 10, 11]));
    });
  });

  group('AppLocalizations Tests', () {
    test('Translates keys properly in Spanish and English', () {
      final locEs = AppLocalizations(const Locale('es'));
      expect(locEs.appName, 'VÉRTICE');
      expect(locEs.tacticalMap, 'MAPA TÁCTICO');
      expect(locEs.themeDark, 'Oscuro Táctico');

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.appName, 'VÉRTICE');
      expect(locEn.tacticalMap, 'TACTICAL MAP');
      expect(locEn.themeDark, 'Tactical Dark');
    });
  });
}
