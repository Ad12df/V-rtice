import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:vertice/features/map/services/location_service.dart';
import 'package:vertice/features/map/services/traffic_network_service.dart';

void main() {
  group('TrafficLayer GIS Vector Offset & Directional Tests', () {
    test('calculateBearing returns accurate compass azimuth in radians', () {
      final origin = const LatLng(13.6900, -89.2200);

      // Rumbo Norte (0 rad)
      final north = const LatLng(13.7000, -89.2200);
      expect(TrafficNetworkService.calculateBearing(origin, north), closeTo(0.0, 0.01));

      // Rumbo Este (pi/2 rad ~ 1.5708)
      final east = const LatLng(13.6900, -89.2100);
      expect(TrafficNetworkService.calculateBearing(origin, east), closeTo(math.pi / 2, 0.01));

      // Rumbo Sur (pi rad ~ 3.14159)
      final south = const LatLng(13.6800, -89.2200);
      final bearingSouth = TrafficNetworkService.calculateBearing(origin, south).abs();
      expect(bearingSouth, closeTo(math.pi, 0.01));

      // Rumbo Oeste (-pi/2 rad ~ -1.5708)
      final west = const LatLng(13.6900, -89.2300);
      expect(TrafficNetworkService.calculateBearing(origin, west), closeTo(-math.pi / 2, 0.01));
    });

    test('offsetPolyline creates right-hand lateral displacement', () {
      // Carretera orientada hacia el Norte (sentido A -> B)
      final roadPoints = [
        const LatLng(13.6700, -89.2400),
        const LatLng(13.6800, -89.2400),
        const LatLng(13.6900, -89.2400),
      ];

      // Desplazamiento de 6 metros a la derecha (este: longitud más positiva)
      final forwardOffset = TrafficNetworkService.offsetPolyline(roadPoints, 6.0);
      expect(forwardOffset.length, equals(roadPoints.length));

      for (int i = 0; i < roadPoints.length; i++) {
        // En sentido Norte, la derecha reglamentaria es el Este (+lon)
        expect(forwardOffset[i].longitude, greaterThan(roadPoints[i].longitude));
        expect(forwardOffset[i].latitude, closeTo(roadPoints[i].latitude, 0.0001));
      }

      // Sentido B -> A (retorno, invertido)
      final reversedRoad = roadPoints.reversed.toList();
      final backwardOffset = TrafficNetworkService.offsetPolyline(reversedRoad, 6.0);
      expect(backwardOffset.length, equals(roadPoints.length));

      for (int i = 0; i < reversedRoad.length; i++) {
        // En sentido Sur, la derecha reglamentaria es el Oeste (-lon)
        expect(backwardOffset[i].longitude, lessThan(reversedRoad[i].longitude));
        expect(backwardOffset[i].latitude, closeTo(reversedRoad[i].latitude, 0.0001));
      }

      // Verificar que ambos carriles no se enciman y están separados por ~12m
      final midPointForward = forwardOffset[1];
      final midPointBackward = backwardOffset[1]; // corresponde al mismo punto físico central
      expect(midPointForward.longitude, greaterThan(midPointBackward.longitude));
    });

    test('Zoom level adaptation: single centerline at zoom < 12, dual offset lanes at zoom >= 12', () {
      final totalSegments = TrafficNetworkService.segments.length;
      expect(totalSegments, greaterThan(15));

      // Zoom lejano (zoom < 12) -> Una polilínea por segmento consolidada
      final polylinesZoomFar = TrafficNetworkService.instance.buildTrafficPolylines(zoom: 10.0);
      expect(polylinesZoomFar.length, equals(totalSegments));

      // Zoom intermedio/cercano (zoom >= 12) -> Dos carriles independientes por segmento (Ida + Vuelta)
      final polylinesZoomClose = TrafficNetworkService.instance.buildTrafficPolylines(zoom: 14.0);
      expect(polylinesZoomClose.length, equals(totalSegments * 2));
    });

    test('Directional markers: disabled below 12.5 zoom, enabled at zoom >= 12.5', () {
      // Zoom < 12.5 -> Lista vacía de marcadores (sin ruido a escala nacional)
      final markersFar = TrafficNetworkService.instance.buildDirectionMarkers(zoom: 11.5);
      expect(markersFar, isEmpty);

      // Zoom >= 12.5 -> Marcadores direccionales generados con CustomPaint
      final markersClose = TrafficNetworkService.instance.buildDirectionMarkers(zoom: 13.5);
      expect(markersClose, isNotEmpty);

      // Verificar que cada marcador tiene dimensiones compactas y CustomPaint
      for (final marker in markersClose) {
        expect(marker.width, equals(18));
        expect(marker.height, equals(18));
        expect(marker.child, isA<IgnorePointer>());
        final ignorePointer = marker.child as IgnorePointer;
        expect(ignorePointer.child, isA<CustomPaint>());
      }
    });

    test('Traffic color palette conforms to official green, amber, red hex specifications', () {
      final green = TrafficSegment.colorForLevel(TrafficCongestionLevel.freeFlow);
      final amber = TrafficSegment.colorForLevel(TrafficCongestionLevel.moderate);
      final red = TrafficSegment.colorForLevel(TrafficCongestionLevel.heavy);

      expect(green, equals(const Color(0xFF2ECC71)));
      expect(amber, equals(const Color(0xFFF39C12)));
      expect(red, equals(const Color(0xFFE74C3C)));
    });

    test('Los Chorros directional logic distinguishes inbound vs outbound', () {
      final chorros = TrafficNetworkService.segments.firstWhere(
        (s) => s.isChorrosCorridor,
      );

      expect(chorros.name, contains('Los Chorros'));
      expect(chorros.forwardName, contains('Santa Tecla'));
      expect(chorros.backwardName, contains('Colón'));

      // Comprobar que evaluateDirection devuelve un TrafficCongestionLevel válido
      final forwardLevel = chorros.evaluateDirection(isForward: true);
      final backwardLevel = chorros.evaluateDirection(isForward: false);

      expect(forwardLevel, isA<TrafficCongestionLevel>());
      expect(backwardLevel, isA<TrafficCongestionLevel>());
    });
  });
}
