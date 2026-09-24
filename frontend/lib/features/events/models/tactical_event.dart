import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:vertice/core/constants/app_colors.dart';

enum TacticalEventStatus {
  upcoming,
  live,
  completed;

  String get label {
    switch (this) {
      case TacticalEventStatus.live:
        return 'EN VIVO';
      case TacticalEventStatus.upcoming:
        return 'PRÓXIMO';
      case TacticalEventStatus.completed:
        return 'FINALIZADO';
    }
  }

  Color get color {
    switch (this) {
      case TacticalEventStatus.live:
        return AppColors.cyan;
      case TacticalEventStatus.upcoming:
        return AppColors.success;
      case TacticalEventStatus.completed:
        return AppColors.textMuted;
    }
  }

  Color get badgeColor => color;

  static TacticalEventStatus fromString(String? val) {
    if (val == null) return TacticalEventStatus.upcoming;
    final lower = val.toLowerCase().trim();
    if (lower == 'live' || lower == 'en vivo') return TacticalEventStatus.live;
    if (lower == 'completed' || lower == 'finalizado') return TacticalEventStatus.completed;
    return TacticalEventStatus.upcoming;
  }
}

/// Modelo de Evento Cultural, Expedición o Competencia Táctica en El Salvador
class TacticalEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime? endDate;
  final String time;
  final String locationName;
  final String department;
  final LatLng coordinates;
  final String price;
  final String priceCategory;
  final double priceAmount;
  final TacticalEventStatus status;
  final String category;
  final IconData icon;

  const TacticalEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.endDate,
    required this.time,
    required this.locationName,
    required this.department,
    required this.coordinates,
    required this.price,
    this.priceCategory = 'GRATUITO',
    this.priceAmount = 0.00,
    required this.status,
    required this.category,
    this.icon = Icons.event_available_rounded,
  });

  String get formattedDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String get timeString => time;
  String get entryPrice => price;

  factory TacticalEvent.fromSupabase(Map<String, dynamic> json) {
    double lat = 13.6983;
    double lng = -89.1914;

    if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    } else if (json['location'] != null && json['location'] is Map) {
      final locMap = json['location'] as Map<String, dynamic>;
      if (locMap['coordinates'] != null && locMap['coordinates'] is List) {
        final coords = locMap['coordinates'] as List;
        if (coords.length >= 2) {
          lng = (coords[0] as num).toDouble();
          lat = (coords[1] as num).toDouble();
        }
      }
    } else if (json['location'] != null && json['location'] is String) {
      final str = json['location'] as String;
      final match = RegExp(r'POINT\s*\(\s*([-\d.]+)\s+([-\d.]+)\s*\)', caseSensitive: false).firstMatch(str);
      if (match != null) {
        lng = double.tryParse(match.group(1) ?? '') ?? lng;
        lat = double.tryParse(match.group(2) ?? '') ?? lat;
      }
    }

    final startDate = json['start_date'] != null
        ? DateTime.tryParse(json['start_date'].toString()) ?? DateTime.now()
        : DateTime.now();

    final endDate = json['end_date'] != null
        ? DateTime.tryParse(json['end_date'].toString())
        : null;

    final priceCategory = (json['price_category'] as String?) ?? 'GRATUITO';
    final priceAmount = json['price_amount'] != null
        ? (json['price_amount'] as num).toDouble()
        : 0.00;

    final priceStr = (json['price'] as String?) ??
        (priceAmount <= 0.0 || priceCategory == 'GRATUITO'
            ? 'Gratis'
            : '\$${priceAmount.toStringAsFixed(2)} USD');

    final category = (json['category'] as String?) ?? 'EXPEDICIÓN TÁCTICA';
    final status = TacticalEventStatus.fromString(json['status'] as String?);

    // Formatear rango horario estimado a partir de fechas
    final timeStr = (json['time'] as String?) ??
        _formatTimeRange(startDate, endDate);

    return TacticalEvent(
      id: (json['id'] as String?) ?? UniqueKey().toString(),
      title: (json['title'] as String?) ?? 'Evento Táctico',
      description: (json['description'] as String?) ?? '',
      date: startDate,
      endDate: endDate,
      time: timeStr,
      locationName: (json['location_name'] as String?) ?? 'El Salvador',
      department: (json['department'] as String?) ?? 'San Salvador',
      coordinates: LatLng(lat, lng),
      price: priceStr,
      priceCategory: priceCategory,
      priceAmount: priceAmount,
      status: status,
      category: category,
      icon: _getIconForCategory(category),
    );
  }

  Map<String, dynamic> toSupabaseInsert() {
    final wktLocation = 'POINT(${coordinates.longitude} ${coordinates.latitude})';
    return {
      'title': title,
      'description': description,
      'category': category,
      'department': department,
      'location_name': locationName,
      'status': status.name,
      'price_category': priceCategory,
      'price_amount': priceAmount,
      'start_date': date.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'location': wktLocation,
    };
  }

  static String _formatTimeRange(DateTime start, DateTime? end) {
    final startH = start.hour.toString().padLeft(2, '0');
    final startM = start.minute.toString().padLeft(2, '0');
    if (end != null) {
      final endH = end.hour.toString().padLeft(2, '0');
      final endM = end.minute.toString().padLeft(2, '0');
      return '$startH:$startM - $endH:$endM';
    }
    return '$startH:$startM';
  }

  static IconData _getIconForCategory(String category) {
    final catUpper = category.toUpperCase();
    if (catUpper.contains('SURF') || catUpper.contains('PLAYA')) {
      return Icons.surfing_rounded;
    } else if (catUpper.contains('CULTURA') || catUpper.contains('FESTIVAL')) {
      return Icons.festival_rounded;
    } else if (catUpper.contains('EXPEDICIÓN') || catUpper.contains('SENDERISMO') || catUpper.contains('VOLCÁN')) {
      return Icons.terrain_rounded;
    } else if (catUpper.contains('TECNOLOG') || catUpper.contains('HACKATHON') || catUpper.contains('CONFERENCIA')) {
      return Icons.terminal_rounded;
    } else if (catUpper.contains('GASTRONOM') || catUpper.contains('CAFÉ')) {
      return Icons.coffee_rounded;
    } else if (catUpper.contains('CAMPAMENTO')) {
      return Icons.cabin_rounded;
    } else if (catUpper.contains('MÚSICA') || catUpper.contains('CARNAVAL')) {
      return Icons.music_note_rounded;
    }
    return Icons.event_available_rounded;
  }

  TacticalEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    DateTime? endDate,
    String? time,
    String? locationName,
    String? department,
    LatLng? coordinates,
    String? price,
    String? priceCategory,
    double? priceAmount,
    TacticalEventStatus? status,
    String? category,
    IconData? icon,
  }) {
    return TacticalEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      endDate: endDate ?? this.endDate,
      time: time ?? this.time,
      locationName: locationName ?? this.locationName,
      department: department ?? this.department,
      coordinates: coordinates ?? this.coordinates,
      price: price ?? this.price,
      priceCategory: priceCategory ?? this.priceCategory,
      priceAmount: priceAmount ?? this.priceAmount,
      status: status ?? this.status,
      category: category ?? this.category,
      icon: icon ?? this.icon,
    );
  }
}
