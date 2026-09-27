import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/localization/app_localizations.dart';
import 'package:vertice/core/providers/settings_provider.dart';
import 'package:vertice/features/map/services/location_service.dart';
import 'package:vertice/features/map/services/map_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsProvider Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Loads default tactical settings and persists changes across 5 languages and font scales', () async {
      final provider = SettingsProvider.instance;
      await provider.loadSettings();

      expect(provider.themeMode, ThemeMode.dark);
      expect(provider.fontScale, 1.0);
      expect(provider.textScaleFactor, 1.0);
      expect(provider.locale.languageCode, 'es');

      // Modificar Tema
      await provider.setThemeMode(ThemeMode.light);
      expect(provider.themeMode, ThemeMode.light);

      // Modificar Escala de Texto (fontScale)
      await provider.setFontScale(1.15);
      expect(provider.fontScale, 1.15);

      await provider.setFontScale(1.25);
      expect(provider.fontScale, 1.25);

      // Clamp de escala fuera de rango (0.80 a 1.30)
      await provider.setFontScale(2.0);
      expect(provider.fontScale, 1.30);

      await provider.setFontScale(0.5);
      expect(provider.fontScale, 0.80);

      // Modificar Idioma a los 5 soportados
      for (final code in ['en', 'zh', 'ru', 'pt', 'es']) {
        await provider.setLocale(Locale(code));
        expect(provider.locale.languageCode, code);
      }

      // Idioma no soportado debe ser ignorado
      await provider.setLocale(const Locale('de'));
      expect(provider.locale.languageCode, 'es');

      // Restaurar a valores estándar
      await provider.setThemeMode(ThemeMode.dark);
      await provider.setFontScale(1.0);
      await provider.setLocale(const Locale('es'));
    });

    test('Loads offline-first settings from SharedPreferences without network errors', () async {
      SharedPreferences.setMockInitialValues({
        'vertice_setting_locale_lang': 'zh',
        'vertice_setting_theme_mode': ThemeMode.light.index,
        'vertice_setting_text_scale': 1.15,
        'vertice_setting_traffic_layer': false,
        'vertice_setting_notifications': true,
      });

      final provider = SettingsProvider.instance;
      await provider.loadSettings();

      expect(provider.locale.languageCode, 'zh');
      expect(provider.themeMode, ThemeMode.light);
      expect(provider.fontScale, 1.15);
      expect(provider.trafficLayerEnabled, false);
      expect(provider.notificationsEnabled, true);

      // Soportar toggles locales
      await provider.setTrafficLayerEnabled(true);
      expect(provider.trafficLayerEnabled, true);

      // Restaurar
      await provider.setThemeMode(ThemeMode.dark);
      await provider.setFontScale(1.0);
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

  group('AppLocalizations Tests (5 Official Languages)', () {
    test('Translates keys properly in Spanish, English, Chinese, Russian and Portuguese', () {
      final locEs = AppLocalizations(const Locale('es'));
      expect(locEs.appName, 'Next Trip');
      expect(locEs.tacticalMap, 'MAPA TÁCTICO');
      expect(locEs.themeDark, 'Oscuro Táctico');
      expect(locEs.trafficLayer, 'Capa de Tráfico');

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.appName, 'Next Trip');
      expect(locEn.tacticalMap, 'TACTICAL MAP');
      expect(locEn.themeDark, 'Tactical Dark');
      expect(locEn.trafficLayer, 'Traffic Layer');

      final locZh = AppLocalizations(const Locale('zh'));
      expect(locZh.appName, 'Next Trip');
      expect(locZh.tacticalMap, '战术地图');
      expect(locZh.themeDark, '战术深色');
      expect(locZh.trafficLayer, '路况图层');

      final locRu = AppLocalizations(const Locale('ru'));
      expect(locRu.appName, 'Next Trip');
      expect(locRu.tacticalMap, 'ТАКТИЧЕСКАЯ КАРТА');
      expect(locRu.themeDark, 'Тактическая темная');
      expect(locRu.trafficLayer, 'Слой дорожного движения');

      final locPt = AppLocalizations(const Locale('pt'));
      expect(locPt.appName, 'Next Trip');
      expect(locPt.tacticalMap, 'MAPA TÁTICO');
      expect(locPt.themeDark, 'Escuro Tático');
      expect(locPt.trafficLayer, 'Camada de Trânsito');
    });

    test('Supported locales list contains all 5 official languages', () {
      expect(AppLocalizations.supportedLocales.length, 5);
      final codes = AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet();
      expect(codes, equals({'es', 'en', 'zh', 'ru', 'pt'}));
    });
  });

  group('Traffic & Routing Tests', () {
    test('TacticalRouteResult formats distance, ETA and traffic indicators correctly', () {
      const freeFlowResult = TacticalRouteResult(
        points: [LatLng(13.6983, -89.1914), LatLng(13.4930, -89.3820)],
        distanceKm: 34.2,
        baseDuration: Duration(minutes: 42),
        estimatedDuration: Duration(minutes: 42),
        trafficDelayMinutes: 0,
        trafficLevel: TrafficCongestionLevel.freeFlow,
        trafficConditionText: 'Flujo Libre',
        isRealRoute: true,
      );

      expect(freeFlowResult.formattedDistance, '34.2 km');
      expect(freeFlowResult.formattedDuration, '42 min');
      expect(freeFlowResult.formattedTrafficDuration, '42 min (flujo libre)');
      expect(freeFlowResult.trafficLevelLabel, 'Flujo Libre');
      expect(freeFlowResult.trafficColor, const Color(0xFF2ECC71));

      const moderateTrafficResult = TacticalRouteResult(
        points: [LatLng(13.6983, -89.1914), LatLng(13.4930, -89.3820)],
        distanceKm: 34.2,
        baseDuration: Duration(minutes: 42),
        estimatedDuration: Duration(minutes: 49),
        trafficDelayMinutes: 7,
        trafficLevel: TrafficCongestionLevel.moderate,
        trafficConditionText: 'Tráfico Moderado (+7 min)',
        isRealRoute: true,
      );

      expect(moderateTrafficResult.formattedDistance, '34.2 km');
      expect(moderateTrafficResult.formattedDuration, '49 min');
      expect(moderateTrafficResult.formattedTrafficDuration, '49 min (Tráfico Moderado)');
      expect(moderateTrafficResult.trafficLevelLabel, 'Tráfico Moderado');
      expect(moderateTrafficResult.trafficColor, const Color(0xFFF39C12));

      const heavyTrafficResult = TacticalRouteResult(
        points: [LatLng(13.6983, -89.1914), LatLng(13.4930, -89.3820)],
        distanceKm: 34.2,
        baseDuration: Duration(minutes: 42),
        estimatedDuration: Duration(minutes: 58),
        trafficDelayMinutes: 16,
        trafficLevel: TrafficCongestionLevel.heavy,
        trafficConditionText: 'Tráfico Lento (+16 min)',
        isRealRoute: true,
      );

      expect(heavyTrafficResult.trafficLevelLabel, 'Tráfico Lento');
      expect(heavyTrafficResult.trafficColor, const Color(0xFFE74C3C));
      expect(heavyTrafficResult.trafficDelayMinutes, 16);
    });

    test('LocationService calculates route with realistic ETA and traffic consideration', () async {
      final service = LocationService();
      const start = LatLng(13.6983, -89.1914); // San Salvador
      const destination = LatLng(13.4930, -89.3820); // El Tunco

      final result = await service.calculateRoute(
        start: start,
        destination: destination,
        trafficEnabled: true,
      );

      expect(result.points.length, greaterThanOrEqualTo(2));
      expect(result.distanceKm, greaterThan(10.0));
      expect(result.estimatedDuration.inMinutes, greaterThan(0));
      expect(result.trafficLevel, isNotNull);
      expect(result.trafficColor, isNotNull);
    });
  });
}
