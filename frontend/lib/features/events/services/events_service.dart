import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vertice/features/events/models/tactical_event.dart';

/// Servicio singleton reactivo para gestionar la Agenda de Eventos Tácticos en El Salvador
/// con persistencia bidireccional directa y exclusiva en Supabase (Tabla `events` y RPC `get_all_events`)
class EventsService {
  static final EventsService _instance = EventsService._internal();
  factory EventsService() => _instance;
  EventsService._internal() {
    // Disparo inicial asíncrono para sincronizar con Supabase
    fetchEvents();
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Notificador reactivo con la lista de eventos en memoria (inicia vacía)
  final ValueNotifier<List<TacticalEvent>> eventsNotifier =
      ValueNotifier<List<TacticalEvent>>(<TacticalEvent>[]);

  List<TacticalEvent> get events => eventsNotifier.value;

  /// Obtiene los eventos ÚNICA Y EXCLUSIVAMENTE desde Supabase mediante RPC o consulta directa
  Future<List<TacticalEvent>> fetchEvents() async {
    try {
      // 1. Intentar primero con el procedimiento almacenado RPC
      try {
        final response = await _supabase.rpc('get_all_events');
        if (response != null && response is List && response.isNotEmpty) {
          final loaded = response
              .map((item) =>
                  TacticalEvent.fromSupabase(item as Map<String, dynamic>))
              .toList();
          eventsNotifier.value = loaded;
          return loaded;
        }
      } catch (rpcErr) {
        debugPrint('ℹ️ [EventsService] RPC get_all_events fallback: $rpcErr');
      }

      // 2. Consulta directa sobre la tabla events
      final data = await _supabase
          .from('events')
          .select('id, title, description, category, department, location_name, status, price_category, price_amount, start_date, end_date, location, created_at')
          .order('start_date', ascending: true);

      if (data.isNotEmpty) {
        final loaded = (data as List)
            .map((item) =>
                TacticalEvent.fromSupabase(item as Map<String, dynamic>))
            .toList();
        eventsNotifier.value = loaded;
        return loaded;
      }

      // Si la tabla en Supabase está vacía, retorna lista limpia vacía
      eventsNotifier.value = <TacticalEvent>[];
      return <TacticalEvent>[];
    } catch (e) {
      debugPrint('⚠️ [EventsService] Error al sincronizar eventos desde Supabase: $e');
      eventsNotifier.value = <TacticalEvent>[];
      return <TacticalEvent>[];
    }
  }

  /// Agregar un nuevo evento táctico en Supabase y actualizar la memoria reactiva
  Future<void> addEvent(TacticalEvent event) async {
    // Actualización optimista local
    final updated = List<TacticalEvent>.from(eventsNotifier.value)..insert(0, event);
    eventsNotifier.value = updated;

    try {
      final insertData = event.toSupabaseInsert();
      final res = await _supabase.from('events').insert(insertData).select();
      if (res.isNotEmpty) {
        final inserted = TacticalEvent.fromSupabase(res.first);
        final list = List<TacticalEvent>.from(eventsNotifier.value);
        final index = list.indexWhere((e) => e.id == event.id);
        if (index != -1) {
          list[index] = inserted;
          eventsNotifier.value = list;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [EventsService] Error al persistir evento en Supabase: $e');
    }
  }

  /// Modificar un evento existente en Supabase y actualizar memoria reactiva
  Future<void> updateEvent(TacticalEvent event) async {
    final updated = List<TacticalEvent>.from(eventsNotifier.value);
    final index = updated.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      updated[index] = event;
      eventsNotifier.value = updated;
    }

    try {
      final updateData = event.toSupabaseInsert();
      await _supabase.from('events').update(updateData).eq('id', event.id);
    } catch (e) {
      debugPrint('⚠️ [EventsService] Error al actualizar evento en Supabase: $e');
    }
  }

  /// Eliminar un evento de Supabase y remover de la memoria reactiva
  Future<void> deleteEvent(String id) async {
    final updated = List<TacticalEvent>.from(eventsNotifier.value)..removeWhere((e) => e.id == id);
    eventsNotifier.value = updated;

    try {
      await _supabase.from('events').delete().eq('id', id);
    } catch (e) {
      debugPrint('⚠️ [EventsService] Error al eliminar evento en Supabase: $e');
    }
  }
}
