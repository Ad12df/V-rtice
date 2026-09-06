import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/screens/auth_screen.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_button.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/map/services/location_service.dart';

class MapScreen extends StatefulWidget {
  final bool isGuest;

  const MapScreen({
    super.key,
    this.isGuest = false,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _authService = AuthService();
  final _locationService = LocationService();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  bool _isFogActive = true;
  TacticalPoi? _selectedPoi;
  bool _isRouteActive = false;

  // Estado de Perfil y Puntos de Interés dinámicos de Supabase
  UserProfile? _userProfile;
  List<TacticalPoi> _pois = LocationService.defaultPois;

  // Estado de Geolocalización en Tiempo Real
  LatLng? _userLocation;
  bool _isLocatingUser = false;

  // Coordenadas tácticas centrales de El Salvador
  static const LatLng _centerElSalvador = LatLng(13.7942, -88.8965);
  static const double _initialZoom = 8.8;

  // Delimitación geográfica estricta de El Salvador (Suroeste y Noreste)
  static final LatLngBounds _elSalvadorBounds = LatLngBounds(
    const LatLng(13.15, -90.15), // Suroeste
    const LatLng(14.45, -87.68), // Noreste
  );

  // Pines de usuario agregados interactivamente por toque en el mapa
  final List<TacticalPoi> _customPines = [];

  // Ruta activa de ejemplo (San Salvador -> Volcán de Santa Ana)
  final List<LatLng> _tacticalRoutePoints = const [
    LatLng(13.6983, -89.1914), // San Salvador
    LatLng(13.7220, -89.3000), // Santa Tecla
    LatLng(13.7650, -89.4300), // Desvío a Opico / Sitio del Niño
    LatLng(13.8100, -89.5200), // Carretera Panamericana hacia Santa Ana
    LatLng(13.8533, -89.6300), // Volcán de Santa Ana
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeOutQuad,
    );

    // Carga de Puntos de Interés y Perfil de Supabase
    _loadLocations();
    if (!widget.isGuest) {
      _loadUserProfile();
    }

    // Detección automática de GPS al iniciar
    _fetchCurrentLocation(moveToLocation: true);
  }

  Future<void> _loadLocations() async {
    final loaded = await _locationService.fetchLocations();
    if (mounted && loaded.isNotEmpty) {
      setState(() {
        _pois = loaded;
      });
    }
  }

  Future<void> _loadUserProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _userProfile = profile;
      });
    }
  }

  Future<void> _handleSignOut() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.surfaceBorder),
        ),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: AppColors.cyan, size: 20),
            SizedBox(width: 8),
            Text(
              'DESCONECTAR ENLACE',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        content: const Text(
          '¿Deseas cerrar la sesión táctica actual y retornar a la consola de acceso?',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('CERRAR SESIÓN'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// Calcula la distancia en metros entre el operador GPS y un punto de destino
  double? _getDistanceInMeters(LatLng destination) {
    if (_userLocation == null) return null;
    return Geolocator.distanceBetween(
      _userLocation!.latitude,
      _userLocation!.longitude,
      destination.latitude,
      destination.longitude,
    );
  }

  /// Formatea la distancia calculada en km o metros
  String _formatDistance(double? meters) {
    if (meters == null) return 'GPS PENDIENTE';
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(2)} km';
    }
    return '${meters.round()} m';
  }

  /// Solicita permisos y localiza la posición real del usuario
  Future<void> _fetchCurrentLocation({bool moveToLocation = false}) async {
    if (!mounted) return;
    setState(() {
      _isLocatingUser = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [GPS] El servicio de localización está desactivado en el dispositivo.');
        if (mounted) {
          setState(() => _isLocatingUser = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text(
                'Activa el GPS de tu dispositivo para fijar tu posición táctica.',
                style: TextStyle(color: AppColors.textPrimary),
              ),
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ [GPS] Permisos de ubicación denegados.');
          if (mounted) setState(() => _isLocatingUser = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [GPS] Permisos de ubicación denegados permanentemente.');
        if (mounted) setState(() => _isLocatingUser = false);
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      final userLatLng = LatLng(position.latitude, position.longitude);
      debugPrint('📍 [GPS] Posición táctica fijada: $userLatLng');

      if (mounted) {
        setState(() {
          _userLocation = userLatLng;
          _isLocatingUser = false;
        });

        if (moveToLocation) {
          _mapController.move(userLatLng, 15.0);
        }
      }
    } catch (e) {
      debugPrint('❌ [GPS ERROR] Excepción al capturar coordenadas: $e');
      if (mounted) {
        setState(() => _isLocatingUser = false);
      }
    }
  }

  /// Manejador de toque en el mapa para añadir pines tácticos interactivos
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    // Validar si el punto está dentro de El Salvador
    if (!_elSalvadorBounds.contains(point)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          duration: Duration(seconds: 2),
          content: Text(
            '⚠️ Coordenada fuera de la jurisdicción táctica de El Salvador.',
            style: TextStyle(color: Colors.amber),
          ),
        ),
      );
      return;
    }

    final pinNumber = _customPines.length + 1;
    final newPin = TacticalPoi(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: 'Punto Táctico #$pinNumber',
      category: 'RECONOCIMIENTO DE CAMPO',
      location: point,
      description: 'Punto de interés táctico marcado por el operador en el terreno.',
      difficulty: 'EXPLORACIÓN',
      icon: Icons.add_location_alt_rounded,
      isCustom: true,
    );

    setState(() {
      _customPines.add(newPin);
      _selectedPoi = newPin;
    });

    final distanceMeters = _getDistanceInMeters(point);
    final distanceText = _formatDistance(distanceMeters);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            const Icon(Icons.add_location_alt_rounded, color: Color(0xFF00F0FF), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN AÑADIDO // DISTANCIA: $distanceText',
                    style: const TextStyle(
                      color: Color(0xFF00F0FF),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'LAT: ${point.latitude.toStringAsFixed(4)}° | LON: ${point.longitude.toStringAsFixed(4)}°',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 10.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        action: SnackBarAction(
          label: 'INSPECCIONAR',
          textColor: const Color(0xFF00F0FF),
          onPressed: () => _showPlaceDetails(
            newPin,
            widget.isGuest ? AppColors.gold : AppColors.cyan,
            !Responsive.isMobile(context),
          ),
        ),
      ),
    );
  }

  void _showPlaceDetails(TacticalPoi poi, Color accentColor, bool isTabletOrLarger) {
    setState(() {
      _selectedPoi = poi;
    });

    final distanceMeters = _getDistanceInMeters(poi.location);
    final distanceText = _formatDistance(distanceMeters);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: isTabletOrLarger ? 60 : 16,
            vertical: 20,
          ),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accentColor.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.8),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header del Punto de Interés
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accentColor, width: 1),
                    ),
                    child: Icon(poi.icon, color: accentColor, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            poi.category,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          poi.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Banner de Distancia al Objetivo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00F0FF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF00F0FF).withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me_rounded, color: Color(0xFF00F0FF), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DISTANCIA AL OBJETIVO (DESDE OPERADOR):',
                            style: TextStyle(
                              color: Color(0xFF00F0FF),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            distanceText,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${poi.location.latitude.toStringAsFixed(4)}°, ${poi.location.longitude.toStringAsFixed(4)}°',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Descripción
              Text(
                poi.description,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),

              // Telemetría del Punto (Dificultad, Categoría)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DIFICULTAD',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          poi.difficulty,
                          style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 28, color: AppColors.surfaceBorder),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'CATEGORÍA',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          poi.category,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Botones de Acción Táctica
              Row(
                children: [
                  if (poi.isCustom) ...[
                    Expanded(
                      child: CustomButton(
                        text: 'ELIMINAR PIN',
                        variant: ButtonVariant.outline,
                        onPressed: () {
                          setState(() {
                            _customPines.removeWhere((p) => p.id == poi.id);
                            if (_selectedPoi?.id == poi.id) {
                              _selectedPoi = null;
                            }
                          });
                          Navigator.of(ctx).pop();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ] else ...[
                    Expanded(
                      child: CustomButton(
                        text: _isRouteActive && _selectedPoi?.id == poi.id
                            ? 'CANCELAR RUTA'
                            : 'TRAZAR RUTA (ETA 1h 20m)',
                        variant: ButtonVariant.outline,
                        onPressed: () {
                          setState(() {
                            _isRouteActive = !_isRouteActive;
                          });
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.surfaceElevated,
                              content: Row(
                                children: [
                                  Icon(Icons.alt_route_rounded, color: accentColor, size: 20),
                                  const SizedBox(width: 10),
                                  Text(
                                    _isRouteActive
                                        ? 'Ruta táctica hacia ${poi.name} (~65 km | ETA: 1h 20m)'
                                        : 'Ruta táctica cancelada.',
                                    style: const TextStyle(color: AppColors.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: CustomButton(
                      text: 'ENFOCAR',
                      variant: widget.isGuest ? ButtonVariant.outline : ButtonVariant.primary,
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _mapController.move(poi.location, 14.5);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);
    final accentColor = widget.isGuest ? AppColors.gold : AppColors.cyan;

    // Distancia calculada dinámica para la barra de telemetría inferior
    String? currentDistanceText;
    if (_selectedPoi != null && _userLocation != null) {
      final d = _getDistanceInMeters(_selectedPoi!.location);
      currentDistanceText = _formatDistance(d);
    }

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
          // 1. Capa de Cartografía Optimizada: Restringida a El Salvador, retinaMode: false y tileProvider con caché
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _centerElSalvador,
                initialZoom: _initialZoom,
                minZoom: 8.0,
                maxZoom: 17.0,
                // Restricción de navegación estricta: No permite salirse de El Salvador
                cameraConstraint: CameraConstraint.contain(bounds: _elSalvadorBounds),
                // Toque interactivo para agregar nuevos pines de campo
                onTap: (tapPosition, point) => _onMapTap(tapPosition, point),
              ),
              children: [
                // Base Cartográfica Oscura Optimizada (maxNativeZoom: 16 evita peticiones inexistentes al servidor)
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.vertice.app',
                  minZoom: 8.0,
                  maxZoom: 18.0,
                  maxNativeZoom: 16,
                  retinaMode: false,
                  tileProvider: NetworkTileProvider(),
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix(<double>[
                        1.20, 0, 0, 0, -8,
                        0, 1.20, 0, 0, -8,
                        0, 0, 1.28, 0, -2,
                        0, 0, 0, 1.0, 0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),

                // Capa de Referencia Optimizada (Carreteras, Límites y Ciudades con maxNativeZoom: 16)
                TileLayer(
                  urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Reference/MapServer/tile/{z}/{y}/{x}',
                  userAgentPackageName: 'com.vertice.app',
                  minZoom: 8.0,
                  maxZoom: 18.0,
                  maxNativeZoom: 16,
                  retinaMode: false,
                  tileProvider: NetworkTileProvider(),
                ),

                // Capa de Rutas Tácticas Neón de Alta Intensidad (PolylineLayer)
                if (_isRouteActive)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _tacticalRoutePoints,
                        color: const Color(0xFF00F0FF), // Cyan Neón al 100%
                        strokeWidth: 5.0,
                        borderColor: const Color(0xFFE5B842), // Borde Dorado Neón al 100%
                        borderStrokeWidth: 1.5,
                      ),
                    ],
                  ),

                // Capa de Marcadores Tácticos de El Salvador + Posición de Operador + Pines Personalizados
                MarkerLayer(
                  markers: [
                    // Marcador Dinámico de Posición del Operador (GPS en tiempo real)
                    if (_userLocation != null)
                      Marker(
                        point: _userLocation!,
                        width: 68,
                        height: 68,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            final pulseValue = _pulseAnimation.value;
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Onda expansiva exterior
                                Container(
                                  width: 28 + (34 * pulseValue),
                                  height: 28 + (34 * pulseValue),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00F0FF).withValues(
                                      alpha: (0.45 * (1.0 - pulseValue)).clamp(0.0, 1.0),
                                    ),
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF).withValues(
                                        alpha: (0.9 * (1.0 - pulseValue)).clamp(0.0, 1.0),
                                      ),
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                                // Halo de neón intermedio
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFF00F0FF).withValues(alpha: 0.3),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0xFF00F0FF),
                                        blurRadius: 12,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                ),
                                // Núcleo del Operador
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFF00F0FF),
                                      width: 3,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black54,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),

                    // Marcadores de Puntos Turísticos Emblemáticos
                    ..._pois.map((poi) {
                      final isSelected = _selectedPoi?.id == poi.id;
                      return Marker(
                        point: poi.location,
                        width: 52,
                        height: 52,
                        child: GestureDetector(
                          onTap: () => _showPlaceDetails(poi, accentColor, isTabletOrLarger),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? accentColor
                                  : AppColors.surfaceElevated.withValues(alpha: 0.95),
                              border: Border.all(
                                color: accentColor,
                                width: isSelected ? 2.8 : 1.8,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accentColor.withValues(alpha: isSelected ? 0.75 : 0.4),
                                  blurRadius: isSelected ? 18 : 10,
                                  spreadRadius: isSelected ? 3 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              poi.icon,
                              color: isSelected ? Colors.black : accentColor,
                              size: 24,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Marcadores de Pines Personalizados añadidos por el usuario
                    ..._customPines.map((customPoi) {
                      final isSelected = _selectedPoi?.id == customPoi.id;
                      return Marker(
                        point: customPoi.location,
                        width: 48,
                        height: 48,
                        child: GestureDetector(
                          onTap: () => _showPlaceDetails(
                            customPoi,
                            const Color(0xFF00F0FF),
                            isTabletOrLarger,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? const Color(0xFF00F0FF)
                                  : AppColors.surface.withValues(alpha: 0.95),
                              border: Border.all(
                                color: const Color(0xFF00F0FF),
                                width: isSelected ? 2.8 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF).withValues(alpha: isSelected ? 0.8 : 0.45),
                                  blurRadius: isSelected ? 16 : 8,
                                  spreadRadius: isSelected ? 3 : 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              customPoi.icon,
                              color: isSelected ? Colors.black : const Color(0xFF00F0FF),
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),

          // 2. Cuadrícula de radar y retícula táctica sutil
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
                horizontal: isTabletOrLarger ? 40 : 16,
                vertical: isTabletOrLarger ? 24 : 14,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Superior de Sincronización y Estado
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTabletOrLarger ? 16 : 10,
                            vertical: isTabletOrLarger ? 8 : 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentColor, width: 1),
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
                                  color: _userLocation != null ? const Color(0xFF00F0FF) : accentColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                                Flexible(
                                child: Text(
                                  _isLocatingUser
                                      ? 'LOCALIZANDO OPERADOR (GPS)...'
                                      : (widget.isGuest
                                          ? 'INVITADO // GPS PENDIENTE'
                                          : (_userProfile != null
                                              ? '[${_userProfile!.role.toUpperCase()}] ${_userProfile!.fullName ?? _userProfile!.username ?? "AGENTE"}'
                                              : (_userLocation != null
                                                  ? 'GPS ACTIVO // TAP MAPA = PIN'
                                                  : 'ZONA RESTRINGIDA // EL SALVADOR'))),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _userLocation != null ? const Color(0xFF00F0FF) : accentColor,
                                    fontSize: isTabletOrLarger ? 11 : 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Controles Rápidos de Mapa (Niebla, GPS de Operador, Overview El Salvador, Desconectar)
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
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
                            // Botón GPS de Operador (Centra en posición actual)
                            IconButton(
                              icon: _isLocatingUser
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F0FF)),
                                      ),
                                    )
                                  : Icon(
                                      Icons.my_location_rounded,
                                      color: _userLocation != null
                                          ? const Color(0xFF00F0FF)
                                          : AppColors.textPrimary,
                                      size: 20,
                                    ),
                              tooltip: 'Centrar en Posición de Operador (GPS)',
                              onPressed: () {
                                if (_userLocation != null) {
                                  _mapController.move(_userLocation!, 15.0);
                                } else {
                                  _fetchCurrentLocation(moveToLocation: true);
                                }
                              },
                            ),
                            // Botón Vista General de El Salvador
                            IconButton(
                              icon: const Icon(
                                Icons.public_rounded,
                                color: AppColors.textPrimary,
                                size: 20,
                              ),
                              tooltip: 'Vista General de El Salvador',
                              onPressed: () {
                                _mapController.move(_centerElSalvador, _initialZoom);
                              },
                            ),
                            // Botón Cerrar Sesión Táctica
                            IconButton(
                              icon: const Icon(
                                Icons.logout_rounded,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              tooltip: 'Cerrar Sesión Táctica',
                              onPressed: _handleSignOut,
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
                            color: AppColors.surface.withValues(alpha: 0.94),
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
                                'Navegación restringida a El Salvador. Toca cualquier punto del mapa para colocar un pin táctico o inspecciona atalayas para ver distancias en vivo.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: isTabletOrLarger ? 13 : 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'INICIAR EXPLORACIÓN LIBRE',
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
                                            'Cartografía táctica libre desbloqueada.',
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

                  // Telemetría Inferior Táctica Flotante con Distancia en Tiempo Real
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedPoi != null
                                ? 'OBJETIVO: ${_selectedPoi!.name.toUpperCase()} ${currentDistanceText != null ? "[$currentDistanceText]" : ""}'
                                : (_userLocation != null
                                    ? 'OPERADOR: ${_userLocation!.latitude.toStringAsFixed(4)}° N, ${_userLocation!.longitude.toStringAsFixed(4)}° W'
                                    : 'LAT: 13.7942° N | LON: 88.8965° W'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _selectedPoi != null
                                  ? const Color(0xFF00F0FF)
                                  : accentColor,
                              fontSize: isTabletOrLarger ? 12 : 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _customPines.isNotEmpty
                              ? 'PINES: ${_customPines.length}'
                              : (_isRouteActive ? 'RUTA: ACTIVA' : 'LÍMITES: SV'),
                          style: TextStyle(
                            color: _selectedPoi != null
                                ? const Color(0xFF00F0FF)
                                : AppColors.textMuted,
                            fontSize: isTabletOrLarger ? 12 : 10.5,
                            letterSpacing: 0.8,
                            fontWeight: FontWeight.bold,
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
    canvas.drawLine(const Offset(margin, margin), const Offset(margin + cornerLength, margin), cornerPaint);

    // Esquina superior derecha
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - cornerLength, margin), cornerPaint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin - cornerLength, margin), cornerPaint);

    // Esquina inferior izquierda
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + cornerLength, size.height - margin), cornerPaint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + cornerLength, size.height - margin), cornerPaint);

    // Esquina inferior derecha
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - cornerLength, size.height - margin), cornerPaint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin - cornerLength, size.height - margin), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalOverlayPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
