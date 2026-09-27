import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/core/constants/environment.dart';

/// Modelo de Punto de Interés Táctico / Turismo en El Salvador con datos territoriales y de precio
class TacticalPoi {
  final String id;
  final String name;
  final String category;
  final LatLng location;
  final String description;
  final String difficulty;
  final IconData icon;
  final bool isCustom;
  final String department;
  final String zone;
  final String priceCategory;
  final double entryFee;
  final String priceRange;
  final String? imageUrl;

  const TacticalPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    this.difficulty = 'MEDIA',
    required this.icon,
    this.isCustom = false,
    this.department = 'San Salvador',
    this.zone = 'Zona Central',
    this.priceCategory = 'GRATUITO',
    this.entryFee = 0.00,
    this.priceRange = 'Gratis',
    this.imageUrl,
  });

  factory TacticalPoi.fromSupabase(Map<String, dynamic> json) {
    double lat = 13.7942;
    double lng = -88.8965;

    if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    } else if (json['location'] != null && json['location'] is Map) {
      final locMap = json['location'] as Map<String, dynamic>;
      if (locMap['coordinates'] != null && locMap['coordinates'] is List) {
        final coords = locMap['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
    } else if (json['location'] != null && json['location'] is String) {
      final str = json['location'] as String;
      final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false).firstMatch(str);
      if (match != null) {
        lng = double.tryParse(match.group(1) ?? '') ?? lng;
        lat = double.tryParse(match.group(2) ?? '') ?? lat;
      }
    }

    final category = (json['category'] as String?) ?? 'DESTINO TURÍSTICO';
    final name = (json['name'] as String?) ?? 'Punto Turístico';

    // Resolver departamento y zona geográfica a partir de metadatos o nombres conocidos
    final dept = (json['department'] as String?) ?? _deduceDepartment(name);
    final zone = (json['zone'] as String?) ?? _deduceZone(dept);
    
    // Resolver precio estructurado y rango
    final priceCat = (json['price_category'] as String?) ?? _deducePriceCategory(json);
    final fee = json['entry_fee'] != null
        ? (json['entry_fee'] as num).toDouble()
        : _deduceFeeFromCategory(priceCat);

    final resolvedPriceRange = (json['price_range'] as String?) ??
        (fee <= 0.0 ? 'Gratis' : '\$${fee.toStringAsFixed(2)} USD');

    final imgUrl = json['image_url'] as String? ??
        ((json['images'] is List && (json['images'] as List).isNotEmpty)
            ? (json['images'] as List).first.toString()
            : null);

    return TacticalPoi(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      name: name,
      category: category,
      location: LatLng(lat, lng),
      description: (json['description'] as String?) ??
          'Punto de interés turístico en El Salvador.',
      difficulty: (json['difficulty'] as String?) ?? 'MEDIA',
      icon: _getIconForCategory(category),
      isCustom: false,
      department: dept,
      zone: zone,
      priceCategory: priceCat,
      entryFee: fee,
      priceRange: resolvedPriceRange,
      imageUrl: imgUrl,
    );
  }

  TacticalPoi copyWith({
    String? id,
    String? name,
    String? category,
    LatLng? location,
    String? description,
    String? difficulty,
    IconData? icon,
    bool? isCustom,
    String? department,
    String? zone,
    String? priceCategory,
    double? entryFee,
    String? priceRange,
    String? imageUrl,
  }) {
    return TacticalPoi(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      location: location ?? this.location,
      description: description ?? this.description,
      difficulty: difficulty ?? this.difficulty,
      icon: icon ?? this.icon,
      isCustom: isCustom ?? this.isCustom,
      department: department ?? this.department,
      zone: zone ?? this.zone,
      priceCategory: priceCategory ?? this.priceCategory,
      entryFee: entryFee ?? this.entryFee,
      priceRange: priceRange ?? this.priceRange,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static IconData _getIconForCategory(String category) {
    final catUpper = category.toUpperCase();
    if (catUpper.contains('VOLCÁN') || catUpper.contains('MONTAÑA') || catUpper.contains('CERRO')) {
      return Icons.terrain_rounded;
    } else if (catUpper.contains('PLAYA') || catUpper.contains('COSTA') || catUpper.contains('SURF')) {
      return Icons.waves_rounded;
    } else if (catUpper.contains('SELVA') || catUpper.contains('PARQUE')) {
      return Icons.forest_rounded;
    } else if (catUpper.contains('ACUÁTICO') || catUpper.contains('LAGO')) {
      return Icons.water_rounded;
    } else if (catUpper.contains('HISTÓRICO')) {
      return Icons.museum_rounded;
    }
    return Icons.explore_rounded;
  }

  static String _deducePriceCategory(Map<String, dynamic> json) {
    final raw = (json['price_range'] ?? json['price'] ?? '').toString().toUpperCase();
    if (raw.contains('GRAT') || raw.contains('LIBRE')) return 'GRATUITO';
    if (raw.contains('EXCLUSIV') || raw.contains('\$\$\$')) return 'EXCLUSIVO';
    if (raw.contains('MODERAD') || raw.contains('\$\$')) return 'MODERADO';
    return 'ECONÓMICO';
  }

  static double _deduceFeeFromCategory(String category) {
    switch (category.toUpperCase()) {
      case 'GRATUITO':
        return 0.00;
      case 'ECONÓMICO':
        return 3.00;
      case 'MODERADO':
        return 10.00;
      case 'EXCLUSIVO':
        return 25.00;
      default:
        return 0.00;
    }
  }

  static String _deduceDepartment(String name) {
    final n = name.toLowerCase();
    if (n.contains('santa ana') || n.contains('tazumal') || n.contains('coatepeque') || n.contains('chalchuapa')) {
      return 'Santa Ana';
    } else if (n.contains('imposible') || n.contains('ahuachapán') || n.contains('apaneca')) {
      return 'Ahuachapán';
    } else if (n.contains('tunco') || n.contains('surf city') || n.contains('la libertad') || n.contains('san diego')) {
      return 'La Libertad';
    } else if (n.contains('suchitoto') || n.contains('suchitlán') || n.contains('tercios')) {
      return 'Cuscatlán';
    } else if (n.contains('pital') || n.contains('chalatenango') || n.contains('palma')) {
      return 'Chalatenango';
    } else if (n.contains('juayúa') || n.contains('sonsonate') || n.contains('salcoatitán')) {
      return 'Sonsonate';
    } else if (n.contains('costa del sol') || n.contains('la paz') || n.contains('zacatecoluca')) {
      return 'La Paz';
    } else if (n.contains('chinchontepec') || n.contains('san vicente') || n.contains('amapulapa')) {
      return 'San Vicente';
    } else if (n.contains('cinquera') || n.contains('cabañas') || n.contains('sensuntepeque')) {
      return 'Cabañas';
    } else if (n.contains('jiquilisco') || n.contains('usulután') || n.contains('alegría')) {
      return 'Usulután';
    } else if (n.contains('chaparrastique') || n.contains('san miguel')) {
      return 'San Miguel';
    } else if (n.contains('perquín') || n.contains('morazán') || n.contains('sapo')) {
      return 'Morazán';
    } else if (n.contains('conchagua') || n.contains('la unión') || n.contains('fonseca')) {
      return 'La Unión';
    }
    return 'San Salvador';
  }

  static String _deduceZone(String department) {
    switch (department) {
      case 'Ahuachapán':
      case 'Santa Ana':
      case 'Sonsonate':
        return 'Zona Occidental';
      case 'San Salvador':
      case 'La Libertad':
      case 'Chalatenango':
      case 'Cuscatlán':
        return 'Zona Central';
      case 'La Paz':
      case 'Cabañas':
      case 'San Vicente':
        return 'Zona Paracentral';
      case 'Usulután':
      case 'San Miguel':
      case 'Morazán':
      case 'La Unión':
        return 'Zona Oriental';
      default:
        return 'Zona Central';
    }
  }
}

/// Servicio singleton para consultar y gestionar ubicaciones y destinos turísticos exclusivamente en Supabase
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Notificador reactivo con la lista completa de ubicaciones en memoria (inicia vacía)
  final ValueNotifier<List<TacticalPoi>> poisNotifier =
      ValueNotifier<List<TacticalPoi>>(<TacticalPoi>[]);

  /// Obtiene la lista de todas las ubicaciones ÚNICA Y EXCLUSIVAMENTE desde Supabase
  Future<List<TacticalPoi>> fetchLocations() async {
    try {
      // 1. Intentar primero con la función RPC get_all_locations
      try {
        final response = await _supabase.rpc('get_all_locations');
        if (response != null && response is List && response.isNotEmpty) {
          final loaded = response
              .map((item) =>
                  TacticalPoi.fromSupabase(item as Map<String, dynamic>))
              .toList();
          poisNotifier.value = loaded;
          return loaded;
        }
      } catch (rpcError) {
        debugPrint('ℹ️ [LocationService] RPC get_all_locations fallback: $rpcError');
      }

      // 2. Consulta directa sobre la tabla locations
      final data = await _supabase
          .from('locations')
          .select('id, name, description, category, difficulty, department, zone, price_category, entry_fee, location, created_at');

      if (data.isNotEmpty) {
        final loaded = (data as List)
            .map((item) =>
                TacticalPoi.fromSupabase(item as Map<String, dynamic>))
            .toList();
        poisNotifier.value = loaded;
        return loaded;
      }

      // Si la tabla en Supabase está vacía, la lista queda limpia en estado vacío
      poisNotifier.value = <TacticalPoi>[];
      return <TacticalPoi>[];
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al cargar ubicaciones desde Supabase: $e');
      poisNotifier.value = <TacticalPoi>[];
      return <TacticalPoi>[];
    }
  }

  /// Registrar un nuevo destino turístico (Exclusivo Administradores)
  Future<TacticalPoi> addPoi(TacticalPoi poi) async {
    try {
      final wktLocation = 'POINT(${poi.location.longitude} ${poi.location.latitude})';
      final insertData = <String, dynamic>{
        'name': poi.name,
        'description': poi.description,
        'category': poi.category,
        'difficulty': poi.difficulty,
        'department': poi.department,
        'zone': poi.zone,
        'price_category': poi.priceCategory,
        'entry_fee': poi.entryFee,
        'location': wktLocation,
      };
      if (poi.imageUrl != null && poi.imageUrl!.isNotEmpty) {
        insertData['image_url'] = poi.imageUrl;
      }

      final res = await _supabase.from('locations').insert(insertData).select();

      TacticalPoi savedPoi = poi;
      if (res.isNotEmpty) {
        savedPoi = TacticalPoi.fromSupabase(res.first);
      }

      // Actualizar estado local inmediatamente
      final updated = List<TacticalPoi>.from(poisNotifier.value)..add(savedPoi);
      poisNotifier.value = updated;
      return savedPoi;
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al insertar destino turístico en Supabase: $e');
      final updated = List<TacticalPoi>.from(poisNotifier.value)..add(poi);
      poisNotifier.value = updated;
      return poi;
    }
  }

  /// Modificar un punto turístico existente
  Future<void> updatePoi(TacticalPoi poi) async {
    try {
      final wktLocation = 'POINT(${poi.location.longitude} ${poi.location.latitude})';
      final updateData = <String, dynamic>{
        'name': poi.name,
        'description': poi.description,
        'category': poi.category,
        'difficulty': poi.difficulty,
        'department': poi.department,
        'zone': poi.zone,
        'price_category': poi.priceCategory,
        'entry_fee': poi.entryFee,
        'location': wktLocation,
      };
      if (poi.imageUrl != null && poi.imageUrl!.isNotEmpty) {
        updateData['image_url'] = poi.imageUrl;
      }

      await _supabase.from('locations').update(updateData).eq('id', poi.id);

      final updated = List<TacticalPoi>.from(poisNotifier.value);
      final index = updated.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        updated[index] = poi;
        poisNotifier.value = updated;
      }
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al actualizar destino turístico en Supabase: $e');
      final updated = List<TacticalPoi>.from(poisNotifier.value);
      final index = updated.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        updated[index] = poi;
        poisNotifier.value = updated;
      }
    }
  }

  /// Eliminar un punto táctico
  Future<void> deletePoi(String id) async {
    try {
      await _supabase.from('locations').delete().eq('id', id);
      final updated = List<TacticalPoi>.from(poisNotifier.value)..removeWhere((p) => p.id == id);
      poisNotifier.value = updated;
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al eliminar destino en Supabase: $e');
      final updated = List<TacticalPoi>.from(poisNotifier.value)..removeWhere((p) => p.id == id);
      poisNotifier.value = updated;
    }
  }

  /// Obtiene la ruta entre dos puntos con consideración de tráfico vehicular (TomTom Routing o OSRM + Modelo de Congestión SV)
  Future<TacticalRouteResult> calculateRoute({
    required LatLng start,
    required LatLng destination,
    bool trafficEnabled = false,
  }) async {
    // 1. Intentar TomTom Routing API si la clave está configurada
    if (Environment.tomtomApiKey.isNotEmpty &&
        Environment.tomtomApiKey != 'YOUR_TOMTOM_KEY') {
      try {
        final tomtomUri = Uri.parse(
          'https://api.tomtom.com/routing/1/calculateRoute/'
          '${start.latitude},${start.longitude}:${destination.latitude},${destination.longitude}'
          '/json?key=${Environment.tomtomApiKey}&traffic=true&computeTravelTimeFor=all',
        );

        final tomtomResponse =
            await http.get(tomtomUri).timeout(const Duration(seconds: 4));
        if (tomtomResponse.statusCode == 200) {
          final data = jsonDecode(tomtomResponse.body) as Map<String, dynamic>;
          final routes = data['routes'] as List?;
          if (routes != null && routes.isNotEmpty) {
            final firstRoute = routes.first as Map<String, dynamic>;
            final summary = firstRoute['summary'] as Map<String, dynamic>?;
            final legs = firstRoute['legs'] as List?;

            if (summary != null && legs != null && legs.isNotEmpty) {
              final lengthMeters =
                  (summary['lengthInMeters'] as num?)?.toDouble() ?? 0.0;
              final travelTimeSec =
                  (summary['travelTimeInSeconds'] as num?)?.toInt() ?? 0;
              final noTrafficSec =
                  (summary['noTrafficTravelTimeInSeconds'] as num?)?.toInt() ??
                      travelTimeSec;
              final trafficDelaySec =
                  (summary['trafficDelayInSeconds'] as num?)?.toInt() ?? 0;

              final legPoints =
                  legs.first['points'] as List<dynamic>? ?? <dynamic>[];
              final points = legPoints.map<LatLng>((p) {
                final map = p as Map<String, dynamic>;
                return LatLng(
                  (map['latitude'] as num).toDouble(),
                  (map['longitude'] as num).toDouble(),
                );
              }).toList();

              if (points.isNotEmpty) {
                final delayMin = (trafficDelaySec / 60.0).round();
                final level = _evaluateTrafficLevel(
                  baseSeconds: noTrafficSec,
                  delayMinutes: delayMin,
                );

                return TacticalRouteResult(
                  points: points,
                  distanceKm: lengthMeters / 1000.0,
                  baseDuration: Duration(seconds: noTrafficSec),
                  estimatedDuration: Duration(seconds: travelTimeSec),
                  trafficDelayMinutes: delayMin,
                  trafficLevel: level,
                  trafficConditionText: _trafficConditionDescription(
                    level,
                    delayMin,
                  ),
                  isRealRoute: true,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('ℹ️ [LocationService] TomTom Routing no disponible ($e). Pasando a OSRM.');
      }
    }

    // 2. Ruta vial vía OSRM con aplicación del Modelo de Congestión Vial de El Salvador
    try {
      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${start.longitude},${start.latitude};${destination.longitude},${destination.latitude}'
        '?overview=full&geometries=geojson',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final first = routes.first as Map<String, dynamic>;
          final geometry = first['geometry'] as Map<String, dynamic>?;
          final coords = geometry?['coordinates'] as List?;
          final distanceMeters = (first['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (first['duration'] as num?)?.toDouble() ?? 0.0;

          if (coords != null && coords.isNotEmpty) {
            final points = coords.map<LatLng>((c) {
              final pair = c as List;
              return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
            }).toList();

            final baseSeconds = durationSeconds.round();
            final trafficFactor = _calculateElSalvadorTrafficFactor(
              start: start,
              destination: destination,
              trafficLayerActive: trafficEnabled,
            );

            final effectiveSeconds = (baseSeconds * trafficFactor).round();
            final delaySeconds = effectiveSeconds - baseSeconds;
            final delayMinutes = (delaySeconds / 60.0).round();

            final level = _evaluateTrafficLevel(
              baseSeconds: baseSeconds,
              delayMinutes: delayMinutes,
            );

            return TacticalRouteResult(
              points: points,
              distanceKm: distanceMeters / 1000.0,
              baseDuration: Duration(seconds: baseSeconds),
              estimatedDuration: Duration(seconds: effectiveSeconds),
              trafficDelayMinutes: delayMinutes,
              trafficLevel: level,
              trafficConditionText: _trafficConditionDescription(level, delayMinutes),
              isRealRoute: true,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('ℹ️ [LocationService] OSRM no disponible ($e). Usando cálculo geodésico.');
    }

    // 3. Fallback geodésico (Cálculo sin conexión con factor de sinuosidad vial de El Salvador)
    const distanceCalculator = Distance();
    final distanceMeters = distanceCalculator.as(LengthUnit.Meter, start, destination);
    final distanceKm = distanceMeters / 1000.0;
    final estimatedRoadKm = distanceKm * 1.30;
    final baseMinutes = ((estimatedRoadKm / 50.0) * 60.0).round().clamp(1, 9999);

    final trafficFactor = _calculateElSalvadorTrafficFactor(
      start: start,
      destination: destination,
      trafficLayerActive: trafficEnabled,
    );
    final effectiveMinutes = (baseMinutes * trafficFactor).round().clamp(1, 9999);
    final delayMinutes = effectiveMinutes - baseMinutes;
    final level = _evaluateTrafficLevel(
      baseSeconds: baseMinutes * 60,
      delayMinutes: delayMinutes,
    );

    return TacticalRouteResult(
      points: [start, destination],
      distanceKm: estimatedRoadKm,
      baseDuration: Duration(minutes: baseMinutes),
      estimatedDuration: Duration(minutes: effectiveMinutes),
      trafficDelayMinutes: delayMinutes,
      trafficLevel: level,
      trafficConditionText: _trafficConditionDescription(level, delayMinutes),
      isRealRoute: false,
    );
  }

  /// Modelo Dinámico de Tráfico Vehicular para El Salvador (Zona Horaria UTC-6)
  static double _calculateElSalvadorTrafficFactor({
    required LatLng start,
    required LatLng destination,
    required bool trafficLayerActive,
  }) {
    final svTime = DateTime.now().toUtc().subtract(const Duration(hours: 6));
    final hour = svTime.hour;
    final minute = svTime.minute;
    final weekday = svTime.weekday; // 1 = Lunes, 7 = Domingo
    final timeDec = hour + (minute / 60.0);

    // ¿Ruta atraviesa el Área Metropolitana de San Salvador (AMSS)?
    final inAmss = (start.latitude >= 13.63 && start.latitude <= 13.76 &&
            start.longitude >= -89.32 && start.longitude <= -89.13) ||
        (destination.latitude >= 13.63 && destination.latitude <= 13.76 &&
            destination.longitude >= -89.32 && destination.longitude <= -89.13);

    // ¿Ruta hacia/desde Surf City / La Libertad?
    final isBeachCorridor = (start.latitude <= 13.55 || destination.latitude <= 13.55);

    double factor = 1.05;

    if (weekday >= 1 && weekday <= 5) {
      // DÍAS LABORABLES (Lunes a Viernes)
      if (timeDec >= 6.5 && timeDec <= 8.75) {
        // Hora pico matutina (6:30 AM - 8:45 AM)
        factor = inAmss ? 1.55 : 1.30;
      } else if (timeDec >= 11.75 && timeDec <= 13.5) {
        // Almuerzo (11:45 AM - 1:30 PM)
        factor = inAmss ? 1.25 : 1.15;
      } else if (timeDec >= 16.5 && timeDec <= 19.5) {
        // Hora pico vespertina (4:30 PM - 7:30 PM)
        factor = inAmss ? 1.60 : 1.35;
      } else if (timeDec >= 8.75 && timeDec <= 16.5) {
        // Horas diurnas estándar
        factor = inAmss ? 1.18 : 1.10;
      } else {
        // Noche / Madrugada
        factor = 1.02;
      }
    } else if (weekday == 6) {
      // SÁBADOS
      if (timeDec >= 10.5 && timeDec <= 14.5) {
        factor = inAmss ? 1.35 : 1.20;
      } else if (isBeachCorridor && timeDec >= 9.0 && timeDec <= 14.0) {
        factor = 1.40;
      } else {
        factor = 1.10;
      }
    } else {
      // DOMINGOS
      if (isBeachCorridor && timeDec >= 15.5 && timeDec <= 19.5) {
        factor = 1.45;
      } else if (timeDec >= 16.0 && timeDec <= 19.0 && inAmss) {
        factor = 1.20;
      } else {
        factor = 1.05;
      }
    }

    if (trafficLayerActive && factor == 1.05) {
      factor = 1.08;
    }

    return factor;
  }

  static TrafficCongestionLevel _evaluateTrafficLevel({
    required int baseSeconds,
    required int delayMinutes,
  }) {
    if (delayMinutes <= 2) {
      return TrafficCongestionLevel.freeFlow;
    } else if (delayMinutes <= 9) {
      return TrafficCongestionLevel.moderate;
    } else {
      return TrafficCongestionLevel.heavy;
    }
  }

  static String _trafficConditionDescription(
    TrafficCongestionLevel level,
    int delayMinutes,
  ) {
    switch (level) {
      case TrafficCongestionLevel.freeFlow:
        return 'Flujo Libre';
      case TrafficCongestionLevel.moderate:
        return delayMinutes > 0
            ? 'Tráfico Moderado (+$delayMinutes min)'
            : 'Tráfico Moderado';
      case TrafficCongestionLevel.heavy:
        return delayMinutes > 0
            ? 'Tráfico Lento (+$delayMinutes min)'
            : 'Tráfico Lento';
    }
  }
}

/// Nivel de congestión del tráfico vehicular
enum TrafficCongestionLevel {
  freeFlow, // Flujo Libre (Verde)
  moderate, // Tráfico Moderado (Ámbar / Naranja)
  heavy, // Tráfico Lento / Congestión (Rojo)
}

/// Resultado del cálculo de ruta con análisis de tráfico
class TacticalRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final Duration estimatedDuration; // Tiempo estimado considerando tráfico
  final Duration baseDuration; // Tiempo ideal sin tráfico
  final int trafficDelayMinutes; // Minutos adicionales por congestión
  final TrafficCongestionLevel trafficLevel;
  final String trafficConditionText;
  final bool isRealRoute;

  const TacticalRouteResult({
    required this.points,
    required this.distanceKm,
    required this.estimatedDuration,
    required this.baseDuration,
    this.trafficDelayMinutes = 0,
    this.trafficLevel = TrafficCongestionLevel.freeFlow,
    this.trafficConditionText = 'Flujo Libre',
    required this.isRealRoute,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';

  String get formattedDuration {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '$minutes min';
  }

  String get formattedTrafficDuration {
    final hours = estimatedDuration.inHours;
    final minutes = estimatedDuration.inMinutes % 60;
    final timeStr = hours > 0 ? '${hours}h ${minutes}m' : '$minutes min';
    if (trafficDelayMinutes > 0) {
      return '$timeStr ($trafficLevelLabel)';
    }
    return '$timeStr (flujo libre)';
  }

  String get trafficLevelLabel {
    switch (trafficLevel) {
      case TrafficCongestionLevel.freeFlow:
        return 'Flujo Libre';
      case TrafficCongestionLevel.moderate:
        return 'Tráfico Moderado';
      case TrafficCongestionLevel.heavy:
        return 'Tráfico Lento';
    }
  }

  Color get trafficColor {
    switch (trafficLevel) {
      case TrafficCongestionLevel.freeFlow:
        return const Color(0xFF2ECC71); // Verde esmeralda (#2ECC71)
      case TrafficCongestionLevel.moderate:
        return const Color(0xFFF39C12); // Ámbar / Naranja dorado (#F39C12)
      case TrafficCongestionLevel.heavy:
        return const Color(0xFFE74C3C); // Rojo carmesí (#E74C3C)
    }
  }
}

