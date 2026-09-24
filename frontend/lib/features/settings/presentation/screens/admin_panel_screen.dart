import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/auth/presentation/widgets/tactical_alert_dialog.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/events/models/tactical_event.dart';
import 'package:vertice/features/events/services/events_service.dart';
import 'package:vertice/features/map/services/location_service.dart';

/// Pantalla del Panel de Control Administrativo Integral (Exclusivo para Usuarios con Rol Admin).
/// Provee 4 módulos de mando:
/// 1. OPERADORES: Nómina táctica y control de suspensiones/baneos en tiempo real.
/// 2. EVENTOS: Gestión CRUD de la Agenda Táctica de El Salvador.
/// 3. ATALAYAS: Gestión CRUD de Puntos de Interés / Atalayas con Supabase.
/// 4. ESTADÍSTICAS: Métricas consolidadas del sistema y desglose territorial por departamento.
class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final AuthService _authService = AuthService();
  final EventsService _eventsService = EventsService();
  final LocationService _locationService = LocationService();

  final TextEditingController _searchController = TextEditingController();

  List<UserProfile> _allProfiles = [];
  List<UserProfile> _filteredProfiles = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _updatingUserId;

  // 14 Departamentos oficiales de El Salvador
  static const List<String> departments = [
    'Ahuachapán',
    'Cabañas',
    'Chalatenango',
    'Cuscatlán',
    'La Libertad',
    'La Paz',
    'La Unión',
    'Morazán',
    'San Miguel',
    'San Salvador',
    'San Vicente',
    'Santa Ana',
    'Sonsonate',
    'Usulután',
  ];

  static const List<String> geographicZones = [
    'Zona Occidental',
    'Zona Central',
    'Zona Paracentral',
    'Zona Oriental',
    'Sector Costero / Surf City',
    'Cadena Volcánica',
  ];

  static const List<String> priceRanges = [
    'Entrada Gratuita',
    'Económico (\$)',
    'Moderado (\$\$)',
    'Exclusivo (\$\$\$)',
  ];

  static const List<String> difficulties = [
    'FÁCIL',
    'MODERADO',
    'DIFÍCIL',
    'EXPERTO',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchProfiles();
    _eventsService.fetchEvents();
    _locationService.fetchLocations();
    _searchController.addListener(_filterProfiles);
  }

  String _mapPriceCategoryFromText(String price) {
    final p = price.toUpperCase();
    if (p.contains('GRAT') || p.contains('LIBRE') || p.contains('0')) return 'GRATUITO';
    if (p.contains('EXCLUSIV') || p.contains('\$\$\$')) return 'EXCLUSIVO';
    if (p.contains('MODERAD') || p.contains('\$\$')) return 'MODERADO';
    return 'ECONÓMICO';
  }

  double _mapPriceAmountFromText(String price) {
    final matches = RegExp(r'[0-9]+(\.[0-9]+)?').firstMatch(price);
    if (matches != null) {
      return double.tryParse(matches.group(0) ?? '') ?? 0.00;
    }
    return 0.00;
  }

  String _mapPriceRangeToCategory(String range) {
    final r = range.toUpperCase();
    if (r.contains('GRAT') || r.contains('LIBRE')) return 'GRATUITO';
    if (r.contains('EXCLUSIV') || r.contains('\$\$\$')) return 'EXCLUSIVO';
    if (r.contains('MODERAD') || r.contains('\$\$')) return 'MODERADO';
    return 'ECONÓMICO';
  }

  double _mapPriceRangeToFee(String range) {
    final cat = _mapPriceRangeToCategory(range);
    switch (cat) {
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

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profiles = await _authService.getAllProfiles();
      if (!mounted) return;
      setState(() {
        _allProfiles = profiles;
        _isLoading = false;
      });
      _filterProfiles();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al sincronizar operadores: $e';
      });
    }
  }

  void _filterProfiles() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProfiles = List.from(_allProfiles);
      } else {
        _filteredProfiles = _allProfiles.where((p) {
          final name = (p.fullName ?? '').toLowerCase();
          final username = (p.username ?? '').toLowerCase();
          final email = (p.email ?? '').toLowerCase();
          return name.contains(query) ||
              username.contains(query) ||
              email.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _handleToggleBan(UserProfile targetUser) async {
    final currentUserId = _authService.currentUser?.id;

    if (targetUser.id == currentUserId) {
      TacticalAlert.show(
        context,
        title: 'ACCIÓN DENEGADA',
        message: 'No puedes suspender tu propia cuenta de Administrador principal.',
        type: AlertType.warning,
      );
      return;
    }

    final willBan = !targetUser.isBanned;
    final actionWord = willBan ? 'SUSPENDER' : 'REACTIVAR';
    final actionColor = willBan ? AppColors.error : AppColors.success;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: actionColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            Icon(
              willBan ? Icons.gavel_rounded : Icons.check_circle_outline_rounded,
              color: actionColor,
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$actionWord ACCESO',
                style: TextStyle(
                  color: actionColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              willBan
                  ? '¿Confirmas la suspensión inmediata del operador @${targetUser.username ?? targetUser.id}?'
                  : '¿Confirmas la reactivación del acceso al operador @${targetUser.username ?? targetUser.id}?',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: actionColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: actionColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: actionColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      willBan
                          ? 'El operador no podrá iniciar sesión ni acceder al mapa.'
                          : 'El operador podrá volver a sincronizar enlaces y datos.',
                      style: TextStyle(
                        color: actionColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: actionColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('CONFIRMAR $actionWord'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _updatingUserId = targetUser.id);

    try {
      await _authService.toggleUserBan(targetUser.id, targetUser.isBanned);
      if (!mounted) return;

      setState(() {
        final index = _allProfiles.indexWhere((p) => p.id == targetUser.id);
        if (index != -1) {
          _allProfiles[index] = _allProfiles[index].copyWith(isBanned: willBan);
        }
      });
      _filterProfiles();

      TacticalAlert.show(
        context,
        title: willBan ? 'ACCESO SUSPENDIDO' : 'ACCESO REACTIVADO',
        message:
            'El estado del operador @${targetUser.username ?? "usuario"} ha sido actualizado en la red.',
        type: willBan ? AlertType.warning : AlertType.success,
      );
    } catch (e) {
      if (!mounted) return;
      TacticalAlert.show(
        context,
        title: 'ERROR DE SINCRONIZACIÓN',
        message: 'No se pudo actualizar el estado de suspensión: $e',
        type: AlertType.error,
      );
    } finally {
      if (mounted) setState(() => _updatingUserId = null);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // DIÁLOGOS DE GESTIÓN DE EVENTOS TÁCTICOS
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showEventFormDialog({TacticalEvent? eventToEdit}) async {
    final isEditing = eventToEdit != null;
    final titleCtrl = TextEditingController(text: eventToEdit?.title ?? '');
    final descCtrl = TextEditingController(text: eventToEdit?.description ?? '');
    final locNameCtrl =
        TextEditingController(text: eventToEdit?.locationName ?? '');
    final priceCtrl =
        TextEditingController(text: eventToEdit?.entryPrice ?? 'Entrada Libre');
    final latCtrl = TextEditingController(
        text: eventToEdit?.coordinates.latitude.toString() ?? '13.6983');
    final lngCtrl = TextEditingController(
        text: eventToEdit?.coordinates.longitude.toString() ?? '-89.1914');

    String selectedDept = eventToEdit?.department ?? 'San Salvador';
    String selectedCategory = eventToEdit?.category ?? 'EXPEDICIÓN TÁCTICA';
    TacticalEventStatus selectedStatus =
        eventToEdit?.status ?? TacticalEventStatus.upcoming;
    DateTime selectedDate = eventToEdit?.date ?? DateTime.now().add(const Duration(days: 3));

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cyan, width: 1.2),
            ),
            title: Text(
              isEditing ? 'EDITAR EVENTO TÁCTICO' : 'NUEVO EVENTO TÁCTICO',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(titleCtrl, 'Título del Evento', Icons.title_rounded),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Categoría',
                      value: selectedCategory,
                      items: const [
                        'EXPEDICIÓN TÁCTICA',
                        'FESTIVAL CULTURAL',
                        'COMPETENCIA DEPORTIVA',
                        'CONFERENCIA TECNOLÓGICA',
                        'SENDERISMO NOCTURNO',
                        'EVENTO GASTRONÓMICO',
                      ],
                      onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Departamento',
                      value: selectedDept,
                      items: departments,
                      onChanged: (v) => setDialogState(() => selectedDept = v!),
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(locNameCtrl, 'Lugar Específico / Municipio', Icons.pin_drop_rounded),
                    const SizedBox(height: 10),
                    _buildTextField(priceCtrl, 'Costo de Entrada', Icons.attach_money_rounded),
                    const SizedBox(height: 10),
                    _buildDropdown<TacticalEventStatus>(
                      label: 'Estado del Evento',
                      value: selectedStatus,
                      items: TacticalEventStatus.values,
                      itemLabel: (s) => s.label,
                      onChanged: (v) => setDialogState(() => selectedStatus = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            latCtrl,
                            'Latitud',
                            Icons.explore_rounded,
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            lngCtrl,
                            'Longitud',
                            Icons.explore_rounded,
                            isNumeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(descCtrl, 'Descripción Táctica', Icons.description_rounded, maxLines: 3),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) return;

                  final lat = double.tryParse(latCtrl.text.trim()) ?? 13.6983;
                  final lng = double.tryParse(lngCtrl.text.trim()) ?? -89.1914;
                  final rawPrice = priceCtrl.text.trim();
                  final priceCategory = _mapPriceCategoryFromText(rawPrice);
                  final priceAmount = _mapPriceAmountFromText(rawPrice);

                  final newEvent = TacticalEvent(
                    id: eventToEdit?.id ?? 'event-${DateTime.now().millisecondsSinceEpoch}',
                    title: title,
                    category: selectedCategory,
                    date: selectedDate,
                    time: eventToEdit?.time ?? '08:00 - 16:00',
                    locationName: locNameCtrl.text.trim().isEmpty
                        ? 'El Salvador'
                        : locNameCtrl.text.trim(),
                    department: selectedDept,
                    coordinates: LatLng(lat, lng),
                    price: rawPrice.isEmpty ? 'Gratis' : rawPrice,
                    priceCategory: priceCategory,
                    priceAmount: priceAmount,
                    status: selectedStatus,
                    description: descCtrl.text.trim().isEmpty
                        ? 'Operación táctica programada en territorio de El Salvador.'
                        : descCtrl.text.trim(),
                    icon: Icons.event_rounded,
                  );

                  Navigator.of(ctx).pop();

                  if (isEditing) {
                    await _eventsService.updateEvent(newEvent);
                  } else {
                    await _eventsService.addEvent(newEvent);
                  }

                  if (!mounted) return;
                  TacticalAlert.show(
                    context,
                    title: isEditing ? 'EVENTO ACTUALIZADO' : 'EVENTO PUBLICADO',
                    message: 'La agenda de eventos ha sido sincronizada con Supabase.',
                    type: AlertType.success,
                  );
                },
                child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'PUBLICAR EVENTO'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // DIÁLOGOS DE GESTIÓN DE PUNTOS DE INTERÉS / ATALAYAS
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _showPoiFormDialog({TacticalPoi? poiToEdit}) async {
    final isEditing = poiToEdit != null;
    final nameCtrl = TextEditingController(text: poiToEdit?.name ?? '');
    final descCtrl = TextEditingController(text: poiToEdit?.description ?? '');
    final catCtrl = TextEditingController(text: poiToEdit?.category ?? 'ATALAYA NATURAL');
    final latCtrl = TextEditingController(
        text: poiToEdit?.location.latitude.toString() ?? '13.6983');
    final lngCtrl = TextEditingController(
        text: poiToEdit?.location.longitude.toString() ?? '-89.1914');

    String selectedDept = poiToEdit?.department ?? 'San Salvador';
    String selectedZone = poiToEdit?.zone ?? 'Zona Central';
    String selectedPrice = poiToEdit?.priceRange ?? 'Entrada Gratuita';
    String selectedDiff = poiToEdit?.difficulty ?? 'MODERADO';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.cyan, width: 1.2),
            ),
            title: Text(
              isEditing ? 'EDITAR ATALAYA / POI' : 'NUEVA ATALAYA / POI',
              style: const TextStyle(
                color: AppColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(nameCtrl, 'Nombre del Sitio Turístico', Icons.place_rounded),
                    const SizedBox(height: 10),
                    _buildTextField(catCtrl, 'Categoría Táctica', Icons.category_rounded),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Departamento (14 Deptos)',
                      value: selectedDept,
                      items: departments,
                      onChanged: (v) => setDialogState(() => selectedDept = v!),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Zona Geográfica',
                      value: selectedZone,
                      items: geographicZones,
                      onChanged: (v) => setDialogState(() => selectedZone = v!),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Rango de Precio',
                      value: selectedPrice,
                      items: priceRanges,
                      onChanged: (v) => setDialogState(() => selectedPrice = v!),
                    ),
                    const SizedBox(height: 10),
                    _buildDropdown<String>(
                      label: 'Dificultad de Acceso',
                      value: selectedDiff,
                      items: difficulties,
                      onChanged: (v) => setDialogState(() => selectedDiff = v!),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            latCtrl,
                            'Latitud',
                            Icons.explore_rounded,
                            isNumeric: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildTextField(
                            lngCtrl,
                            'Longitud',
                            Icons.explore_rounded,
                            isNumeric: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(descCtrl, 'Descripción del Punto', Icons.description_rounded, maxLines: 3),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  if (name.isEmpty) return;

                  final lat = double.tryParse(latCtrl.text.trim()) ?? 13.6983;
                  final lng = double.tryParse(lngCtrl.text.trim()) ?? -89.1914;
                  final priceCategory = _mapPriceRangeToCategory(selectedPrice);
                  final entryFee = _mapPriceRangeToFee(selectedPrice);

                  final newPoi = TacticalPoi(
                    id: poiToEdit?.id ?? 'poi-${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    category: catCtrl.text.trim().isEmpty ? 'ATALAYA' : catCtrl.text.trim().toUpperCase(),
                    location: LatLng(lat, lng),
                    description: descCtrl.text.trim().isEmpty
                        ? 'Punto de interés turístico y atalaya en El Salvador.'
                        : descCtrl.text.trim(),
                    difficulty: selectedDiff,
                    icon: Icons.castle_rounded,
                    department: selectedDept,
                    zone: selectedZone,
                    priceCategory: priceCategory,
                    entryFee: entryFee,
                    priceRange: selectedPrice,
                  );

                  Navigator.of(ctx).pop();

                  if (isEditing) {
                    await _locationService.updatePoi(newPoi);
                  } else {
                    await _locationService.addPoi(newPoi);
                  }

                  if (!mounted) return;
                  TacticalAlert.show(
                    context,
                    title: isEditing ? 'ATALAYA ACTUALIZADA' : 'ATALAYA REGISTRADA',
                    message: 'El punto de interés ha sido sincronizado con Supabase.',
                    type: AlertType.success,
                  );
                },
                child: Text(isEditing ? 'GUARDAR CAMBIOS' : 'REGISTRAR ATALAYA'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // INTERFAZ PRINCIPAL CON TABBAR TÁCTICO
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.cyan, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GEOTURISMO // PANEL ADMIN',
              style: TextStyle(
                color: AppColors.cyan,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              'ADMINISTRACIÓN TÁCTICA // EL SALVADOR',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.cyan,
          indicatorWeight: 3,
          labelColor: AppColors.cyan,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            fontFamily: 'monospace',
          ),
          tabs: const [
            Tab(icon: Icon(Icons.people_alt_rounded, size: 18), text: 'OPERADORES'),
            Tab(icon: Icon(Icons.event_note_rounded, size: 18), text: 'EVENTOS'),
            Tab(icon: Icon(Icons.castle_rounded, size: 18), text: 'ATALAYAS'),
            Tab(icon: Icon(Icons.analytics_rounded, size: 18), text: 'ESTADÍSTICAS'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 0: Gestión de Operadores (Baneos / Suspensiones)
          _buildOperatorsTab(),
          // Tab 1: Gestión de Eventos Tácticos
          _buildEventsTab(),
          // Tab 2: Gestión de Atalayas / Puntos de Interés
          _buildPoisTab(),
          // Tab 3: Estadísticas del Sistema y Desglose por Departamento
          _buildStatisticsTab(),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 0: OPERADORES
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildOperatorsTab() {
    final isTabletOrLarger = !Responsive.isMobile(context);
    final totalCount = _allProfiles.length;
    final activeCount = _allProfiles.where((p) => !p.isBanned).length;
    final bannedCount = _allProfiles.where((p) => p.isBanned).length;

    return RefreshIndicator(
      onRefresh: _fetchProfiles,
      color: AppColors.cyan,
      backgroundColor: AppColors.surface,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isTabletOrLarger ? 32 : 16,
          vertical: 20,
        ),
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'TOTAL',
                  value: totalCount.toString(),
                  icon: Icons.people_alt_rounded,
                  accentColor: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'ACTIVOS',
                  value: activeCount.toString(),
                  icon: Icons.verified_user_rounded,
                  accentColor: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: 'SUSPENDIDOS',
                  value: bannedCount.toString(),
                  icon: Icons.block_rounded,
                  accentColor: AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              cursorColor: AppColors.cyan,
              decoration: InputDecoration(
                hintText: 'Filtrar operador por nombre, @username o correo...',
                hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cyan, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          _filterProfiles();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            )
          else if (_errorMessage != null)
            _buildErrorBox(_errorMessage!)
          else if (_filteredProfiles.isEmpty)
            _buildEmptyBox('NO SE ENCONTRARON OPERADORES')
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredProfiles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final profile = _filteredProfiles[index];
                return _buildOperatorCard(profile);
              },
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 1: EVENTOS TÁCTICOS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildEventsTab() {
    return ValueListenableBuilder<List<TacticalEvent>>(
      valueListenable: _eventsService.eventsNotifier,
      builder: (context, events, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Botón de acción superior
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL EVENTOS REGISTRADOS: ${events.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text(
                    'NUEVO EVENTO',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => _showEventFormDialog(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (events.isEmpty)
              _buildEmptyBox('NO HAY REGISTROS EN BASE DE DATOS')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildAdminEventCard(event);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdminEventCard(TacticalEvent event) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
            ),
            child: Icon(event.icon, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: event.status.badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: event.status.badgeColor, width: 0.8),
                      ),
                      child: Text(
                        event.status.label,
                        style: TextStyle(
                          color: event.status.badgeColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${event.department} // ${event.locationName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${event.formattedDate} · ${event.timeString} · ${event.entryPrice}',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.cyan, size: 20),
                tooltip: 'Editar Evento',
                onPressed: () => _showEventFormDialog(eventToEdit: event),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Eliminar Evento',
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(event.title);
                  if (confirm == true) {
                    await _eventsService.deleteEvent(event.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 2: ATALAYAS / POIS
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildPoisTab() {
    return ValueListenableBuilder<List<TacticalPoi>>(
      valueListenable: _locationService.poisNotifier,
      builder: (context, pois, _) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ATALAYAS DISPONIBLES: ${pois.length}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    fontFamily: 'monospace',
                  ),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                  label: const Text(
                    'NUEVA ATALAYA',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => _showPoiFormDialog(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (pois.isEmpty)
              _buildEmptyBox('NO HAY REGISTROS EN BASE DE DATOS')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pois.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final poi = pois[index];
                  return _buildAdminPoiCard(poi);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildAdminPoiCard(TacticalPoi poi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
            ),
            child: Icon(poi.icon, color: AppColors.cyan, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.cyan, width: 0.8),
                      ),
                      child: Text(
                        poi.department,
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      poi.zone,
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  poi.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${poi.category} · ${poi.priceRange} · DIF: ${poi.difficulty}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppColors.cyan, size: 20),
                tooltip: 'Editar Atalaya',
                onPressed: () => _showPoiFormDialog(poiToEdit: poi),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                tooltip: 'Eliminar Atalaya',
                onPressed: () async {
                  final confirm = await _showDeleteConfirmation(poi.name);
                  if (confirm == true) {
                    await _locationService.deletePoi(poi.id);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // TAB 3: ESTADÍSTICAS DEL SISTEMA Y DESGLOSE TERRITORIAL
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildStatisticsTab() {
    final pois = _locationService.poisNotifier.value;
    final events = _eventsService.eventsNotifier.value;
    final totalUsers = _allProfiles.length;
    final bannedUsers = _allProfiles.where((p) => p.isBanned).length;
    final activeUsers = totalUsers - bannedUsers;

    // Conteo por los 14 departamentos
    final Map<String, int> deptCounts = {};
    for (final d in departments) {
      deptCounts[d] = 0;
    }
    for (final p in pois) {
      final dept = p.department;
      if (deptCounts.containsKey(dept)) {
        deptCounts[dept] = (deptCounts[dept] ?? 0) + 1;
      }
    }

    final maxDeptCount = deptCounts.values.fold<int>(1, (max, v) => v > max ? v : max);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Métricas Generales
        const Text(
          'MÉTRICAS CLAVE DEL SISTEMA',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'USUARIOS',
                value: totalUsers.toString(),
                icon: Icons.people_outline_rounded,
                accentColor: AppColors.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'EVENTOS',
                value: events.length.toString(),
                icon: Icons.event_available_rounded,
                accentColor: AppColors.gold,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildMetricCard(
                title: 'ATALAYAS',
                value: pois.length.toString(),
                icon: Icons.castle_rounded,
                accentColor: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Resumen de Operadores
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ESTADO DE NÓMINA OPERATIVA',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Operadores Activos: $activeUsers',
                      style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text('Operadores Suspendidos: $bannedUsers',
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: totalUsers > 0 ? (activeUsers / totalUsers) : 1.0,
                backgroundColor: AppColors.error.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Desglose Territorial por los 14 Departamentos
        const Text(
          'DISTRIBUCIÓN DE ATALAYAS POR DEPARTAMENTO (EL SALVADOR)',
          style: TextStyle(
            color: AppColors.cyan,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: 12),

        ...departments.map((dept) {
          final count = deptCounts[dept] ?? 0;
          final ratio = count / maxDeptCount;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: count > 0 ? AppColors.cyan.withValues(alpha: 0.3) : AppColors.surfaceBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        dept.toUpperCase(),
                        style: TextStyle(
                          color: count > 0 ? AppColors.textPrimary : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$count ${count == 1 ? "Punto" : "Puntos"}',
                        style: TextStyle(
                          color: count > 0 ? AppColors.cyan : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: AppColors.surface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      count > 0 ? AppColors.cyan : AppColors.textMuted.withValues(alpha: 0.3),
                    ),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // WIDGETS AUXILIARES
  // ══════════════════════════════════════════════════════════════════════

  Widget _buildOperatorCard(UserProfile profile) {
    final currentUserId = _authService.currentUser?.id;
    final isSelf = profile.id == currentUserId;
    final isUpdating = _updatingUserId == profile.id;
    final isBanned = profile.isBanned;
    final isAdmin = profile.isAdmin;

    final displayName = profile.fullName ?? profile.username ?? 'Operador';
    final username = profile.username ?? '—';
    final email = profile.email ?? '—';

    String initials = '?';
    final nameSource = profile.fullName ?? profile.username ?? '';
    if (nameSource.isNotEmpty) {
      final parts = nameSource.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = nameSource.substring(0, nameSource.length.clamp(1, 2)).toUpperCase();
      }
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isBanned
            ? AppColors.error.withValues(alpha: 0.05)
            : AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isBanned
              ? AppColors.error.withValues(alpha: 0.5)
              : AppColors.surfaceBorder,
          width: isBanned ? 1.2 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isBanned ? AppColors.error : AppColors.cyan,
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty
                  ? Image.network(
                      profile.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildInitialsBox(initials, isBanned),
                    )
                  : _buildInitialsBox(initials, isBanned),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (isSelf) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'TÚ',
                          style: TextStyle(
                            color: AppColors.cyan,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@$username · $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAdmin
                            ? AppColors.cyan.withValues(alpha: 0.12)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isAdmin
                              ? AppColors.cyan.withValues(alpha: 0.5)
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        isAdmin ? '[ADMIN]' : '[OPERADOR]',
                        style: TextStyle(
                          color: isAdmin ? AppColors.cyan : AppColors.textMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isBanned
                            ? AppColors.error.withValues(alpha: 0.15)
                            : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isBanned
                              ? AppColors.error.withValues(alpha: 0.5)
                              : AppColors.success.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        isBanned ? '[SUSPENDIDO]' : '[ACTIVO]',
                        style: TextStyle(
                          color: isBanned ? AppColors.error : AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isUpdating)
            const SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyan),
                ),
              ),
            )
          else if (isSelf)
            const Tooltip(
              message: 'No puedes suspender tu propia cuenta.',
              child: Icon(Icons.shield_rounded, color: AppColors.cyan, size: 22),
            )
          else
            IconButton(
              tooltip: isBanned ? 'Reactivar Acceso' : 'Suspender Acceso',
              icon: Icon(
                isBanned ? Icons.lock_open_rounded : Icons.lock_person_rounded,
                color: isBanned ? AppColors.success : AppColors.error,
                size: 22,
              ),
              onPressed: () => _handleToggleBan(profile),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  fontFamily: 'monospace',
                ),
              ),
              Icon(icon, color: accentColor, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumeric = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        prefixIcon: maxLines == 1 ? Icon(icon, color: AppColors.cyan, size: 18) : null,
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    String Function(T)? itemLabel,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            itemLabel != null ? itemLabel(item) : item.toString(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      dropdownColor: AppColors.surface,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteConfirmation(String itemName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
            SizedBox(width: 8),
            Text(
              'CONFIRMAR ELIMINACIÓN',
              style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w900),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar permanentemente "$itemName"?',
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCELAR', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('ELIMINAR'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialsBox(String initials, bool isBanned) {
    return Container(
      color: isBanned
          ? AppColors.error.withValues(alpha: 0.1)
          : AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: isBanned ? AppColors.error : AppColors.cyan,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: 12)),
    );
  }

  Widget _buildEmptyBox(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, color: AppColors.goldenOrange, size: 48),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
