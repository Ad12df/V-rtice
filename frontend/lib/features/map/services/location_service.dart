import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de Punto de Interés Táctico / Turismo en El Salvador
class TacticalPoi {
  final String id;
  final String name;
  final String category;
  final LatLng location;
  final String description;
  final String difficulty;
  final IconData icon;
  final bool isCustom;

  const TacticalPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.difficulty,
    required this.icon,
    this.isCustom = false,
  });

  factory TacticalPoi.fromSupabase(Map<String, dynamic> json) {
    // Manejo de coordenadas: puede venir de la función RPC (lat/lng numéricos)
    // o de la columna PostGIS Geography
    double lat = 13.7942;
    double lng = -88.8965;

    if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else if (json['location'] != null && json['location'] is Map) {
      final locMap = json['location'] as Map<String, dynamic>;
      if (locMap['coordinates'] != null && locMap['coordinates'] is List) {
        final coords = locMap['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
    }

    final category = (json['category'] as String?) ?? 'ATALAYA TURÍSTICA';

    return TacticalPoi(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      name: (json['name'] as String?) ?? 'Punto Táctico',
      category: category,
      location: LatLng(lat, lng),
      description: (json['description'] as String?) ??
          'Punto de interés turístico en El Salvador.',
      difficulty: (json['difficulty'] as String?) ?? 'MEDIA',
      icon: _getIconForCategory(category),
      isCustom: false,
    );
  }

  static IconData _getIconForCategory(String category) {
    final catUpper = category.toUpperCase();
    if (catUpper.contains('NATURAL') || catUpper.contains('VOLCÁN')) {
      return Icons.terrain_rounded;
    } else if (catUpper.contains('ARQUEOLÓGICA') || catUpper.contains('MAYA')) {
      return Icons.account_balance_rounded;
    } else if (catUpper.contains('URBANO') || catUpper.contains('CIUDAD')) {
      return Icons.location_city_rounded;
    } else if (catUpper.contains('COSTERO') || catUpper.contains('PLAYA')) {
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
}

/// Servicio para consultar ubicaciones y atalayas turísticas desde Supabase
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Semillas de respaldo si no hay conexión o la base de datos está cargando
  static const List<TacticalPoi> defaultPois = [
    TacticalPoi(
      id: 'volcan-santa-ana',
      name: 'Volcán de Santa Ana (Ilamatepec)',
      category: 'ATALAYA NATURAL',
      location: LatLng(13.8533, -89.6300),
      description:
          'Cráter activo a 2,381 msnm con laguna esmeralda. Punto estratégico para disipar niebla en el occidente.',
      difficulty: 'ALTA',
      icon: Icons.terrain_rounded,
    ),
    TacticalPoi(
      id: 'tazumal',
      name: 'Ruinas de Tazumal',
      category: 'ZONA ARQUEOLÓGICA',
      location: LatLng(13.9794, -89.6744),
      description:
          'Complejo ceremonial maya con pirámide escalonada de 24 metros y reliquias de jade.',
      difficulty: 'MEDIA',
      icon: Icons.account_balance_rounded,
    ),
    TacticalPoi(
      id: 'centro-historico',
      name: 'Centro Histórico de San Salvador',
      category: 'NÚCLEO URBANO',
      location: LatLng(13.6983, -89.1914),
      description:
          'Epicentro cultural: Palacio Nacional, Teatro Nacional y Catedral Metropolitana.',
      difficulty: 'BAJA',
      icon: Icons.location_city_rounded,
    ),
    TacticalPoi(
      id: 'el-tunco',
      name: 'Playa El Tunco (Surf City)',
      category: 'SECTOR COSTERO',
      location: LatLng(13.4939, -89.3853),
      description:
          'Costa del Pacífico reconocida mundialmente por sus olas clase élite y atardeceres volcánicos.',
      difficulty: 'BAJA',
      icon: Icons.waves_rounded,
    ),
    TacticalPoi(
      id: 'el-imposible',
      name: 'Parque Nacional El Imposible',
      category: 'RESERVA DE SELVA',
      location: LatLng(13.8292, -89.9392),
      description:
          'Bosque tropical primario con desfiladeros escarpados, cascadas ocultas y biodiversidad endémica.',
      difficulty: 'ÉPICA',
      icon: Icons.forest_rounded,
    ),
    TacticalPoi(
      id: 'coatepeque',
      name: 'Lago de Coatepeque',
      category: 'CRÁTER ACUÁTICO',
      location: LatLng(13.8697, -89.5517),
      description:
          'Lago de origen volcánico con aguas turquesas rodeado de miradores y senderos náuticos.',
      difficulty: 'MEDIA',
      icon: Icons.water_rounded,
    ),
    TacticalPoi(
      id: 'suchitoto',
      name: 'Suchitoto (Ciudad Colonial)',
      category: 'PATRIMONIO HISTÓRICO',
      location: LatLng(13.9378, -89.0278),
      description:
          'Joyel histórico con calles empedradas, arquitectura colonial y vistas panorámicas al Lago Suchitlán.',
      difficulty: 'BAJA',
      icon: Icons.museum_rounded,
    ),
    TacticalPoi(
      id: 'puerta-del-diablo',
      name: 'La Puerta del Diablo',
      category: 'MIRADOR TÁCTICO',
      location: LatLng(13.6214, -89.1906),
      description:
          'Formación rocosa legendaria en Panchimalco con mirador de 360 grados hacia la costa y volcanes.',
      difficulty: 'MEDIA',
      icon: Icons.explore_rounded,
    ),
  ];

  /// Obtiene la lista de todas las ubicaciones desde Supabase
  Future<List<TacticalPoi>> fetchLocations() async {
    try {
      // 1. Intentar primero con la función RPC que ya entrega lat y lng separados
      try {
        final response = await _supabase.rpc('get_all_locations');
        if (response != null && response is List && response.isNotEmpty) {
          return response
              .map((item) =>
                  TacticalPoi.fromSupabase(item as Map<String, dynamic>))
              .toList();
        }
      } catch (rpcError) {
        debugPrint('ℹ️ [LocationService] RPC get_all_locations fallback: $rpcError');
      }

      // 2. Fallback a consulta directa sobre la tabla locations
      final data = await _supabase
          .from('locations')
          .select('id, name, description, category, difficulty, created_at');

      if (data.isNotEmpty) {
        // Asignar coordenadas predeterminadas conocidas si la consulta REST no desempaqueta PostGIS
        final List<TacticalPoi> loadedList = [];
        for (final item in data) {
          final matchedDefault = defaultPois.firstWhere(
            (p) => p.name.toLowerCase() == (item['name'] as String? ?? '').toLowerCase(),
            orElse: () => TacticalPoi.fromSupabase(item),
          );

          loadedList.add(TacticalPoi(
            id: item['id'] as String? ?? matchedDefault.id,
            name: item['name'] as String? ?? matchedDefault.name,
            category: item['category'] as String? ?? matchedDefault.category,
            location: matchedDefault.location,
            description: item['description'] as String? ?? matchedDefault.description,
            difficulty: item['difficulty'] as String? ?? matchedDefault.difficulty,
            icon: TacticalPoi._getIconForCategory(item['category'] as String? ?? ''),
            isCustom: false,
          ));
        }
        return loadedList;
      }

      return defaultPois;
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al cargar ubicaciones desde Supabase: $e');
      return defaultPois;
    }
  }
}
