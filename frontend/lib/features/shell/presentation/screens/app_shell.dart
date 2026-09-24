import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/events/presentation/screens/events_screen.dart';
import 'package:vertice/features/map/presentation/screens/map_screen.dart';
import 'package:vertice/features/settings/presentation/screens/settings_screen.dart';

/// Ubicación fija para el botón flotante central de recentrado GPS.
/// Evita que la aparición de SnackBars, modales o BottomSheets desplace
/// o eleve verticalmente el botón central fuera de su muesca (notch).
class FixedCenterDockedFabLocation extends FloatingActionButtonLocation {
  const FixedCenterDockedFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;
    // Anclado estrictamente a contentBottom sin sumar la altura del SnackBar o BottomSheet
    final double contentBottom = scaffoldGeometry.contentBottom;
    final double fabY =
        contentBottom - scaffoldGeometry.floatingActionButtonSize.height / 2.0;
    return Offset(fabX, fabY);
  }
}

/// Shell de Navegación Principal — Contenedor raíz post-autenticación.
/// Aloja el Mapa Táctico, la Agenda de Eventos y Ajustes/Perfil con BottomBar táctico.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  final _authService = AuthService();
  UserProfile? _userProfile;

  /// Controlador compartido del estado GPS. Cuando cambia a false, MapScreen
  /// no ejecuta nuevas peticiones de localización.
  final ValueNotifier<bool> _gpsEnabledNotifier = ValueNotifier<bool>(true);

  /// Clave global para invocar comandos tácticos directos sobre MapScreen (ej. recentrar cámara)
  final GlobalKey<MapScreenState> _mapScreenKey = GlobalKey<MapScreenState>();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _gpsEnabledNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final profile = await _authService.getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() => _userProfile = profile);
    }
  }

  /// Ejecuta el recentrado de cámara GPS en tiempo real sobre la pantalla del mapa
  void _onRecenterGpsPressed() {
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapScreenKey.currentState?.recenterOnUser();
    });
  }

  /// Navega al mapa y enfoca las coordenadas exactas de un evento
  void _onViewEventOnMap(LatLng coords, String eventName) {
    setState(() => _currentIndex = 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapScreenKey.currentState?.focusOnCoordinates(coords, eventName);
    });
  }

  /// Construye el avatar circular para el ítem de perfil en la barra inferior.
  Widget _buildProfileAvatar({required bool isSelected}) {
    final String? avatarUrl = _userProfile?.avatarUrl;
    final String? fullName = _userProfile?.fullName;
    final String? username = _userProfile?.username;

    // Obtener iniciales del nombre o username
    String initials = '?';
    final nameSource = fullName ?? username ?? '';
    if (nameSource.isNotEmpty) {
      final parts = nameSource.trim().split(' ');
      if (parts.length >= 2) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = nameSource.substring(0, nameSource.length.clamp(1, 2)).toUpperCase();
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? AppColors.cyan
              : AppColors.textMuted.withValues(alpha: 0.5),
          width: isSelected ? 2.0 : 1.2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: avatarUrl != null && avatarUrl.isNotEmpty
            ? Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _buildInitialsAvatar(initials, isSelected),
              )
            : _buildInitialsAvatar(initials, isSelected),
      ),
    );
  }

  Widget _buildInitialsAvatar(String initials, bool isSelected) {
    return Container(
      color: isSelected
          ? AppColors.cyan.withValues(alpha: 0.15)
          : AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: isSelected ? AppColors.cyan : AppColors.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // IndexedStack mantiene el estado de cada pantalla al cambiar de tab
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Mapa Táctico
          ValueListenableBuilder<bool>(
            valueListenable: _gpsEnabledNotifier,
            builder: (_, gpsEnabled, _) => MapScreen(
              key: _mapScreenKey,
              gpsEnabled: gpsEnabled,
            ),
          ),
          // Tab 1: Agenda de Eventos Tácticos
          EventsScreen(
            onViewOnMap: _onViewEventOnMap,
          ),
          // Tab 2: Ajustes y Perfil
          SettingsScreen(
            userProfile: _userProfile,
            gpsEnabledNotifier: _gpsEnabledNotifier,
            onProfileUpdated: _loadProfile,
          ),
        ],
      ),
      // Botón Central Recentrador GPS estilo radar táctico anclado en posición fija
      floatingActionButton: _buildCenterGpsButton(),
      floatingActionButtonLocation: const FixedCenterDockedFabLocation(),
      // Menú inferior cóncavo con notch central
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  /// Botón Central Táctico Flotante Orgánico para Recentrar el GPS
  Widget _buildCenterGpsButton() {
    return SizedBox(
      width: 60,
      height: 60,
      child: FloatingActionButton(
        elevation: 4,
        highlightElevation: 8,
        backgroundColor: AppColors.surface,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.turquoise, width: 2.0),
        ),
        onPressed: _onRecenterGpsPressed,
        tooltip: 'Recentrar GPS en Operador',
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.locationBlue.withValues(alpha: 0.35),
                AppColors.turquoise.withValues(alpha: 0.1),
                Colors.transparent,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.locationBlue.withValues(alpha: 0.25),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Retícula orgánica circular interna
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.turquoise.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                ),
              ),
              // Icono central de mira / GPS
              const Icon(
                Icons.my_location_rounded,
                color: AppColors.locationBlue,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Barra de navegación cóncava flotante con espacio central para el botón GPS
  Widget _buildBottomBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(
            color: AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyBlue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: AppColors.surface,
        elevation: 0,
        padding: EdgeInsets.zero,
        height: 64,
        child: SafeArea(
          top: false,
          child: MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.15,
            child: Row(
              children: [
                // Tab 0: Exploración / Mapa
                Expanded(
                  child: _buildNavItem(
                    index: 0,
                    icon: Icons.explore_rounded,
                    label: 'MAPA',
                  ),
                ),
                // Tab 1: Agenda de Eventos Tácticos
                Expanded(
                  child: _buildNavItem(
                    index: 1,
                    icon: Icons.event_note_rounded,
                    label: 'EVENTOS',
                  ),
                ),
                // Espacio cóncavo central reservado para el botón flotante GPS
                const SizedBox(width: 72),
                // Tab 2: Ajustes de Sistema
                Expanded(
                  child: _buildNavItem(
                    index: 2,
                    icon: Icons.tune_rounded,
                    label: 'AJUSTES',
                  ),
                ),
                // Perfil de Agente / Identidad
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _currentIndex = 2),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildProfileAvatar(isSelected: _currentIndex == 2),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PERFIL',
                            maxLines: 1,
                            style: TextStyle(
                              color: _currentIndex == 2
                                  ? AppColors.cyan
                                  : AppColors.textMuted,
                              fontSize: 9.5,
                              fontWeight: _currentIndex == 2
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.cyan.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? AppColors.cyan : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: isSelected ? AppColors.cyan : AppColors.textMuted,
                fontSize: 9.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

