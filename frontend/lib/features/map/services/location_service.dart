import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  const TacticalPoi({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    required this.description,
    required this.difficulty,
    required this.icon,
    this.isCustom = false,
    this.department = 'San Salvador',
    this.zone = 'Zona Central',
    this.priceCategory = 'GRATUITO',
    this.entryFee = 0.00,
    this.priceRange = 'Gratis',
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

    final category = (json['category'] as String?) ?? 'ATALAYA TURÍSTICA';
    final name = (json['name'] as String?) ?? 'Punto Táctico';

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

/// Servicio singleton para consultar y gestionar ubicaciones y atalayas turísticas exclusivamente en Supabase
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Registrar un nuevo punto táctico / atalaya (Exclusivo Administradores)
  Future<TacticalPoi> addPoi(TacticalPoi poi) async {
    try {
      final wktLocation = 'POINT(${poi.location.longitude} ${poi.location.latitude})';
      final res = await _supabase.from('locations').insert({
        'name': poi.name,
        'description': poi.description,
        'category': poi.category,
        'difficulty': poi.difficulty,
        'department': poi.department,
        'zone': poi.zone,
        'price_category': poi.priceCategory,
        'entry_fee': poi.entryFee,
        'location': wktLocation,
      }).select();

      TacticalPoi savedPoi = poi;
      if (res.isNotEmpty) {
        savedPoi = TacticalPoi.fromSupabase(res.first);
      }

      // Actualizar estado local inmediatamente
      final updated = List<TacticalPoi>.from(poisNotifier.value)..add(savedPoi);
      poisNotifier.value = updated;
      return savedPoi;
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al insertar atalaya en Supabase: $e');
      final updated = List<TacticalPoi>.from(poisNotifier.value)..add(poi);
      poisNotifier.value = updated;
      return poi;
    }
  }

  /// Modificar un punto turístico existente
  Future<void> updatePoi(TacticalPoi poi) async {
    try {
      final wktLocation = 'POINT(${poi.location.longitude} ${poi.location.latitude})';
      await _supabase.from('locations').update({
        'name': poi.name,
        'description': poi.description,
        'category': poi.category,
        'difficulty': poi.difficulty,
        'department': poi.department,
        'zone': poi.zone,
        'price_category': poi.priceCategory,
        'entry_fee': poi.entryFee,
        'location': wktLocation,
      }).eq('id', poi.id);

      final updated = List<TacticalPoi>.from(poisNotifier.value);
      final index = updated.indexWhere((p) => p.id == poi.id);
      if (index != -1) {
        updated[index] = poi;
        poisNotifier.value = updated;
      }
    } catch (e) {
      debugPrint('⚠️ [LocationService] Error al actualizar atalaya en Supabase: $e');
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
      debugPrint('⚠️ [LocationService] Error al eliminar atalaya en Supabase: $e');
      final updated = List<TacticalPoi>.from(poisNotifier.value)..removeWhere((p) => p.id == id);
      poisNotifier.value = updated;
    }
  }
}
