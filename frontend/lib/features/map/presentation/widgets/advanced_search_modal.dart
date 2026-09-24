import 'package:flutter/material.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/map/services/location_service.dart';

/// Criterios de filtrado territorial y de costo para la búsqueda avanzada
class TacticalFilterCriteria {
  final String? selectedDepartment;
  final String? selectedZone;
  final String? selectedPriceRange;
  final String? selectedDifficulty;

  const TacticalFilterCriteria({
    this.selectedDepartment,
    this.selectedZone,
    this.selectedPriceRange,
    this.selectedDifficulty,
  });

  bool get isActive =>
      selectedDepartment != null ||
      selectedZone != null ||
      selectedPriceRange != null ||
      selectedDifficulty != null;

  TacticalFilterCriteria copyWith({
    String? selectedDepartment,
    String? selectedZone,
    String? selectedPriceRange,
    String? selectedDifficulty,
    bool clearDepartment = false,
    bool clearZone = false,
    bool clearPrice = false,
    bool clearDifficulty = false,
  }) {
    return TacticalFilterCriteria(
      selectedDepartment: clearDepartment ? null : (selectedDepartment ?? this.selectedDepartment),
      selectedZone: clearZone ? null : (selectedZone ?? this.selectedZone),
      selectedPriceRange: clearPrice ? null : (selectedPriceRange ?? this.selectedPriceRange),
      selectedDifficulty: clearDifficulty ? null : (selectedDifficulty ?? this.selectedDifficulty),
    );
  }
}

/// Modal de Búsqueda Avanzada con división territorial real de El Salvador, precios y categorías
class AdvancedSearchModal extends StatefulWidget {
  final List<TacticalPoi> allPois;
  final TacticalFilterCriteria initialCriteria;
  final void Function(TacticalFilterCriteria criteria, List<TacticalPoi> filteredResults) onApplyFilters;
  final void Function(TacticalPoi selectedPoi) onSelectPoi;

  const AdvancedSearchModal({
    super.key,
    required this.allPois,
    required this.initialCriteria,
    required this.onApplyFilters,
    required this.onSelectPoi,
  });

  /// Método estático conveniente para desplegar el modal táctico
  static Future<void> show(
    BuildContext context, {
    required List<TacticalPoi> allPois,
    required TacticalFilterCriteria currentCriteria,
    required void Function(TacticalFilterCriteria criteria, List<TacticalPoi> filteredResults) onApplyFilters,
    required void Function(TacticalPoi selectedPoi) onSelectPoi,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AdvancedSearchModal(
        allPois: allPois,
        initialCriteria: currentCriteria,
        onApplyFilters: onApplyFilters,
        onSelectPoi: onSelectPoi,
      ),
    );
  }

  @override
  State<AdvancedSearchModal> createState() => _AdvancedSearchModalState();
}

class _AdvancedSearchModalState extends State<AdvancedSearchModal> {
  late TacticalFilterCriteria _criteria;

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

  // Sectores y zonas geográficas estratégicas
  static const List<String> zones = [
    'Zona Occidental',
    'Zona Central',
    'Zona Paracentral',
    'Zona Oriental',
    'Sector Costero / Surf City',
    'Cadena Volcánica',
  ];

  // Rangos de costo / precio
  static const List<String> priceRanges = [
    'Gratis',
    'Económico (\$)',
    'Moderado (\$\$)',
    'Exclusivo (\$\$\$)',
  ];

  // Niveles de dificultad táctica
  static const List<String> difficulties = [
    'BAJA',
    'MEDIA',
    'ALTA',
    'ÉPICA',
  ];

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
  }

  List<TacticalPoi> get _filteredResults {
    return widget.allPois.where((poi) {
      if (_criteria.selectedDepartment != null &&
          poi.department.toLowerCase() != _criteria.selectedDepartment!.toLowerCase()) {
        return false;
      }
      if (_criteria.selectedZone != null &&
          poi.zone.toLowerCase() != _criteria.selectedZone!.toLowerCase()) {
        return false;
      }
      if (_criteria.selectedPriceRange != null &&
          !poi.priceRange.toLowerCase().contains(_criteria.selectedPriceRange!.toLowerCase().replaceAll(RegExp(r'[\(\$\)]'), '').trim())) {
        return false;
      }
      if (_criteria.selectedDifficulty != null &&
          poi.difficulty.toUpperCase() != _criteria.selectedDifficulty!.toUpperCase()) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);
    final results = _filteredResults;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.7),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.15),
            blurRadius: 20,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // ─── CABECERA DEL MODAL TÁCTICO ─────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 16, 12),
              child: Column(
                children: [
                  // Tirador táctico
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.cyan.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.cyan, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FILTROS TERRITORIALES // EL SALVADOR',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'DIVISIÓN POR DEPARTAMENTOS, ZONAS Y COSTO',
                              style: TextStyle(
                                color: AppColors.cyan,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Botón de Cierre Táctico "X"
                      IconButton(
                        tooltip: 'Cerrar Filtros',
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.surfaceElevated,
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),

            // ─── CONTENIDO CON FILTROS Y RESULTADOS EN VIVO ─────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isTabletOrLarger ? 32 : 18,
                  vertical: 16,
                ),
                children: [
                  // 1. FILTRO DE DEPARTAMENTO (14 DEPARTAMENTOS)
                  _buildSectionTitle('DEPARTAMENTO (14 DIVISIONES SV)', Icons.map_outlined),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'TODOS',
                        isSelected: _criteria.selectedDepartment == null,
                        onTap: () => setState(() {
                          _criteria = _criteria.copyWith(clearDepartment: true);
                        }),
                      ),
                      ...departments.map((dept) => _buildChip(
                            label: dept,
                            isSelected: _criteria.selectedDepartment == dept,
                            onTap: () => setState(() {
                              _criteria = _criteria.copyWith(
                                selectedDepartment: _criteria.selectedDepartment == dept ? null : dept,
                                clearDepartment: _criteria.selectedDepartment == dept,
                              );
                            }),
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 2. FILTRO DE ZONA GEOGRÁFICA / SECTOR
                  _buildSectionTitle('SECTOR / ZONA TÁCTICA', Icons.explore_rounded),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'TODAS',
                        isSelected: _criteria.selectedZone == null,
                        onTap: () => setState(() {
                          _criteria = _criteria.copyWith(clearZone: true);
                        }),
                      ),
                      ...zones.map((zone) => _buildChip(
                            label: zone,
                            isSelected: _criteria.selectedZone == zone,
                            onTap: () => setState(() {
                              _criteria = _criteria.copyWith(
                                selectedZone: _criteria.selectedZone == zone ? null : zone,
                                clearZone: _criteria.selectedZone == zone,
                              );
                            }),
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 3. FILTRO DE RANGO DE PRECIO / ACCESO
                  _buildSectionTitle('COSTO DE INGRESO / RANGO', Icons.monetization_on_outlined),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'TODOS',
                        isSelected: _criteria.selectedPriceRange == null,
                        onTap: () => setState(() {
                          _criteria = _criteria.copyWith(clearPrice: true);
                        }),
                      ),
                      ...priceRanges.map((price) => _buildChip(
                            label: price,
                            isSelected: _criteria.selectedPriceRange == price,
                            onTap: () => setState(() {
                              _criteria = _criteria.copyWith(
                                selectedPriceRange: _criteria.selectedPriceRange == price ? null : price,
                                clearPrice: _criteria.selectedPriceRange == price,
                              );
                            }),
                          )),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // 4. FILTRO DE DIFICULTAD
                  _buildSectionTitle('DIFICULTAD / EXIGENCIA', Icons.military_tech_outlined),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'TODAS',
                        isSelected: _criteria.selectedDifficulty == null,
                        onTap: () => setState(() {
                          _criteria = _criteria.copyWith(clearDifficulty: true);
                        }),
                      ),
                      ...difficulties.map((diff) => _buildChip(
                            label: diff,
                            isSelected: _criteria.selectedDifficulty == diff,
                            onTap: () => setState(() {
                              _criteria = _criteria.copyWith(
                                selectedDifficulty: _criteria.selectedDifficulty == diff ? null : diff,
                                clearDifficulty: _criteria.selectedDifficulty == diff,
                              );
                            }),
                          )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // RESULTADOS COINCIDENTES EN VIVO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'PUNTOS COINCIDENTES (${results.length})',
                        style: const TextStyle(
                          color: AppColors.cyan,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (_criteria.isActive)
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.error,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          icon: const Icon(Icons.restart_alt_rounded, size: 14),
                          label: const Text('RESETEAR', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          onPressed: () {
                            setState(() {
                              _criteria = const TacticalFilterCriteria();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (results.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay puntos de interés que coincidan con los filtros seleccionados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: results.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) {
                        final poi = results[index];
                        return _buildMiniResultTile(poi);
                      },
                    ),
                ],
              ),
            ),

            // ─── BARRA DE ACCIÓN INFERIOR ───────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        foregroundColor: const Color(0xFF001520),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      icon: const Icon(Icons.filter_alt_rounded, size: 18),
                      label: Text(
                        'APLICAR AL MAPA (${results.length})',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      onPressed: () {
                        widget.onApplyFilters(_criteria, results);
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.cyan),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyan.withValues(alpha: 0.22)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppColors.cyan
                : AppColors.surfaceBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.cyan : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMiniResultTile(TacticalPoi poi) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.of(context).pop();
        widget.onSelectPoi(poi);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            Icon(poi.icon, size: 18, color: AppColors.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${poi.department}  •  ${poi.zone}  •  ${poi.priceRange}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
