import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:vertice/features/map/services/location_service.dart';

/// Clasificación de corredor vial para calibrar el comportamiento direccional
enum TrafficCorridorType {
  /// Paso Los Chorros (CA-1 Occidente): Inbound AM a SS, Outbound PM a Lourdes/Colón
  chorros,

  /// Corredor Surf City / Carretera al Puerto (CA-2): Éxodo fin de semana y retorno domingo
  beachSurfCity,

  /// Arterias radiales de la capital (Monseñor Romero, Comalapa, Ejército, Constitución)
  urbanRadial,

  /// Ejes del núcleo metropolitano (Próceres, Héroes, Alameda Roosevelt, Paseo Escalón)
  urbanCore,

  /// Carreteras interdepartamentales e internacionales (CA-1 Oriente/Occidente, Litoral, Ruta Flores)
  interstate,
}

/// Representa un segmento de vía bidireccional con cálculo de congestión direccional independiente
class TrafficSegment {
  final String name;
  final String forwardName;
  final String backwardName;
  final List<LatLng> coordinates;
  final TrafficCorridorType corridorType;
  final bool isUrbanCore;
  final bool isBeachCorridor;
  final bool isChorrosCorridor;

  const TrafficSegment({
    required this.name,
    required this.coordinates,
    this.forwardName = 'Sentido A -> B',
    this.backwardName = 'Sentido B -> A',
    this.corridorType = TrafficCorridorType.urbanCore,
    this.isUrbanCore = false,
    this.isBeachCorridor = false,
    this.isChorrosCorridor = false,
  });

  /// Evalúa el nivel de tráfico según la dirección de flujo (isForward: A->B vs B->A)
  /// y la hora local de El Salvador (UTC-6)
  TrafficCongestionLevel evaluateDirection({required bool isForward}) {
    final svTime = DateTime.now().toUtc().subtract(const Duration(hours: 6));
    final hour = svTime.hour;
    final minute = svTime.minute;
    final weekday = svTime.weekday; // 1 = Lunes, 7 = Domingo
    final timeDec = hour + (minute / 60.0);

    // 1. Corredor Los Chorros (Colón <-> Santa Tecla)
    // Coordenadas: A (Colón/Lourdes) -> B (Santa Tecla/Las Delicias)
    // isForward: Colón -> Santa Tecla (Entrada a SS)
    // !isForward: Santa Tecla -> Colón (Salida a Occidente)
    if (corridorType == TrafficCorridorType.chorros || isChorrosCorridor) {
      if (weekday >= 1 && weekday <= 5) {
        if (isForward) {
          // Mañana: Influx masivo de trabajadores hacia San Salvador
          if (timeDec >= 5.5 && timeDec <= 9.25) return TrafficCongestionLevel.heavy;
          if (timeDec >= 11.5 && timeDec <= 14.0) return TrafficCongestionLevel.moderate;
          return TrafficCongestionLevel.freeFlow;
        } else {
          // Tarde/Noche: Éxodo masivo de regreso hacia Colón/Lourdes/Santa Ana
          if (timeDec >= 16.5 && timeDec <= 20.5) return TrafficCongestionLevel.heavy;
          if (timeDec >= 12.0 && timeDec <= 14.5) return TrafficCongestionLevel.moderate;
          return TrafficCongestionLevel.freeFlow;
        }
      } else if (weekday == 6) {
        // Sábado mediodía retorno
        if (!isForward && timeDec >= 11.5 && timeDec <= 15.0) {
          return TrafficCongestionLevel.heavy;
        }
        return TrafficCongestionLevel.moderate;
      }
      return TrafficCongestionLevel.moderate;
    }

    // 2. Corredor Surf City / Carretera al Puerto de La Libertad (CA-2)
    // Coordenadas: A (Santa Tecla) -> B (Puerto La Libertad)
    // isForward: Hacia la costa / Surf City
    // !isForward: Hacia Santa Tecla / San Salvador (Retorno)
    if (corridorType == TrafficCorridorType.beachSurfCity || isBeachCorridor) {
      if (weekday == 7) {
        // Domingo
        if (!isForward && timeDec >= 14.5 && timeDec <= 20.5) {
          // Retorno masivo de veraneantes hacia San Salvador
          return TrafficCongestionLevel.heavy;
        }
        if (isForward && timeDec >= 9.0 && timeDec <= 13.0) {
          // Flujo hacia playas
          return TrafficCongestionLevel.moderate;
        }
        return TrafficCongestionLevel.freeFlow;
      }
      if (weekday == 6) {
        // Sábado
        if (isForward && timeDec >= 9.5 && timeDec <= 14.5) {
          return TrafficCongestionLevel.moderate;
        }
        if (!isForward && timeDec >= 16.5 && timeDec <= 19.5) {
          return TrafficCongestionLevel.moderate;
        }
        return TrafficCongestionLevel.freeFlow;
      }
      // Días de semana
      if (timeDec >= 17.0 && timeDec <= 19.5) {
        return isForward ? TrafficCongestionLevel.moderate : TrafficCongestionLevel.freeFlow;
      }
      return TrafficCongestionLevel.freeFlow;
    }

    // 3. Arterias radiales de San Salvador (Monseñor Romero, Comalapa, Ejército, Constitución)
    // La mayoría trazadas desde el centro hacia afuera o periferia
    if (corridorType == TrafficCorridorType.urbanRadial) {
      if (weekday >= 1 && weekday <= 5) {
        // Horas pico matutinas (Entrada al centro metropolitano)
        if (timeDec >= 6.25 && timeDec <= 9.0) {
          return isForward ? TrafficCongestionLevel.freeFlow : TrafficCongestionLevel.heavy;
        }
        // Horas pico vespertinas (Salida hacia municipios dormitorios)
        if (timeDec >= 16.5 && timeDec <= 19.75) {
          return isForward ? TrafficCongestionLevel.heavy : TrafficCongestionLevel.freeFlow;
        }
        if (timeDec >= 11.5 && timeDec <= 14.0) {
          return TrafficCongestionLevel.moderate;
        }
      }
      return TrafficCongestionLevel.freeFlow;
    }

    // 4. Corredores urbanos densos (Héroes, Manuel Enrique Araujo, Roosevelt, Escalón)
    if (corridorType == TrafficCorridorType.urbanCore || isUrbanCore) {
      if (weekday >= 1 && weekday <= 5) {
        if (timeDec >= 6.5 && timeDec <= 9.0) return TrafficCongestionLevel.heavy;
        if (timeDec >= 11.5 && timeDec <= 13.75) return TrafficCongestionLevel.moderate;
        if (timeDec >= 16.75 && timeDec <= 19.5) return TrafficCongestionLevel.heavy;
        if (timeDec >= 9.0 && timeDec <= 16.75) return TrafficCongestionLevel.moderate;
      } else if (weekday == 6 && timeDec >= 10.5 && timeDec <= 15.0) {
        return TrafficCongestionLevel.moderate;
      }
      return TrafficCongestionLevel.freeFlow;
    }

    // 5. Carreteras interdepartamentales
    if (weekday >= 1 && weekday <= 5 && timeDec >= 7.0 && timeDec <= 17.5) {
      return TrafficCongestionLevel.moderate;
    }
    return TrafficCongestionLevel.freeFlow;
  }

  /// Nivel máximo entre ambos sentidos (para vista consolidada a zoom < 12)
  TrafficCongestionLevel getCurrentTrafficLevel() {
    final forward = evaluateDirection(isForward: true);
    final backward = evaluateDirection(isForward: false);
    if (forward == TrafficCongestionLevel.heavy || backward == TrafficCongestionLevel.heavy) {
      return TrafficCongestionLevel.heavy;
    }
    if (forward == TrafficCongestionLevel.moderate || backward == TrafficCongestionLevel.moderate) {
      return TrafficCongestionLevel.moderate;
    }
    return TrafficCongestionLevel.freeFlow;
  }

  /// Color para el sentido de flujo especificado
  Color getColor({required bool isForward}) {
    return colorForLevel(evaluateDirection(isForward: isForward));
  }

  /// Color consolidado para vista lejana
  Color get currentColor => colorForLevel(getCurrentTrafficLevel());

  /// Paleta oficial de flujo vehicular
  static Color colorForLevel(TrafficCongestionLevel level) {
    switch (level) {
      case TrafficCongestionLevel.freeFlow:
        return const Color(0xFF2ECC71); // Verde Esmeralda (#2ECC71)
      case TrafficCongestionLevel.moderate:
        return const Color(0xFFF39C12); // Ámbar (#F39C12)
      case TrafficCongestionLevel.heavy:
        return const Color(0xFFE74C3C); // Rojo Carmesí (#E74C3C)
    }
  }
}

/// Pintor de alto rendimiento para chevrons direccionales orientados por el rumbo del carril
class DirectionalArrowPainter extends CustomPainter {
  final Color color;
  final double angleRad;

  const DirectionalArrowPainter({
    required this.color,
    required this.angleRad,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(angleRad);

    // Contorno oscuro para alto contraste sobre fondo oscuro, claro o satelital
    final borderPaint = Paint()
      ..color = const Color(0xCC000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Chevron aerodinámico apuntando al Norte (eje -Y en canvas)
    final path = Path()
      ..moveTo(0, -5.5)
      ..lineTo(4.5, 4.2)
      ..lineTo(0, 1.8)
      ..lineTo(-4.5, 4.2)
      ..close();

    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, fillPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DirectionalArrowPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.angleRad != angleRad;
}

/// Servicio que gestiona la red vial y genera las geometrías con desplazamiento lateral
/// perpendicular (offset geodésico) e indicadores de sentido direccional
class TrafficNetworkService {
  TrafficNetworkService._();
  static final TrafficNetworkService instance = TrafficNetworkService._();

  /// Desplaza perpendicularmente una polilínea hacia la derecha según su sentido de avance
  /// usando proyección geodésica local y cálculo de normales con límite de inglete (miter limit).
  static List<LatLng> offsetPolyline(List<LatLng> points, double offsetMeters) {
    if (points.length < 2) return List.from(points);

    const double metersPerDegreeLat = 111139.0;
    final List<Offset> segmentNormals = [];

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final latMidRad = (p1.latitude + p2.latitude) / 2 * (math.pi / 180.0);
      final metersPerDegreeLon = metersPerDegreeLat * math.cos(latMidRad);

      final dy = (p2.latitude - p1.latitude) * metersPerDegreeLat;
      final dx = (p2.longitude - p1.longitude) * metersPerDegreeLon;
      final len = math.sqrt(dx * dx + dy * dy);

      if (len < 1e-6) {
        segmentNormals.add(Offset.zero);
      } else {
        final ux = dx / len;
        final uy = dy / len;
        // Normal perpendicular a la derecha (giro 90° horario): (uy, -ux)
        segmentNormals.add(Offset(uy, -ux));
      }
    }

    final List<LatLng> result = [];
    for (int i = 0; i < points.length; i++) {
      Offset normal;
      if (i == 0) {
        normal = segmentNormals[0];
      } else if (i == points.length - 1) {
        normal = segmentNormals[points.length - 2];
      } else {
        final n1 = segmentNormals[i - 1];
        final n2 = segmentNormals[i];
        final avgX = (n1.dx + n2.dx) / 2.0;
        final avgY = (n1.dy + n2.dy) / 2.0;
        final len = math.sqrt(avgX * avgX + avgY * avgY);

        if (len < 1e-4) {
          normal = n1;
        } else {
          final unitAvgX = avgX / len;
          final unitAvgY = avgY / len;
          final miterFactor = (1.0 / len).clamp(1.0, 1.75);
          normal = Offset(unitAvgX * miterFactor, unitAvgY * miterFactor);
        }
      }

      final latRad = points[i].latitude * (math.pi / 180.0);
      final metersPerDegreeLon = metersPerDegreeLat * math.cos(latRad);

      final deltaLat = (normal.dy * offsetMeters) / metersPerDegreeLat;
      final deltaLon = (normal.dx * offsetMeters) / metersPerDegreeLon;

      result.add(LatLng(
        points[i].latitude + deltaLat,
        points[i].longitude + deltaLon,
      ));
    }

    return result;
  }

  /// Calcula el ángulo de azimut (bearing) en radianes de un segmento p1 -> p2
  static double calculateBearing(LatLng p1, LatLng p2) {
    const double metersPerDegreeLat = 111139.0;
    final latMidRad = (p1.latitude + p2.latitude) / 2 * (math.pi / 180.0);
    final metersPerDegreeLon = metersPerDegreeLat * math.cos(latMidRad);

    final dy = (p2.latitude - p1.latitude) * metersPerDegreeLat;
    final dx = (p2.longitude - p1.longitude) * metersPerDegreeLon;

    return math.atan2(dx, dy);
  }

  /// Definición geométrica canónica de los principales corredores viales de El Salvador
  static final List<TrafficSegment> segments = [
    // ─── AMSS / SAN SALVADOR (ÁREA METROPOLITANA) ───────────────────────────
    const TrafficSegment(
      name: 'Los Chorros (CA-1 Occidente)',
      forwardName: 'Hacia Santa Tecla / San Salvador',
      backwardName: 'Hacia Colón / Lourdes / Occidente',
      corridorType: TrafficCorridorType.chorros,
      isChorrosCorridor: true,
      coordinates: [
        LatLng(13.7050, -89.3300), // Colón / Lourdes
        LatLng(13.6950, -89.3150),
        LatLng(13.6820, -89.3000),
        LatLng(13.6750, -89.2880), // Santa Tecla (Las Delicias)
      ],
    ),
    const TrafficSegment(
      name: 'Bulevar Monseñor Romero',
      forwardName: 'Hacia Santa Tecla / Occidente',
      backwardName: 'Hacia San Salvador / Próceres',
      corridorType: TrafficCorridorType.urbanRadial,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6860, -89.2420), // Próceres / Masferrer
        LatLng(13.6835, -89.2520),
        LatLng(13.6800, -89.2680),
        LatLng(13.6750, -89.2880), // Santa Tecla
      ],
    ),
    const TrafficSegment(
      name: 'Bulevar Los Próceres & Árbol de la Paz',
      forwardName: 'Hacia San Salvador Centro',
      backwardName: 'Hacia Santa Tecla',
      corridorType: TrafficCorridorType.urbanCore,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6860, -89.2420),
        LatLng(13.6840, -89.2320),
        LatLng(13.6880, -89.2220),
      ],
    ),
    const TrafficSegment(
      name: 'Bulevar de Los Héroes',
      forwardName: 'Hacia Universidad / Norte',
      backwardName: 'Hacia Estadio Cuscatlán / Sur',
      corridorType: TrafficCorridorType.urbanCore,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6880, -89.2220),
        LatLng(13.6980, -89.2190),
        LatLng(13.7050, -89.2150),
        LatLng(13.7180, -89.2080),
      ],
    ),
    const TrafficSegment(
      name: 'Alameda Manuel Enrique Araujo & Roosevelt',
      forwardName: 'Hacia Centro Histórico',
      backwardName: 'Hacia Salvador del Mundo / Poniente',
      corridorType: TrafficCorridorType.urbanCore,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6860, -89.2420),
        LatLng(13.6930, -89.2340),
        LatLng(13.7015, -89.2240), // Salvador del Mundo
        LatLng(13.6990, -89.2050), // Parque Cuscatlán
        LatLng(13.6980, -89.1914), // Centro Histórico
      ],
    ),
    const TrafficSegment(
      name: 'Bulevar Constitución',
      forwardName: 'Hacia Redondel Integración / Apopa',
      backwardName: 'Hacia Salvador del Mundo / Capital',
      corridorType: TrafficCorridorType.urbanRadial,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.7015, -89.2240),
        LatLng(13.7120, -89.2200),
        LatLng(13.7250, -89.2180),
        LatLng(13.7450, -89.2150),
        LatLng(13.7650, -89.2120), // Redondel Integración
      ],
    ),
    const TrafficSegment(
      name: 'Paseo General Escalón',
      forwardName: 'Hacia Salvador del Mundo',
      backwardName: 'Hacia Redoma Masferrer',
      corridorType: TrafficCorridorType.urbanCore,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.7070, -89.2480), // Redoma Masferrer
        LatLng(13.7040, -89.2360),
        LatLng(13.7015, -89.2240), // Salvador del Mundo
      ],
    ),
    const TrafficSegment(
      name: 'Autopista a Comalapa (San Salvador - Aeropuerto)',
      forwardName: 'Hacia Aeropuerto San Óscar Romero',
      backwardName: 'Hacia San Salvador Centro',
      corridorType: TrafficCorridorType.urbanRadial,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6880, -89.2220),
        LatLng(13.6550, -89.1850), // San Marcos
        LatLng(13.6350, -89.1350), // Santo Tomás
        LatLng(13.5650, -89.1150), // Olocuilta
        LatLng(13.4450, -89.0550), // Aeropuerto San Óscar Romero
      ],
    ),
    const TrafficSegment(
      name: 'Soyapango - Ilopango (Bulevar del Ejército)',
      forwardName: 'Hacia Ilopango / San Martín',
      backwardName: 'Hacia San Salvador',
      corridorType: TrafficCorridorType.urbanRadial,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.6980, -89.1800),
        LatLng(13.7000, -89.1550),
        LatLng(13.7020, -89.1200), // Cárcel de Mujeres / Ilopango
        LatLng(13.7350, -89.0550), // San Martín
      ],
    ),
    const TrafficSegment(
      name: 'Carretera Troncal del Norte (CA-4N)',
      forwardName: 'Hacia Chalatenango / Norte',
      backwardName: 'Hacia San Salvador',
      corridorType: TrafficCorridorType.urbanRadial,
      isUrbanCore: true,
      coordinates: [
        LatLng(13.7180, -89.1950),
        LatLng(13.7350, -89.1850), // Ciudad Delgado
        LatLng(13.8050, -89.1800), // Apopa
        LatLng(13.9550, -89.1900), // Aguilares
        LatLng(14.0500, -89.1600),
        LatLng(14.1500, -89.1200), // Tejutla / Chalatenango
      ],
    ),

    // ─── SURF CITY & CORREDOR COSTERO (CA-2) ───────────────────────────────
    const TrafficSegment(
      name: 'Carretera al Puerto de La Libertad / Bypass Surf City',
      forwardName: 'Hacia Puerto La Libertad / Playas',
      backwardName: 'Hacia Santa Tecla / San Salvador',
      corridorType: TrafficCorridorType.beachSurfCity,
      isBeachCorridor: true,
      coordinates: [
        LatLng(13.6750, -89.2880), // Santa Tecla
        LatLng(13.5900, -89.2880), // Zaragoza
        LatLng(13.5150, -89.2950), // Redondel Surf City
        LatLng(13.4880, -89.3180), // Puerto de La Libertad
      ],
    ),
    const TrafficSegment(
      name: 'Litoral Surf City (Puerto de La Libertad - El Tunco - El Zonte)',
      forwardName: 'Hacia Mizata / Poniente',
      backwardName: 'Hacia Puerto de La Libertad / Oriente',
      corridorType: TrafficCorridorType.beachSurfCity,
      isBeachCorridor: true,
      coordinates: [
        LatLng(13.4880, -89.3180), // La Libertad
        LatLng(13.4930, -89.3820), // El Tunco
        LatLng(13.4920, -89.3900), // El Sunzal
        LatLng(13.4950, -89.4400), // El Zonte
        LatLng(13.5100, -89.5200), // Mizata
      ],
    ),
    const TrafficSegment(
      name: 'Litoral Oriente (La Libertad - San Luis Talpa - Costa del Sol)',
      forwardName: 'Hacia Costa del Sol / Zacatecoluca',
      backwardName: 'Hacia Puerto La Libertad',
      corridorType: TrafficCorridorType.beachSurfCity,
      isBeachCorridor: true,
      coordinates: [
        LatLng(13.4880, -89.3180),
        LatLng(13.4750, -89.2550), // San Diego
        LatLng(13.4250, -89.1250), // San Luis Talpa
        LatLng(13.3450, -89.0550), // Costa del Sol
        LatLng(13.3550, -88.8250), // Zacatecoluca
      ],
    ),

    // ─── CA-1 OCCIDENTE (SAN SALVADOR - SANTA ANA - FRONTERA) ───────────────
    const TrafficSegment(
      name: 'CA-1 Occidente (Colón - Ciudad Arce - El Congo)',
      forwardName: 'Hacia Santa Ana / Occidente',
      backwardName: 'Hacia San Salvador / Colón',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.7050, -89.3300),
        LatLng(13.7850, -89.3650), // Opico
        LatLng(13.8400, -89.4450), // Ciudad Arce
        LatLng(13.9050, -89.4950), // Coatepeque / El Congo
        LatLng(13.9780, -89.5550), // Santa Ana
      ],
    ),
    const TrafficSegment(
      name: 'CA-1 Santa Ana - Chalchuapa - Ahuachapán',
      forwardName: 'Hacia Ahuachapán / Frontera',
      backwardName: 'Hacia Santa Ana',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.9780, -89.5550),
        LatLng(13.9867, -89.6800), // Chalchuapa
        LatLng(13.9922, -89.8450), // Ahuachapán
      ],
    ),

    // ─── RUTA DE LAS FLORES & SONSONATE (CA-8 & CA-12) ─────────────────────
    const TrafficSegment(
      name: 'Ruta de Las Flores (Sonsonate - Juayúa - Apaneca - Ahuachapán)',
      forwardName: 'Hacia Ahuachapán',
      backwardName: 'Hacia Sonsonate',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.7180, -89.7250), // Sonsonate
        LatLng(13.7850, -89.7350), // Salcoatitán
        LatLng(13.8420, -89.7450), // Juayúa
        LatLng(13.8550, -89.8050), // Apaneca
        LatLng(13.8700, -89.8500), // Ataco
        LatLng(13.9922, -89.8450), // Ahuachapán
      ],
    ),
    const TrafficSegment(
      name: 'Carretera a Acajutla (Sonsonate - Puerto Acajutla)',
      forwardName: 'Hacia Puerto Acajutla',
      backwardName: 'Hacia Sonsonate',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.7180, -89.7250),
        LatLng(13.6550, -89.7850),
        LatLng(13.5900, -89.8300), // Puerto Acajutla
      ],
    ),

    // ─── CA-1 ORIENTE (SAN MARTÍN - COJUTEPEQUE - SAN MIGUEL) ──────────────
    const TrafficSegment(
      name: 'CA-1 Oriente (San Martín - Cojutepeque - San Vicente)',
      forwardName: 'Hacia San Vicente / Oriente',
      backwardName: 'Hacia San Salvador',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.7350, -89.0550), // San Martín
        LatLng(13.7220, -88.9350), // Cojutepeque
        LatLng(13.6850, -88.8550),
        LatLng(13.6450, -88.7850), // San Vicente
      ],
    ),
    const TrafficSegment(
      name: 'CA-1 Oriente (San Vicente - Usulután - San Miguel)',
      forwardName: 'Hacia San Miguel',
      backwardName: 'Hacia San Salvador',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.6450, -88.7850),
        LatLng(13.5650, -88.4850), // Mercedes Umaña
        LatLng(13.5350, -88.2550), // Moncagua
        LatLng(13.4800, -88.1800), // San Miguel
      ],
    ),
    const TrafficSegment(
      name: 'CA-1 Oriente (San Miguel - Santa Rosa de Lima - El Amatillo)',
      forwardName: 'Hacia Frontera El Amatillo',
      backwardName: 'Hacia San Miguel',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.4800, -88.1800),
        LatLng(13.6250, -87.8900), // Santa Rosa de Lima
        LatLng(13.5950, -87.7200), // El Amatillo
      ],
    ),
    const TrafficSegment(
      name: 'Litoral Oriente (Usulután - El Delirio - La Unión)',
      forwardName: 'Hacia Puerto de La Unión',
      backwardName: 'Hacia Usulután',
      corridorType: TrafficCorridorType.interstate,
      coordinates: [
        LatLng(13.3450, -88.4450), // Usulután
        LatLng(13.3850, -88.1950), // El Delirio
        LatLng(13.3350, -87.8450), // La Unión
      ],
    ),
  ];

  /// Genera las polilíneas de tráfico adaptadas al nivel de zoom:
  /// - zoom < 12.0: Línea única central simplificada sin saturar a escala nacional.
  /// - zoom >= 12.0: Carriles dobles paralelos desplazados lateralmente por la derecha (reglamento SV).
  List<Polyline> buildTrafficPolylines({double zoom = 14.0}) {
    if (zoom < 12.0) {
      // Vista lejana: Línea única consolidada en el eje central
      return segments.map((segment) {
        return Polyline(
          points: segment.coordinates,
          color: segment.currentColor,
          strokeWidth: 2.8,
          borderColor: const Color(0x66000000),
          borderStrokeWidth: 0.8,
        );
      }).toList();
    }

    // Offset geodésico adaptado al nivel de zoom para mantener separación visual nítida
    // A zoom 12-13 se calibra para garantizar 2-3px de separación; a zoom >= 14 se mantiene en ~5-6m reales
    final double offsetMeters = zoom >= 14.0
        ? 5.5
        : (5.5 + (14.0 - zoom) * 6.0);

    final List<Polyline> polylines = [];

    for (final segment in segments) {
      // 1. Sentido A -> B (Carril derecho hacia adelante)
      final forwardPoints = offsetPolyline(segment.coordinates, offsetMeters);
      final forwardColor = segment.getColor(isForward: true);

      polylines.add(
        Polyline(
          points: forwardPoints,
          color: forwardColor,
          strokeWidth: 3.6,
          borderColor: const Color(0x77000000),
          borderStrokeWidth: 1.0,
        ),
      );

      // 2. Sentido B -> A (Carril de retorno, invertido y desplazado a su derecha correspondiente)
      final reversedCoords = segment.coordinates.reversed.toList();
      final backwardPoints = offsetPolyline(reversedCoords, offsetMeters);
      final backwardColor = segment.getColor(isForward: false);

      polylines.add(
        Polyline(
          points: backwardPoints,
          color: backwardColor,
          strokeWidth: 3.6,
          borderColor: const Color(0x77000000),
          borderStrokeWidth: 1.0,
        ),
      );
    }

    return polylines;
  }

  /// Genera micro-marcadores con chevrons orientados según el rumbo geodésico de cada carril
  /// Se activan únicamente a zoom >= 12.5 para mantener los 60 FPS y una estética limpia.
  List<Marker> buildDirectionMarkers({required double zoom}) {
    if (zoom < 12.5) return const [];

    final double offsetMeters = zoom >= 14.0
        ? 5.5
        : (5.5 + (14.0 - zoom) * 6.0);

    final List<Marker> markers = [];

    for (final segment in segments) {
      // Marcadores para el carril A -> B
      final forwardPoints = offsetPolyline(segment.coordinates, offsetMeters);
      final forwardColor = segment.getColor(isForward: true);
      _appendMarkersForPolyline(forwardPoints, forwardColor, markers);

      // Marcadores para el carril B -> A
      final reversedCoords = segment.coordinates.reversed.toList();
      final backwardPoints = offsetPolyline(reversedCoords, offsetMeters);
      final backwardColor = segment.getColor(isForward: false);
      _appendMarkersForPolyline(backwardPoints, backwardColor, markers);
    }

    return markers;
  }

  /// Distribuye estratégicamente indicadores en puntos intermedios de los segmentos viales
  static void _appendMarkersForPolyline(
    List<LatLng> points,
    Color color,
    List<Marker> output,
  ) {
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final bearing = calculateBearing(p1, p2);

      // Punto medio del segmento
      final midLat = (p1.latitude + p2.latitude) / 2.0;
      final midLon = (p1.longitude + p2.longitude) / 2.0;
      final midPoint = LatLng(midLat, midLon);

      output.add(
        Marker(
          point: midPoint,
          width: 18,
          height: 18,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: CustomPaint(
              size: const Size(18, 18),
              painter: DirectionalArrowPainter(
                color: color,
                angleRad: bearing,
              ),
            ),
          ),
        ),
      );
    }
  }
}
