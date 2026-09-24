import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/widgets/custom_button.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/map/presentation/widgets/add_location_modal.dart';
import 'package:vertice/features/map/presentation/widgets/advanced_search_modal.dart';
import 'package:vertice/features/map/services/location_service.dart';
import 'package:vertice/features/map/services/map_cache_service.dart';

class MapScreen extends StatefulWidget {
  /// Controla si el sensor GPS está activo. Cuando es false, no se realizan
  /// peticiones de localización (controlado desde SettingsScreen vía AppShell).
  final bool gpsEnabled;

  const MapScreen({
    super.key,
    this.gpsEnabled = true,
  });

  @override
  State<MapScreen> createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final _authService = AuthService();
  final _locationService = LocationService();
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  StreamSubscription<Position>? _positionStreamSub;

  // Controladores y estado para la barra de búsqueda táctica
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';

  // Filtros territoriales de El Salvador
  TacticalFilterCriteria _filterCriteria = const TacticalFilterCriteria();

  bool _isFogActive = false;
  bool _showTelemetry = true;
  TacticalPoi? _selectedPoi;

  // Estado de Ruta Táctica Dinámica (OSRM con fallback geodésico)
  bool _isRouteActive = false;
  List<LatLng> _tacticalRoutePoints = [];
  TacticalRouteResult? _currentRouteResult;
  TacticalPoi? _routeDestinationPoi;
  bool _isCalculatingRoute = false;

  // Estado de Perfil y Puntos de Interés dinámicos de Supabase
  UserProfile? _userProfile;
  List<TacticalPoi> _pois = const [];

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
    _loadUserProfile();
    _locationService.poisNotifier.addListener(_onPoisNotifierChanged);

    // Detección automática de GPS al iniciar (solo si GPS habilitado)
    if (widget.gpsEnabled) {
      _fetchCurrentLocation(moveToLocation: true);
    }
  }

  void _onPoisNotifierChanged() {
    if (mounted) {
      setState(() => _pois = _locationService.poisNotifier.value);
    }
  }

  bool get _isAdmin => _userProfile?.role == 'admin';

  Future<void> _openAddLocationModal(LatLng point) async {
    if (!_isAdmin) return;

    final createdPoi = await AddLocationModal.show(
      context,
      initialCoordinates: point,
    );

    if (createdPoi != null && mounted) {
      await _loadLocations();
      setState(() {
        _selectedPoi = createdPoi;
      });
      _mapController.move(createdPoi.location, 14.5);
    }
  }

  Future<void> _captureCurrentLocationAsPoi() async {
    if (!_isAdmin) return;

    LatLng targetCoords;
    if (_userLocation != null) {
      targetCoords = _userLocation!;
    } else {
      setState(() => _isLocatingUser = true);
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        targetCoords = LatLng(pos.latitude, pos.longitude);
      } catch (_) {
        targetCoords = const LatLng(13.6983, -89.1914);
      } finally {
        if (mounted) setState(() => _isLocatingUser = false);
      }
    }

    if (!mounted) return;
    await _openAddLocationModal(targetCoords);
  }

  Future<void> _loadLocations() async {
    final loaded = await _locationService.fetchLocations();
    if (mounted) {
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

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gpsEnabled != widget.gpsEnabled) {
      if (widget.gpsEnabled) {
        _fetchCurrentLocation(moveToLocation: true);
      } else {
        _positionStreamSub?.cancel();
        _positionStreamSub = null;
        setState(() {
          _userLocation = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _locationService.poisNotifier.removeListener(_onPoisNotifierChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _positionStreamSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  /// Recentra la cámara del mapa sobre las coordenadas GPS en tiempo real del usuario
  /// con un nivel de zoom táctico (15.0).
  void recenterOnUser() {
    if (!widget.gpsEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: const Text(
            'GPS desactivado en ajustes. Actívalo para rastrear tu posición.',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }

    if (_userLocation != null) {
      _mapController.move(_userLocation!, 15.0);
    } else {
      _fetchCurrentLocation(moveToLocation: true);
    }
  }

  /// Enfoca la cámara en unas coordenadas específicas (ej. desde la agenda de eventos tácticos)
  void focusOnCoordinates(LatLng coords, [String? name]) {
    _mapController.move(coords, 15.0);
    final allList = [..._pois, ..._customPines];
    final match = allList.firstWhere(
      (p) =>
          (p.location.latitude - coords.latitude).abs() < 0.001 &&
          (p.location.longitude - coords.longitude).abs() < 0.001,
      orElse: () => TacticalPoi(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        name: name ?? 'OBJETIVO TÁCTICO',
        category: 'EVENTO / OPERACIÓN',
        location: coords,
        description: 'Coordenadas del evento táctico en El Salvador.',
        difficulty: 'TERRENO',
        icon: Icons.event_available_rounded,
      ),
    );
    setState(() {
      _selectedPoi = match;
    });
    _showPlaceDetails(match, AppColors.cyan, !Responsive.isMobile(context));
  }

  /// Lista de POIs activos filtrados según criterios territoriales y de precio
  List<TacticalPoi> get _activeDisplayedPois {
    if (!_filterCriteria.isActive) return _pois;
    return _pois.where((poi) {
      if (_filterCriteria.selectedDepartment != null &&
          poi.department != _filterCriteria.selectedDepartment) {
        return false;
      }
      if (_filterCriteria.selectedZone != null &&
          poi.zone != _filterCriteria.selectedZone) {
        return false;
      }
      if (_filterCriteria.selectedPriceRange != null &&
          poi.priceRange != _filterCriteria.selectedPriceRange) {
        return false;
      }
      if (_filterCriteria.selectedDifficulty != null &&
          poi.difficulty != _filterCriteria.selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  /// Despliega el modal táctico de búsqueda avanzada con los 14 departamentos
  void _openAdvancedSearch() {
    AdvancedSearchModal.show(
      context,
      allPois: _pois,
      currentCriteria: _filterCriteria,
      onApplyFilters: (criteria, filteredResults) {
        setState(() {
          _filterCriteria = criteria;
        });
        if (filteredResults.isNotEmpty) {
          _mapController.move(filteredResults.first.location, 12.0);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Row(
                children: [
                  const Icon(Icons.filter_alt_rounded, color: AppColors.cyan, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Filtro aplicado: ${filteredResults.length} puntos localizados.',
                      style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      onSelectPoi: (poi) {
        _mapController.move(poi.location, 15.0);
        _showPlaceDetails(poi, AppColors.cyan, !Responsive.isMobile(context));
      },
    );
  }

  /// Filtra en tiempo real los puntos de interés de El Salvador coincidentes con la búsqueda
  List<TacticalPoi> get _filteredPois {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return const [];
    final allList = [..._pois, ..._customPines];
    return allList.where((p) {
      final name = p.name.toLowerCase();
      final cat = p.category.toLowerCase();
      final desc = p.description.toLowerCase();
      return name.contains(query) || cat.contains(query) || desc.contains(query);
    }).toList();
  }

  /// Selecciona un resultado de búsqueda, mueve la cámara y abre la ficha táctica
  void _selectSearchResult(TacticalPoi poi, Color accentColor, bool isTabletOrLarger) {
    _searchFocusNode.unfocus();
    _searchController.text = poi.name;
    setState(() {
      _searchQuery = '';
      _selectedPoi = poi;
    });
    _mapController.move(poi.location, 15.0);
    _showPlaceDetails(poi, accentColor, isTabletOrLarger);
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

  /// Asegura que las coordenadas caigan dentro de la delimitación de El Salvador.
  /// Si se ejecuta en un emulador o fuera del país, ajusta la posición táctica
  /// a San Salvador para garantizar que el punto siempre sea visible en el mapa.
  LatLng _sanitizeCoordinates(LatLng coords) {
    if (_elSalvadorBounds.contains(coords)) {
      return coords;
    }
    debugPrint('⚠️ [GPS] Coordenada ($coords) fuera de El Salvador. Ajustando a punto táctico de San Salvador.');
    return const LatLng(13.6983, -89.1914);
  }

  /// Inicia la escucha continua de posición para actualizar el punto en tiempo real.
  void _startLocationStream() {
    _positionStreamSub?.cancel();
    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 3,
      ),
    ).listen(
      (pos) {
        if (!mounted || !widget.gpsEnabled) return;
        final validPoint = _sanitizeCoordinates(LatLng(pos.latitude, pos.longitude));
        setState(() {
          _userLocation = validPoint;
          _isLocatingUser = false;
        });
      },
      onError: (err) {
        debugPrint('⚠️ [GPS STREAM] Error en flujo continuo: $err');
      },
    );
  }

  /// Solicita permisos y localiza la posición real del operador.
  /// Utiliza última posición conocida como respuesta inmediata, fallback de precisión
  /// y activación de stream continuo.
  Future<void> _fetchCurrentLocation({bool moveToLocation = false}) async {
    if (!mounted) return;
    if (!widget.gpsEnabled) {
      setState(() => _isLocatingUser = false);
      return;
    }
    setState(() {
      _isLocatingUser = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ [GPS] Servicio de ubicación desactivado en el dispositivo.');
        if (mounted) {
          setState(() {
            // Posición por defecto en San Salvador para que siempre haya un punto táctico
            _userLocation ??= const LatLng(13.6983, -89.1914);
            _isLocatingUser = false;
          });
          if (moveToLocation && _userLocation != null) {
            _mapController.move(_userLocation!, 15.0);
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text(
                'Activa el GPS de tu dispositivo para actualizar tu posición táctica real.',
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
          if (mounted) {
            setState(() {
              _userLocation ??= const LatLng(13.6983, -89.1914);
              _isLocatingUser = false;
            });
            if (moveToLocation && _userLocation != null) {
              _mapController.move(_userLocation!, 15.0);
            }
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ [GPS] Permisos de ubicación denegados permanentemente.');
        if (mounted) {
          setState(() {
            _userLocation ??= const LatLng(13.6983, -89.1914);
            _isLocatingUser = false;
          });
          if (moveToLocation && _userLocation != null) {
            _mapController.move(_userLocation!, 15.0);
          }
        }
        return;
      }

      // 1. Obtener última posición conocida para respuesta instantánea (0ms)
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null && mounted) {
        final quickPoint = _sanitizeCoordinates(LatLng(lastKnown.latitude, lastKnown.longitude));
        setState(() {
          _userLocation = quickPoint;
        });
        if (moveToLocation) {
          _mapController.move(quickPoint, 15.0);
        }
      }

      // 2. Obtener posición actual con fallback de precisión
      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 6),
          ),
        );
      } catch (_) {
        // Fallback a balanced/medium si la alta precisión tarda o da timeout
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 5),
            ),
          );
        } catch (err) {
          debugPrint('⚠️ [GPS] Error en fallback de posición: $err');
        }
      }

      if (position != null && mounted) {
        final accuratePoint = _sanitizeCoordinates(LatLng(position.latitude, position.longitude));
        debugPrint('📍 [GPS] Posición táctica fijada: $accuratePoint');
        setState(() {
          _userLocation = accuratePoint;
          _isLocatingUser = false;
        });

        if (moveToLocation) {
          _mapController.move(accuratePoint, 15.0);
        }
      } else if (mounted && _userLocation == null) {
        // Garantizar que siempre haya un punto visible en el mapa
        const fallbackPoint = LatLng(13.6983, -89.1914);
        setState(() {
          _userLocation = fallbackPoint;
          _isLocatingUser = false;
        });
        if (moveToLocation) {
          _mapController.move(fallbackPoint, 15.0);
        }
      } else if (mounted) {
        setState(() => _isLocatingUser = false);
      }

      // 3. Iniciar stream continuo de ubicación
      _startLocationStream();
    } catch (e) {
      debugPrint('❌ [GPS ERROR] Excepción al capturar coordenadas: $e');
      if (mounted) {
        setState(() {
          _userLocation ??= const LatLng(13.6983, -89.1914);
          _isLocatingUser = false;
        });
      }
    }
  }

  /// Traza la ruta óptima entre el operador y el destino (OSRM con fallback geodésico)
  Future<void> _traceRouteToDestination(TacticalPoi destination) async {
    LatLng startPoint;
    if (_userLocation != null) {
      startPoint = _userLocation!;
    } else {
      setState(() => _isLocatingUser = true);
      try {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 5),
          ),
        );
        startPoint = LatLng(pos.latitude, pos.longitude);
        _userLocation = startPoint;
      } catch (_) {
        startPoint = const LatLng(13.6983, -89.1914);
        _userLocation ??= startPoint;
      } finally {
        if (mounted) setState(() => _isLocatingUser = false);
      }
    }

    setState(() {
      _isCalculatingRoute = true;
    });

    final result = await _locationService.calculateRoute(
      start: startPoint,
      destination: destination.location,
    );

    if (mounted) {
      setState(() {
        _isCalculatingRoute = false;
        _isRouteActive = true;
        _tacticalRoutePoints = result.points;
        _currentRouteResult = result;
        _routeDestinationPoi = destination;
      });

      // Ajustar cámara para encuadrar la ruta completa
      try {
        if (result.points.length >= 2) {
          final bounds = LatLngBounds.fromPoints(result.points);
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: bounds,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 80),
            ),
          );
        } else {
          _mapController.move(destination.location, 13.0);
        }
      } catch (_) {
        _mapController.move(destination.location, 13.0);
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          duration: const Duration(seconds: 4),
          content: Row(
            children: [
              const Icon(Icons.alt_route_rounded, color: AppColors.goldenOrange, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RUTA TÁCTICA // ${result.isRealRoute ? "OSRM VIAL REAL" : "LÍNEA GEODÉSICA DIRECTA"}',
                      style: const TextStyle(
                        color: AppColors.goldenOrange,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      'Destino: ${destination.name} (${result.formattedDistance} • ETA: ${result.formattedDuration})',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  /// Cancela la ruta táctica activa
  void _cancelRoute() {
    setState(() {
      _isRouteActive = false;
      _tacticalRoutePoints = [];
      _currentRouteResult = null;
      _routeDestinationPoi = null;
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.surfaceElevated,
        content: Text(
          'Ruta táctica cancelada.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }

  /// Abre la navegación externa por voz paso a paso en Google Maps / Waze
  Future<void> _openExternalNavigation(LatLng destination) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${destination.latitude},${destination.longitude}',
    );
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text(
              'No se pudo abrir navegación externa: $e',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        );
      }
    }
  }

  /// Manejador de toque en el mapa para añadir pines tácticos interactivos
  void _onMapTap(TapPosition tapPosition, LatLng point) {
    if (_searchFocusNode.hasFocus) {
      _searchFocusNode.unfocus();
    }
    if (_searchQuery.isNotEmpty) {
      setState(() => _searchQuery = '');
    }

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

    // Si es Administrador, abrir el modal de captura y registro para la coordenada seleccionada
    if (_isAdmin) {
      _openAddLocationModal(point);
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
            const Icon(Icons.add_location_alt_rounded, color: AppColors.turquoise, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN AÑADIDO // DISTANCIA: $distanceText',
                    style: const TextStyle(
                      color: AppColors.locationBlue,
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
          textColor: AppColors.locationBlue,
          onPressed: () => _showPlaceDetails(
            newPin,
            AppColors.cyan,
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
            borderRadius: BorderRadius.circular(16),
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
            ),
            child: SingleChildScrollView(
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
                  color: AppColors.locationBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.near_me_rounded, color: AppColors.locationBlue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'DISTANCIA AL OBJETIVO (DESDE OPERADOR):',
                            style: TextStyle(
                              color: AppColors.locationBlue,
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                            text: _isRouteActive && _routeDestinationPoi?.id == poi.id
                                ? 'CANCELAR RUTA'
                                : 'TRAZAR RUTA',
                            variant: ButtonVariant.outline,
                            icon: _isRouteActive && _routeDestinationPoi?.id == poi.id
                                ? Icons.close_rounded
                                : Icons.alt_route_rounded,
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              if (_isRouteActive && _routeDestinationPoi?.id == poi.id) {
                                _cancelRoute();
                              } else {
                                _traceRouteToDestination(poi);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: CustomButton(
                          text: 'ENFOCAR',
                          variant: ButtonVariant.primary,
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _mapController.move(poi.location, 14.5);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Opción "Abrir en Google Maps / Waze" mediante url_launcher
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.goldenOrange,
                        side: const BorderSide(color: AppColors.goldenOrange, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text(
                        'ABRIR EN GOOGLE MAPS / WAZE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      onPressed: () {
                        _openExternalNavigation(poi.location);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  },
);
  }

  /// Construye el marcador dinámico táctico de alta visibilidad para la posición del operador.
  Marker _buildOperatorMarker(LatLng location) {
    final operatorName = _userProfile?.fullName ?? _userProfile?.username ?? 'OPERADOR';
    return Marker(
      point: location,
      width: 110,
      height: 110,
      alignment: Alignment.center,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, _) {
          final pulseValue = _pulseAnimation.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              // 1. Radar perimetral de zona aproximada (onda expansiva)
              Container(
                width: 44 + (56 * pulseValue),
                height: 44 + (56 * pulseValue),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.locationBlue.withValues(
                    alpha: (0.30 * (1.0 - pulseValue)).clamp(0.0, 1.0),
                  ),
                  border: Border.all(
                    color: AppColors.turquoise.withValues(
                      alpha: (0.75 * (1.0 - pulseValue)).clamp(0.0, 1.0),
                    ),
                    width: 1.5,
                  ),
                ),
              ),

              // 2. Halo táctico y contenedor circular de alta visibilidad
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.locationBlue,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.locationBlue.withValues(alpha: 0.35),
                      blurRadius: 12,
                      spreadRadius: 1.5,
                    ),
                    const BoxShadow(
                      color: Colors.black54,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.my_location_rounded,
                    color: AppColors.locationBlue,
                    size: 24,
                  ),
                ),
              ),

              // 3. Núcleo luminoso blanco centrado
              Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.locationBlue.withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1.0,
                    ),
                  ],
                ),
              ),

              // 4. Badge flotante superior con identificador del operador
              Positioned(
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.navyBlue.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.turquoise,
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navyBlue.withValues(alpha: 0.3),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    operatorName.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);
    // Siempre cyan: modo invitado eliminado
    const accentColor = AppColors.cyan;

    // Distancia calculada dinámica para la barra de telemetría inferior
    String? currentDistanceText;
    if (_selectedPoi != null && _userLocation != null) {
      final d = _getDistanceInMeters(_selectedPoi!.location);
      currentDistanceText = _formatDistance(d);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
                // Toque interactivo para agregar nuevos pines de campo o atalayas admin
                onTap: (tapPosition, point) => _onMapTap(tapPosition, point),
                onLongPress: (tapPosition, point) {
                  if (_isAdmin && _elSalvadorBounds.contains(point)) {
                    _openAddLocationModal(point);
                  }
                },
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
                  tileProvider: MapCacheService.instance.tileProvider,
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
                  tileProvider: MapCacheService.instance.tileProvider,
                ),

                // Capa de Rutas Tácticas Orgánicas (PolylineLayer)
                if (_isRouteActive && _tacticalRoutePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _tacticalRoutePoints,
                        color: AppColors.goldenOrange, // Naranja Dorado (#F39C12)
                        strokeWidth: 4.8,
                        borderColor: AppColors.navyBlue,
                        borderStrokeWidth: 1.8,
                      ),
                    ],
                  ),

                // Capa de Marcadores Tácticos de El Salvador + Posición de Operador + Pines Personalizados
                MarkerLayer(
                  markers: [
                    // Marcadores de Puntos Turísticos Emblemáticos (Filtrados)
                    ..._activeDisplayedPois.map((poi) {
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
                              color: isSelected ? Colors.white : accentColor,
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
                            AppColors.turquoise,
                            isTabletOrLarger,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? AppColors.turquoise
                                  : AppColors.surface.withValues(alpha: 0.95),
                              border: Border.all(
                                color: AppColors.turquoise,
                                width: isSelected ? 2.8 : 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.turquoise.withValues(alpha: isSelected ? 0.5 : 0.25),
                                  blurRadius: isSelected ? 12 : 6,
                                  spreadRadius: isSelected ? 2 : 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              customPoi.icon,
                              color: isSelected ? Colors.white : AppColors.turquoise,
                              size: 22,
                            ),
                          ),
                        ),
                      );
                    }),

                    // Marcador Táctico Dinámico del Operador (se renderiza al final para máxima visibilidad encima de todo)
                    if (_userLocation != null)
                      _buildOperatorMarker(_userLocation!),
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
                  // 1. Barra de Búsqueda Táctica Flotante
                  _buildTacticalSearchBar(accentColor, isTabletOrLarger),

                  // 2. Menú Desplegable de Sugerencias (o Chip de Estado si no hay consulta activa)
                  if (_searchQuery.trim().isNotEmpty)
                    _buildSearchSuggestions(accentColor, isTabletOrLarger)
                  else
                    _buildStatusChip(accentColor, isTabletOrLarger),

                  if (_pois.isEmpty)
                    _buildEmptyStateBanner(isTabletOrLarger),

                  const Spacer(),

                  // Tarjeta HUD Central Flotante (Desplegable / Despejable)
                  if (_isFogActive)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Container(
                          padding: EdgeInsets.all(isTabletOrLarger ? 24 : 18),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.95),
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
                          child: Stack(
                            children: [
                              // Botón de cierre táctico "X"
                              Positioned(
                                top: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => setState(() => _isFogActive = false),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceElevated,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.surfaceBorder,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textMuted,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.explore_outlined,
                                        size: isTabletOrLarger ? 32 : 26,
                                        color: accentColor,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'NIEBLA DE GUERRA ACTIVA',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: isTabletOrLarger ? 15 : 13,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Navegación restringida a El Salvador. Toca cualquier punto del mapa para colocar un pin táctico o inspecciona atalayas para ver distancias en vivo.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: isTabletOrLarger ? 12.5 : 11.5,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomButton(
                                    text: 'INICIAR EXPLORACIÓN LIBRE',
                                    variant: ButtonVariant.primary,
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
                            ],
                          ),
                        ),
                      ),
                    ),

                  const Spacer(),

                  // Banner Flotante de Ruta Activa Táctica
                  if (_isRouteActive && _routeDestinationPoi != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.goldenOrange, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldenOrange.withValues(alpha: 0.25),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.alt_route_rounded, color: AppColors.goldenOrange, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'RUTA: ${_routeDestinationPoi!.name.toUpperCase()}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.goldenOrange,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_currentRouteResult?.formattedDistance ?? ''} • ETA: ${_currentRouteResult?.formattedDuration ?? ''} (${_currentRouteResult?.isRealRoute == true ? "OSRM VIAL" : "DIRECTO"})',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 10.5,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón Abrir en Google Maps / Waze
                          IconButton(
                            icon: const Icon(Icons.navigation_rounded, color: AppColors.cyan, size: 20),
                            tooltip: 'Abrir en Google Maps / Waze',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _openExternalNavigation(_routeDestinationPoi!.location),
                          ),
                          const SizedBox(width: 12),
                          // Botón Cancelar Ruta
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                            tooltip: 'Cancelar Ruta',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: _cancelRoute,
                          ),
                        ],
                      ),
                    ),

                  if (_isCalculatingRoute)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.goldenOrange),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.goldenOrange),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Calculando waypoints tácticos (OSRM)...',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 11, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),

                  // Telemetría Inferior Táctica Flotante con Distancia en Tiempo Real y Descarte
                  if (_showTelemetry)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                                    ? AppColors.turquoise
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
                                : (_isRouteActive ? 'RUTA: ACTIVA' : 'SV'),
                            style: TextStyle(
                              color: _selectedPoi != null
                                  ? AppColors.turquoise
                                  : AppColors.textMuted,
                              fontSize: isTabletOrLarger ? 12 : 10.5,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botón de descarte táctico "X"
                          GestureDetector(
                            onTap: () => setState(() => _showTelemetry = false),
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textMuted,
                                size: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    // Chip compacto para restaurar telemetría
                    Align(
                      alignment: Alignment.bottomRight,
                      child: GestureDetector(
                        onTap: () => setState(() => _showTelemetry = true),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.sensors_rounded, color: AppColors.cyan, size: 13),
                              SizedBox(width: 6),
                              Text(
                                'TELEMETRÍA',
                                style: TextStyle(
                                  color: AppColors.cyan,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. Botón Flotante Exclusivo para Administradores: Capturar Posición Actual
          if (_isAdmin)
            Positioned(
              right: isTabletOrLarger ? 32 : 16,
              bottom: isTabletOrLarger ? 90 : 76,
              child: FloatingActionButton.extended(
                heroTag: 'admin_capture_current_position_fab',
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.locationBlue,
                elevation: 6,
                highlightElevation: 10,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppColors.turquoise, width: 1.5),
                ),
                onPressed: _isLocatingUser ? null : _captureCurrentLocationAsPoi,
                icon: _isLocatingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.turquoise,
                        ),
                      )
                    : const Icon(
                        Icons.add_location_alt_rounded,
                        color: AppColors.turquoise,
                        size: 22,
                      ),
                label: const Text(
                  'CAPTURAR POSICIÓN',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Barra de Búsqueda Táctica Superior Flotante
  Widget _buildTacticalSearchBar(Color accentColor, bool isTabletOrLarger) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _searchFocusNode.hasFocus ? AppColors.cyan : AppColors.surfaceBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (_searchFocusNode.hasFocus ? AppColors.cyan : Colors.black).withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(
            Icons.radar_rounded,
            color: accentColor,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
              cursorColor: AppColors.cyan,
              decoration: const InputDecoration(
                hintText: 'BUSCAR EN EL SALVADOR (VOLCÁN, PLAYA, LAGO)...',
                hintStyle: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  letterSpacing: 0.6,
                  fontFamily: 'monospace',
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
                filled: false,
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
              tooltip: 'Limpiar búsqueda',
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          Container(
            height: 24,
            width: 1,
            color: AppColors.surfaceBorder,
            margin: const EdgeInsets.symmetric(horizontal: 4),
          ),
          // Botón Búsqueda Avanzada con Filtros Territoriales de El Salvador
          IconButton(
            icon: Stack(
              alignment: Alignment.topRight,
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: _filterCriteria.isActive ? AppColors.cyan : AppColors.textSecondary,
                  size: 20,
                ),
                if (_filterCriteria.isActive)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cyan,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.cyan,
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Filtros Territoriales (14 Deptos / Precios)',
            onPressed: _openAdvancedSearch,
          ),
          // Botón Alternar Niebla
          IconButton(
            icon: Icon(
              _isFogActive ? Icons.cloud_outlined : Icons.cloud_off_outlined,
              color: _isFogActive ? AppColors.cyan : AppColors.textSecondary,
              size: 20,
            ),
            tooltip: 'Alternar Niebla',
            onPressed: () {
              setState(() => _isFogActive = !_isFogActive);
            },
          ),
          // Botón Vista General El Salvador
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
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  /// Menú Desplegable con Sugerencias Tácticas en Tiempo Real
  Widget _buildSearchSuggestions(Color accentColor, bool isTabletOrLarger) {
    final results = _filteredPois;

    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: BoxConstraints(maxHeight: isTabletOrLarger ? 320 : 260),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cyan.withValues(alpha: 0.6), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.25),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: results.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_off_rounded, color: AppColors.textMuted, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'OBJETIVO NO LOCALIZADO',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Verifica el nombre o categoría en El Salvador.',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: results.length,
                separatorBuilder: (_, _) => Divider(
                  color: AppColors.surfaceBorder.withValues(alpha: 0.5),
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final poi = results[index];
                  final distance = _getDistanceInMeters(poi.location);
                  final distanceText = _formatDistance(distance);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Icon(poi.icon, color: accentColor, size: 20),
                    ),
                    title: Text(
                      poi.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                    subtitle: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            poi.category,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DIF: ${poi.difficulty}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.near_me_rounded, color: AppColors.cyan, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          distanceText,
                          style: const TextStyle(
                            color: AppColors.cyan,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectSearchResult(poi, accentColor, isTabletOrLarger),
                  );
                },
              ),
      ),
    );
  }

  /// Chip Táctico de Estado y Sincronización Superior
  Widget _buildStatusChip(Color accentColor, bool isTabletOrLarger) {
    if (_filterCriteria.isActive) {
      final dept = _filterCriteria.selectedDepartment;
      final zone = _filterCriteria.selectedZone;
      final price = _filterCriteria.selectedPriceRange;
      final difficulty = _filterCriteria.selectedDifficulty;
      final label = dept ?? zone ?? price ?? difficulty ?? 'FILTRADO';

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cyan, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.25),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_alt_rounded, color: AppColors.cyan, size: 15),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'FILTRO: ${label.toUpperCase()} (${_activeDisplayedPois.length} ATALAYAS)',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.cyan,
                  fontSize: isTabletOrLarger ? 11 : 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _filterCriteria = const TacticalFilterCriteria();
                });
              },
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, color: AppColors.cyan, size: 14),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isTabletOrLarger ? 16 : 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _userLocation != null ? AppColors.cyan : AppColors.gold,
              boxShadow: [
                BoxShadow(
                  color: (_userLocation != null ? AppColors.cyan : AppColors.gold).withValues(alpha: 0.7),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              _isLocatingUser
                  ? 'LOCALIZANDO OPERADOR (GPS)...'
                  : (!widget.gpsEnabled
                      ? 'GPS INACTIVO // CONFIGURAR EN AJUSTES'
                      : (_userProfile != null
                          ? '[${_userProfile!.role.toUpperCase()}] ${_userProfile!.fullName ?? _userProfile!.username ?? "AGENTE"} // GPS ACTIVO'
                          : (_userLocation != null
                              ? 'GPS ACTIVO // TAP MAPA = PIN'
                              : 'ENLACE TÁCTICO // EL SALVADOR'))),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _userLocation != null ? AppColors.cyan : AppColors.textSecondary,
                fontSize: isTabletOrLarger ? 11 : 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateBanner(bool isTabletOrLarger) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(
        horizontal: isTabletOrLarger ? 16 : 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.goldenOrange.withValues(alpha: 0.7), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: AppColors.goldenOrange, size: 16),
          SizedBox(width: 8),
          Flexible(
            child: Text(
              'NO HAY REGISTROS EN BASE DE DATOS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                fontFamily: 'monospace',
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
