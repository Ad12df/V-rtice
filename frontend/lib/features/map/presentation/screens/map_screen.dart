import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/constants/environment.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/screens/auth_screen.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_button.dart';
import 'package:vertice/features/auth/services/auth_service.dart';

class MapScreen extends StatefulWidget {
  final bool isGuest;

  const MapScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapboxMap? _mapboxMap;
  bool _isFogActive = true;

  // Coordenadas tácticas centrales de El Salvador
  static const double _initialLat = 13.7942;
  static const double _initialLng = -88.8965;
  static const double _initialZoom = 8.5;

  @override
  void initState() {
    super.initState();
    // Inicializar token de acceso de Mapbox
    if (Environment.mapboxAccessToken.isNotEmpty &&
        Environment.mapboxAccessToken != 'TU_MAPBOX_TOKEN_AQUI') {
      MapboxOptions.setAccessToken(Environment.mapboxAccessToken);
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;
    // Ocultar adornos por defecto para look táctico limpio
    _mapboxMap?.compass.updateSettings(CompassSettings(enabled: false));
    _mapboxMap?.scaleBar.updateSettings(ScaleBarSettings(enabled: false));
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);
    final accentColor = widget.isGuest ? AppColors.gold : AppColors.cyan;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('VÉRTICE // MAPA'),
        actions: [
          IconButton(
            tooltip: 'Cerrar Sesión',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            onPressed: () async {
              if (!widget.isGuest) {
                await AuthService().signOut();
              }
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Capa de Cartografía Interactiva Mapbox
          Positioned.fill(
            child: MapWidget(
              key: const ValueKey("tacticalMapWidget"),
              styleUri: MapboxStyles.DARK,
              viewport: CameraViewportState(
                center: Point(
                  coordinates: Position(
                    _initialLng,
                    _initialLat,
                  ),
                ),
                zoom: _initialZoom,
                bearing: 0.0, // Orientación Norte
                pitch: 0.0,
              ),
              onMapCreated: _onMapCreated,
            ),
          ),

          // 2. Cuadrícula de radar y retícula táctica sutil Animus
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TacticalOverlayPainter(accentColor: accentColor),
              ),
            ),
          ),

          // 3. Superpuestos de UI (HUD Táctico, Badges, Telemetría y Acciones)
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isTabletOrLarger ? 40 : 20,
                vertical: isTabletOrLarger ? 24 : 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Superior de Sincronización y Estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTabletOrLarger ? 16 : 12,
                          vertical: isTabletOrLarger ? 8 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: accentColor,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withValues(alpha: 0.2),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.isGuest
                                  ? 'MODO INVITADO // SINCRONIZACIÓN LIMITADA'
                                  : 'AGENTE ACTIVO // CONEXIÓN ESTABLE',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: isTabletOrLarger ? 11 : 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Controles Rápidos de Mapa
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isFogActive
                                    ? Icons.cloud_outlined
                                    : Icons.cloud_off_outlined,
                                color: accentColor,
                                size: 20,
                              ),
                              tooltip: 'Alternar Niebla',
                              onPressed: () {
                                setState(() {
                                  _isFogActive = !_isFogActive;
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.my_location_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              tooltip: 'Recentrar en El Salvador',
                              onPressed: () {
                                _mapboxMap?.flyTo(
                                  CameraOptions(
                                    center: Point(
                                      coordinates: Position(
                                        _initialLng,
                                        _initialLat,
                                      ),
                                    ),
                                    zoom: _initialZoom,
                                    bearing: 0.0,
                                    pitch: 0.0,
                                  ),
                                  MapAnimationOptions(duration: 1200),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Tarjeta HUD Central Flotante (Desplegable / Despejable)
                  if (_isFogActive)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Container(
                          padding: EdgeInsets.all(isTabletOrLarger ? 28 : 20),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.5),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.08),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.explore_outlined,
                                    size: isTabletOrLarger ? 36 : 30,
                                    color: accentColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'NIEBLA DE GUERRA ACTIVA',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: isTabletOrLarger ? 16 : 14,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'El territorio de El Salvador se encuentra en reconocimiento. Explora sectores, sincroniza atalayas y desbloquea el mapa satelital.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: isTabletOrLarger ? 13 : 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'INICIAR EXPLORACIÓN GPS',
                                variant: widget.isGuest
                                    ? ButtonVariant.outline
                                    : ButtonVariant.primary,
                                onPressed: () {
                                  setState(() {
                                    _isFogActive = false;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: AppColors.surfaceElevated,
                                      content: Row(
                                        children: [
                                          Icon(Icons.radar, color: accentColor, size: 20),
                                          const SizedBox(width: 10),
                                          const Text(
                                            'Cartografía interactiva Mapbox activada',
                                            style: TextStyle(color: AppColors.textPrimary),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Telemetría Inferior Táctica Flotante
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LAT: 13.7942° N  |  LON: 88.8965° W',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: isTabletOrLarger ? 12 : 11,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          'SECTOR: SV-CENTRAL // MAPBOX v2',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: isTabletOrLarger ? 12 : 11,
                            letterSpacing: 1.1,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TacticalOverlayPainter extends CustomPainter {
  final Color accentColor;

  _TacticalOverlayPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFF14141E).withValues(alpha: 0.35)
      ..strokeWidth = 1;

    const double step = 60.0;

    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Retícula y visor táctico de esquinas
    final cornerPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const cornerLength = 24.0;
    const margin = 12.0;

    // Esquina superior izquierda
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + cornerLength, margin), cornerPaint);
    canvas.drawLine(const Offset(margin, margin), const Offset(margin, margin + cornerLength), cornerPaint);

    // Esquina superior derecha
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - cornerLength, margin), cornerPaint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + cornerLength), cornerPaint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + cornerLength, size.height - margin), cornerPaint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin, size.height - margin - cornerLength), cornerPaint);

    // Esquina inferior derecha
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - cornerLength, size.height - margin), cornerPaint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalOverlayPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
