import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/core/utils/responsive.dart';
import 'package:vertice/features/events/models/tactical_event.dart';
import 'package:vertice/features/events/services/events_service.dart';

/// Pantalla de Agenda de Eventos Tácticos, Culturales y Expediciones en El Salvador
class EventsScreen extends StatefulWidget {
  final void Function(LatLng coordinates, String eventName)? onViewOnMap;

  const EventsScreen({
    super.key,
    this.onViewOnMap,
  });

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final EventsService _eventsService = EventsService();
  final TextEditingController _searchController = TextEditingController();

  TacticalEventStatus? _selectedStatusFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _eventsService.fetchEvents();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TacticalEvent> _getFilteredEvents(List<TacticalEvent> allEvents) {
    return allEvents.where((e) {
      if (_selectedStatusFilter != null && e.status != _selectedStatusFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final title = e.title.toLowerCase();
        final desc = e.description.toLowerCase();
        final loc = e.locationName.toLowerCase();
        final dept = e.department.toLowerCase();
        final cat = e.category.toLowerCase();
        if (!title.contains(_searchQuery) &&
            !desc.contains(_searchQuery) &&
            !loc.contains(_searchQuery) &&
            !dept.contains(_searchQuery) &&
            !cat.contains(_searchQuery)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isTabletOrLarger = !Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.turquoise, width: 1.2),
              ),
              child: ClipOval(
                child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GEOTURISMO // EVENTOS',
                  style: TextStyle(
                    color: AppColors.turquoise,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'EXPEDICIONES, FESTIVALES & AGENDA // SV',
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
          ],
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: AppColors.turquoise.withValues(alpha: 0.2),
          ),
        ),
      ),
      body: ValueListenableBuilder<List<TacticalEvent>>(
        valueListenable: _eventsService.eventsNotifier,
        builder: (context, eventsList, _) {
          final filtered = _getFilteredEvents(eventsList);

          return ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletOrLarger ? 40 : 18,
              vertical: 18,
            ),
            children: [
              // ─── BARRA DE BÚSQUEDA DE EVENTOS ──────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  cursorColor: AppColors.cyan,
                  decoration: InputDecoration(
                    hintText: 'Buscar evento, festival, departamento...',
                    hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.cyan, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ─── SELECTOR DE ESTADO TÁCTICO (FILTROS) ─────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterPill(
                      label: 'TODOS (${eventsList.length})',
                      isSelected: _selectedStatusFilter == null,
                      onTap: () => setState(() => _selectedStatusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'EN VIVO',
                      color: AppColors.cyan,
                      isSelected: _selectedStatusFilter == TacticalEventStatus.live,
                      onTap: () => setState(() => _selectedStatusFilter = TacticalEventStatus.live),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'PRÓXIMOS',
                      color: AppColors.success,
                      isSelected: _selectedStatusFilter == TacticalEventStatus.upcoming,
                      onTap: () => setState(() => _selectedStatusFilter = TacticalEventStatus.upcoming),
                    ),
                    const SizedBox(width: 8),
                    _buildFilterPill(
                      label: 'FINALIZADOS',
                      color: AppColors.textMuted,
                      isSelected: _selectedStatusFilter == TacticalEventStatus.completed,
                      onTap: () => setState(() => _selectedStatusFilter = TacticalEventStatus.completed),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ─── LISTADO DE TARJETAS DE EVENTO ────────────────────────
              if (eventsList.isEmpty)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.cloud_off_rounded, color: AppColors.goldenOrange, size: 48),
                        SizedBox(height: 14),
                        Text(
                          'NO HAY REGISTROS EN BASE DE DATOS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'La base de datos de Supabase no contiene eventos registrados.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_busy_rounded, color: AppColors.textMuted, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'NO SE ENCONTRARON EVENTOS COINCIDENTES',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Prueba modificando los filtros de búsqueda.',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final event = filtered[index];
                    return _buildEventCard(event, isTabletOrLarger);
                  },
                ),

              const SizedBox(height: 80), // Margen para despejar la barra de navegación
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    final activeColor = color ?? AppColors.cyan;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.18) : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.surfaceBorder,
            width: isSelected ? 1.4 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(TacticalEvent event, bool isTabletOrLarger) {
    final statusColor = event.status.color;
    final formattedDate =
        '${event.date.day.toString().padLeft(2, '0')}/${event.date.month.toString().padLeft(2, '0')}/${event.date.year}';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: event.status == TacticalEventStatus.live
              ? AppColors.cyan.withValues(alpha: 0.8)
              : AppColors.surfaceBorder,
          width: event.status == TacticalEventStatus.live ? 1.5 : 1.0,
        ),
        boxShadow: [
          if (event.status == TacticalEventStatus.live)
            BoxShadow(
              color: AppColors.cyan.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera de la ficha del evento
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono táctico de la categoría
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cyan.withValues(alpha: 0.4)),
                  ),
                  child: Icon(event.icon, color: AppColors.cyan, size: 24),
                ),
                const SizedBox(width: 12),

                // Título y categoría
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Text(
                              event.category,
                              style: const TextStyle(
                                color: AppColors.cyan,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          // Badge de Estado Táctico
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  event.status.label,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'monospace',
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        event.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Descripción breve
            Text(
              event.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            // Metadatos: Fecha/Hora, Ubicación y Precio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_outlined, size: 15, color: AppColors.cyan),
                      const SizedBox(width: 6),
                      Text(
                        '$formattedDate (${event.time})',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          event.price,
                          style: const TextStyle(
                            color: AppColors.gold,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.error),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${event.locationName} • ${event.department}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Botón Táctico: "UBICACIÓN EN MAPA"
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan.withValues(alpha: 0.16),
                  foregroundColor: AppColors.cyan,
                  side: BorderSide(
                    color: AppColors.cyan.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.gps_fixed_rounded, size: 16),
                label: const Text(
                  'UBICACIÓN EN MAPA TÁCTICO',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                onPressed: () {
                  if (widget.onViewOnMap != null) {
                    widget.onViewOnMap!(event.coordinates, event.title);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
