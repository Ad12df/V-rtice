import 'dart:io';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_db_store/dio_cache_interceptor_db_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';

/// Servicio singleton para gestión de caché offline de mapas en disco (SQLite).
/// Utiliza dio_cache_interceptor_db_store y flutter_map_cache para almacenamiento
/// persistente de teselas cartográficas de ArcGIS.
class MapCacheService {
  static final MapCacheService _instance = MapCacheService._internal();
  static MapCacheService get instance => _instance;
  MapCacheService._internal();

  DbCacheStore? _cacheStore;
  CacheOptions? _cacheOptions;
  TileProvider? _tileProvider;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  TileProvider get tileProvider => _tileProvider ?? NetworkTileProvider();

  static const String baseLayerUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}';
  static const String referenceLayerUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}';

  // Bounding Box de El Salvador: Suroeste 13.15, -90.15 a Noreste 14.45, -87.68
  static const double minLat = 13.15;
  static const double maxLat = 14.45;
  static const double minLng = -90.15;
  static const double maxLng = -87.68;

  /// Inicializa la base de datos SQLite de caché en el almacenamiento persistente
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/vertice_map_cache');
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      _cacheStore = DbCacheStore(
        databasePath: cacheDir.path,
        logStatements: false,
      );

      _cacheOptions = CacheOptions(
        store: _cacheStore,
        policy: CachePolicy.forceCache,
        hitCacheOnErrorExcept: [401, 403, 404],
        maxStale: const Duration(days: 30),
        priority: CachePriority.high,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      );

      _tileProvider = CachedTileProvider(
        maxStale: const Duration(days: 30),
        store: _cacheStore!,
      );

      _isInitialized = true;
      debugPrint('✅ [MapCacheService] Caché SQLite de mapas inicializado correctamente en: ${cacheDir.path}');
    } catch (e) {
      debugPrint('❌ [MapCacheService] Error al inicializar caché SQLite de mapa: $e');
      _tileProvider = NetworkTileProvider();
    }
  }

  /// Convierte coordenadas geográficas a coordenadas de tesela Slippy (x, y) para un nivel de zoom dado
  math.Point<int> latLngToTileCoordinates(double lat, double lng, int zoom) {
    final n = math.pow(2.0, zoom).toDouble();
    final x = ((lng + 180.0) / 360.0 * n).floor();
    final latRad = lat * math.pi / 180.0;
    final y = ((1.0 - math.log(math.tan(latRad) + 1.0 / math.cos(latRad)) / math.pi) / 2.0 * n).floor();
    return math.Point<int>(x, y);
  }

  /// Calcula la lista completa de teselas (x, y, z) que cubren la caja de El Salvador entre zooms 8 y 11
  List<({int z, int x, int y})> getElSalvadorTilesRange({int minZoom = 8, int maxZoom = 11}) {
    final List<({int z, int x, int y})> tiles = [];

    for (int z = minZoom; z <= maxZoom; z++) {
      final nw = latLngToTileCoordinates(maxLat, minLng, z);
      final se = latLngToTileCoordinates(minLat, maxLng, z);

      final minX = math.min(nw.x, se.x);
      final maxX = math.max(nw.x, se.x);
      final minY = math.min(nw.y, se.y);
      final maxY = math.max(nw.y, se.y);

      for (int x = minX; x <= maxX; x++) {
        for (int y = minY; y <= maxY; y++) {
          tiles.add((z: z, x: x, y: y));
        }
      }
    }

    return tiles;
  }

  /// Rutina de pre-descarga y almacenamiento en caché en disco de las teselas de El Salvador (Zooms 8 al 11).
  /// Descarga tanto la capa base como la capa de referencia.
  /// Si el dispositivo se encuentra offline o se interrumpe la conexión, no lanza excepciones fatales.
  Future<void> precacheElSalvador({
    void Function(int current, int total)? onProgress,
  }) async {
    if (!_isInitialized || _cacheOptions == null) {
      await initialize();
    }

    final tiles = getElSalvadorTilesRange(minZoom: 8, maxZoom: 11);
    // Cada posición requiere 2 teselas: Base Cartográfica y Capa de Referencia
    final totalRequests = tiles.length * 2;
    int completedRequests = 0;

    final dio = Dio();
    dio.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));
    dio.options.headers['User-Agent'] = 'com.vertice.app/1.0';
    dio.options.connectTimeout = const Duration(seconds: 8);
    dio.options.receiveTimeout = const Duration(seconds: 8);

    debugPrint('🚀 [MapCacheService] Iniciando precache de El Salvador: ${tiles.length} coordenadas x 2 capas = $totalRequests peticiones');

    // Procesar en lotes concurrentes controlados para no saturar el socket de red
    const batchSize = 6;
    for (int i = 0; i < tiles.length; i += batchSize) {
      final batch = tiles.sublist(i, math.min(i + batchSize, tiles.length));
      final futures = <Future<void>>[];

      for (final t in batch) {
        // Capa Base
        final baseUrl = baseLayerUrl
            .replaceAll('{z}', '${t.z}')
            .replaceAll('{y}', '${t.y}')
            .replaceAll('{x}', '${t.x}');

        // Capa Referencia
        final refUrl = referenceLayerUrl
            .replaceAll('{z}', '${t.z}')
            .replaceAll('{y}', '${t.y}')
            .replaceAll('{x}', '${t.x}');

        futures.add(
          _fetchAndCacheTile(dio, baseUrl).then((_) {
            completedRequests++;
            onProgress?.call(completedRequests, totalRequests);
          }),
        );

        futures.add(
          _fetchAndCacheTile(dio, refUrl).then((_) {
            completedRequests++;
            onProgress?.call(completedRequests, totalRequests);
          }),
        );
      }

      await Future.wait(futures);
    }

    debugPrint('✅ [MapCacheService] Rutina de precaché completada: $completedRequests / $totalRequests teselas procesadas.');
  }

  Future<void> _fetchAndCacheTile(Dio dio, String url) async {
    try {
      await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
    } catch (e) {
      // Supresión controlada de errores de red o timeouts para evitar abortar el precache completo
      debugPrint('⚠️ [MapCacheService] Falló tesela $url: $e');
    }
  }

  /// Limpia todo el contenido del almacén de caché local de mapas
  Future<void> clearCache() async {
    try {
      if (_cacheStore != null) {
        await _cacheStore!.clean();
        debugPrint('🗑️ [MapCacheService] Caché de mapas SQLite limpiado con éxito.');
      }
    } catch (e) {
      debugPrint('❌ [MapCacheService] Error al limpiar caché de mapas: $e');
    }
  }

  /// Cierra conexiones y libera recursos del almacén de base de datos
  Future<void> dispose() async {
    try {
      await _cacheStore?.close();
      _cacheStore = null;
      _isInitialized = false;
    } catch (e) {
      debugPrint('⚠️ [MapCacheService] Error al cerrar cacheStore: $e');
    }
  }
}
