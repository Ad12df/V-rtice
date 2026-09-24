import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';
import 'package:vertice/features/auth/services/auth_service.dart';
import 'package:vertice/features/events/models/tactical_event.dart';
import 'package:vertice/features/events/services/events_service.dart';

/// Modal táctico para la creación y registro de eventos turísticos, culturales y expediciones
/// Disponible para cualquier usuario autenticado y activo (no suspendido).
class AddEventModal extends StatefulWidget {
  final LatLng? initialCoordinates;

  const AddEventModal({
    super.key,
    this.initialCoordinates,
  });

  static Future<TacticalEvent?> show(
    BuildContext context, {
    LatLng? initialCoordinates,
  }) {
    return showDialog<TacticalEvent>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AddEventModal(initialCoordinates: initialCoordinates),
    );
  }

  @override
  State<AddEventModal> createState() => _AddEventModalState();
}

class _AddEventModalState extends State<AddEventModal> {
  final _formKey = GlobalKey<FormState>();
  final _eventsService = EventsService();
  final _authService = AuthService();

  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  late final TextEditingController _priceController;

  bool _isSaving = false;
  bool _isLocatingGps = false;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);

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

  static const List<String> categories = [
    'EXPEDICIÓN TÁCTICA',
    'SURF & PLAYA',
    'CULTURA & ARTE',
    'CONFERENCIA TECNOLÓGICA',
    'SENDERISMO',
    'GASTRONOMÍA',
    'CAMPAMENTO',
    'MÚSICA & FESTIVAL',
  ];

  static const List<String> priceCategories = [
    'GRATUITO',
    'ECONÓMICO',
    'MODERADO',
    'EXCLUSIVO',
  ];

  late String _selectedDept;
  late String _selectedCategory;
  late String _selectedPriceCategory;

  @override
  void initState() {
    super.initState();
    final defaultCoords = widget.initialCoordinates ?? const LatLng(13.6983, -89.1914);

    _titleController = TextEditingController();
    _descController = TextEditingController();
    _locationNameController = TextEditingController();
    _latController = TextEditingController(text: defaultCoords.latitude.toStringAsFixed(6));
    _lngController = TextEditingController(text: defaultCoords.longitude.toStringAsFixed(6));
    _priceController = TextEditingController(text: '0.00');

    _selectedDept = departments[9]; // San Salvador
    _selectedCategory = categories[0];
    _selectedPriceCategory = priceCategories[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _locationNameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _captureCurrentGps() async {
    setState(() => _isLocatingGps = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.surfaceElevated,
              content: Text('⚠️ Permiso GPS denegado.', style: TextStyle(color: Colors.amber)),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 7),
        ),
      );

      if (mounted) {
        setState(() {
          _latController.text = position.latitude.toStringAsFixed(6);
          _lngController.text = position.longitude.toStringAsFixed(6);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('Error al capturar GPS: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocatingGps = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.goldenOrange,
              onPrimary: AppColors.navyBlue,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.goldenOrange,
              onPrimary: AppColors.navyBlue,
              surface: AppColors.surfaceElevated,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());

    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.surfaceElevated,
          content: Text('⚠️ Coordenadas GPS inválidas.', style: TextStyle(color: Colors.redAccent)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = _authService.currentUser;
      final profile = await _authService.getCurrentUserProfile();

      final fullDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final priceAmount = double.tryParse(_priceController.text.trim()) ?? 0.00;
      final priceStr = _selectedPriceCategory == 'GRATUITO' || priceAmount <= 0.0
          ? 'Gratis'
          : '\$${priceAmount.toStringAsFixed(2)} USD';

      final timeFormatted =
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

      final newEvent = TacticalEvent(
        id: 'event-${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        date: fullDate,
        endDate: fullDate.add(const Duration(hours: 4)),
        time: timeFormatted,
        locationName: _locationNameController.text.trim().isEmpty
            ? 'El Salvador'
            : _locationNameController.text.trim(),
        department: _selectedDept,
        coordinates: LatLng(lat, lng),
        price: priceStr,
        priceCategory: _selectedPriceCategory,
        priceAmount: priceAmount,
        status: TacticalEventStatus.upcoming,
        category: _selectedCategory,
        organizerId: user?.id,
        organizerName: profile?.username != null
            ? '@${profile!.username}'
            : (profile?.fullName ?? user?.email?.split('@').first ?? 'Operador'),
        organizerAvatar: profile?.avatarUrl,
      );

      await _eventsService.addEvent(newEvent);

      if (mounted) {
        Navigator.of(context).pop(newEvent);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.goldenOrange, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Evento "${newEvent.title}" publicado con éxito.',
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.surfaceElevated,
            content: Text('Error al crear evento: $e', style: const TextStyle(color: Colors.redAccent)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.goldenOrange, width: 1.5),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 540,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.goldenOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.goldenOrange),
                    ),
                    child: const Icon(Icons.event_available_rounded, color: AppColors.goldenOrange, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PUBLICAR EVENTO TÁCTICO',
                          style: TextStyle(
                            color: AppColors.goldenOrange,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AGENDA COMUNITARIA & TURÍSTICA // SV',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: AppColors.surfaceBorder, height: 24),

              // Formulario scrollable
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // TÍTULO
                        _buildLabel('TÍTULO DEL EVENTO *'),
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Ej. Torneo Surf City El Tunco'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 14),

                        // DESCRIPCIÓN
                        _buildLabel('DESCRIPCIÓN OPERATIVA *'),
                        TextFormField(
                          controller: _descController,
                          maxLines: 3,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Detalles, punto de reunión, recomendaciones...'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 14),

                        // LUGAR / NOMBRE DE UBICACIÓN
                        _buildLabel('NOMBRE DEL LUGAR O ATALAYA *'),
                        TextFormField(
                          controller: _locationNameController,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          decoration: _buildInputDecoration('Ej. Playa El Tunco, Tamanique'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 14),

                        // CATEGORÍA & DEPARTAMENTO (2 columnas)
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('CATEGORÍA'),
                                  _buildDropdown(
                                    value: _selectedCategory,
                                    items: categories,
                                    onChanged: (v) => setState(() => _selectedCategory = v!),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('DEPARTAMENTO'),
                                  _buildDropdown(
                                    value: _selectedDept,
                                    items: departments,
                                    onChanged: (v) => setState(() => _selectedDept = v!),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // FECHA Y HORA (Selectores interactivos)
                        _buildLabel('FECHA Y HORA DEL EVENTO'),
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: _pickDate,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.surfaceBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, color: AppColors.goldenOrange, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedDate,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: InkWell(
                                onTap: _pickTime,
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.surfaceBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: AppColors.goldenOrange, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        formattedTime,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // PRECIO & RANGO
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('TIPO DE ENTRADA'),
                                  _buildDropdown(
                                    value: _selectedPriceCategory,
                                    items: priceCategories,
                                    onChanged: (v) {
                                      setState(() {
                                        _selectedPriceCategory = v!;
                                        if (_selectedPriceCategory == 'GRATUITO') {
                                          _priceController.text = '0.00';
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLabel('MONTO USD (\$)'),
                                  TextFormField(
                                    controller: _priceController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                                    decoration: _buildInputDecoration('0.00'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // COORDENADAS GPS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('COORDENADAS GPS *'),
                            TextButton.icon(
                              onPressed: _isLocatingGps ? null : _captureCurrentGps,
                              icon: _isLocatingGps
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.cyan),
                                    )
                                  : const Icon(Icons.my_location_rounded, size: 14, color: AppColors.cyan),
                              label: const Text(
                                'CAPTURAR MI GPS',
                                style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                                decoration: _buildInputDecoration('Latitud'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontFamily: 'monospace'),
                                decoration: _buildInputDecoration('Longitud'),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              // Botón Guardar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldenOrange,
                    foregroundColor: AppColors.navyBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.navyBlue),
                        )
                      : const Icon(Icons.publish_rounded, size: 18),
                  label: Text(
                    _isSaving ? 'PUBLICANDO EN SUPABASE...' : 'PUBLICAR EVENTO TÁCTICO',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 9.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
      filled: true,
      fillColor: AppColors.surfaceElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.surfaceBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.goldenOrange, width: 1.5),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.surfaceElevated,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
          icon: const Icon(Icons.arrow_drop_down_rounded, color: AppColors.cyan),
          items: items.map((item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
