import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/features/auth/presentation/widgets/tactical_alert_dialog.dart';
import 'package:vertice/features/map/services/location_service.dart';

/// Modal administrativo para la captura y registro de nuevas Atalayas y Puntos Turísticos en El Salvador.
/// EXCLUSIVO PARA ADMINISTRADORES (RBAC: profile.role == 'admin').
class AddLocationModal extends StatefulWidget {
  final LatLng initialCoordinates;

  const AddLocationModal({
    super.key,
    required this.initialCoordinates,
  });

  static Future<TacticalPoi?> show(
    BuildContext context, {
    required LatLng initialCoordinates,
  }) {
    return showDialog<TacticalPoi>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddLocationModal(initialCoordinates: initialCoordinates),
    );
  }

  @override
  State<AddLocationModal> createState() => _AddLocationModalState();
}

class _AddLocationModalState extends State<AddLocationModal> {
  final _formKey = GlobalKey<FormState>();
  final _locationService = LocationService();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _feeController;

  bool _isSaving = false;
  bool _isLocatingGps = false;

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

  static const List<String> categories = [
    'ATALAYA NATURAL',
    'ZONA ARQUEOLÓGICA',
    'NÚCLEO URBANO',
    'SECTOR COSTERO',
    'RESERVA DE SELVA',
    'CRÁTER ACUÁTICO',
    'PATRIMONIO HISTÓRICO',
    'MIRADOR TÁCTICO',
  ];

  static const List<String> priceCategories = [
    'GRATUITO',
    'ECONÓMICO',
    'MODERADO',
    'EXCLUSIVO',
  ];

  static const List<String> difficulties = [
    'BAJA',
    'MEDIA',
    'ALTA',
    'ÉPICA',
  ];

  late String _selectedDept;
  late String _selectedZone;
  late String _selectedCategory;
  late String _selectedPriceCategory;
  late String _selectedDifficulty;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descController = TextEditingController();
    _latController = TextEditingController(
      text: widget.initialCoordinates.latitude.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: widget.initialCoordinates.longitude.toStringAsFixed(6),
    );
    _feeController = TextEditingController(text: '0.00');

    _selectedCategory = categories.first;
    _selectedDept = 'San Salvador';
    _selectedZone = 'Zona Central';
    _selectedPriceCategory = 'GRATUITO';
    _selectedDifficulty = 'MEDIA';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _refreshGpsPosition() async {
    setState(() => _isLocatingGps = true);
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 6),
        ),
      );
      if (mounted) {
        setState(() {
          _latController.text = pos.latitude.toStringAsFixed(6);
          _lngController.text = pos.longitude.toStringAsFixed(6);
          _isLocatingGps = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLocatingGps = false);
      }
    }
  }

  Future<void> _saveLocation() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      TacticalAlert.show(
        context,
        title: 'COORDENADAS INVÁLIDAS',
        message: 'Por favor ingresa valores numéricos válidos de latitud y longitud.',
        type: AlertType.error,
      );
      return;
    }

    final entryFee = double.tryParse(_feeController.text.trim()) ?? 0.00;
    final name = _nameController.text.trim();
    final description = _descController.text.trim().isEmpty
        ? 'Punto táctico de interés turístico en El Salvador.'
        : _descController.text.trim();

    final priceRange = entryFee <= 0.0 || _selectedPriceCategory == 'GRATUITO'
        ? 'Gratis'
        : '\$${entryFee.toStringAsFixed(2)} USD';

    setState(() => _isSaving = true);

    final newPoi = TacticalPoi(
      id: 'poi-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      category: _selectedCategory,
      location: LatLng(lat, lng),
      description: description,
      difficulty: _selectedDifficulty,
      icon: _getIconForCategory(_selectedCategory),
      department: _selectedDept,
      zone: _selectedZone,
      priceCategory: _selectedPriceCategory,
      entryFee: entryFee,
      priceRange: priceRange,
    );

    try {
      // Inserción directa en la tabla locations de Supabase con PostGIS
      await _locationService.addPoi(newPoi);

      if (!mounted) return;
      Navigator.of(context).pop(newPoi);

      TacticalAlert.show(
        context,
        title: 'ATALAYA REGISTRADA // ADMIN',
        message: 'La atalaya "$name" ha sido persistida en Supabase y renderizada en el mapa.',
        type: AlertType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      TacticalAlert.show(
        context,
        title: 'ERROR DE REGISTRO',
        message: 'No fue posible registrar la atalaya: $e',
        type: AlertType.error,
      );
    }
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'ATALAYA NATURAL':
        return Icons.terrain_rounded;
      case 'ZONA ARQUEOLÓGICA':
        return Icons.account_balance_rounded;
      case 'NÚCLEO URBANO':
        return Icons.location_city_rounded;
      case 'SECTOR COSTERO':
        return Icons.waves_rounded;
      case 'RESERVA DE SELVA':
        return Icons.forest_rounded;
      case 'CRÁTER ACUÁTICO':
        return Icons.water_rounded;
      case 'PATRIMONIO HISTÓRICO':
        return Icons.museum_rounded;
      case 'MIRADOR TÁCTICO':
        return Icons.explore_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      elevation: 12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.turquoise, width: 1.5),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.locationBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.locationBlue.withValues(alpha: 0.4)),
            ),
            child: const Icon(
              Icons.add_location_alt_rounded,
              color: AppColors.locationBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REGISTRAR NUEVA ATALAYA',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'OPERACIÓN EXCLUSIVA DE ADMINISTRADOR // SV',
                  style: TextStyle(
                    color: AppColors.turquoise,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),

                // ─── NOMBRE DE LA ATALAYA ──────────────────────────────
                _buildFieldLabel('Nombre del Lugar / Atalaya *'),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(
                    hint: 'Ej. Mirador Espíritu de la Montaña',
                    icon: Icons.castle_rounded,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── CATEGORÍA Y DIFICULTAD ────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Categoría'),
                          _buildDropdown<String>(
                            value: _selectedCategory,
                            items: categories,
                            onChanged: (v) => setState(() => _selectedCategory = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Dificultad'),
                          _buildDropdown<String>(
                            value: _selectedDifficulty,
                            items: difficulties,
                            onChanged: (v) => setState(() => _selectedDifficulty = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── DEPARTAMENTO Y ZONA GEOGRÁFICA ────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Departamento (14 SV)'),
                          _buildDropdown<String>(
                            value: _selectedDept,
                            items: departments,
                            onChanged: (v) => setState(() => _selectedDept = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Zona Geográfica'),
                          _buildDropdown<String>(
                            value: _selectedZone,
                            items: geographicZones,
                            onChanged: (v) => setState(() => _selectedZone = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── RANGO DE PRECIO Y TARIFA (USD) ────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Rango de Precio'),
                          _buildDropdown<String>(
                            value: _selectedPriceCategory,
                            items: priceCategories,
                            onChanged: (v) => setState(() => _selectedPriceCategory = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Tarifa USD'),
                          TextFormField(
                            controller: _feeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: '0.00',
                              icon: Icons.attach_money_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── COORDENADAS GPS ──────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Latitud GPS *'),
                          TextFormField(
                            controller: _latController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: '13.8533',
                              icon: Icons.explore_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Longitud GPS *'),
                          TextFormField(
                            controller: _lngController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                            decoration: _buildInputDecoration(
                              hint: '-89.6300',
                              icon: Icons.explore_rounded,
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Capturar Coordenadas GPS del Dispositivo',
                      child: InkWell(
                        onTap: _isLocatingGps ? null : _refreshGpsPosition,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.turquoise),
                          ),
                          child: _isLocatingGps
                              ? const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.turquoise,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.gps_fixed_rounded,
                                  color: AppColors.turquoise,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── DESCRIPCIÓN ──────────────────────────────────────
                _buildFieldLabel('Descripción Táctica del Sitio'),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                  decoration: _buildInputDecoration(
                    hint: 'Vistas panorámicas, senderos, datos clave de acceso...',
                    icon: Icons.description_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'CANCELAR',
            style: TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.locationBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _isSaving ? null : _saveLocation,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'REGISTRAR ATALAYA',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    fontSize: 12,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5, left: 2),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.turquoise, size: 18),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.locationBlue, width: 1.5),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          dropdownColor: AppColors.surfaceElevated,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.turquoise),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12.5),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
