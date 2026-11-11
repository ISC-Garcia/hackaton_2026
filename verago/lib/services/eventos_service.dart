import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evento.dart';
import 'error_verago.dart';

/// SERVICIO de eventos: pide la agenda cultural a Supabase.
class EventosService {
  SupabaseClient get _db => Supabase.instance.client;

  /// Eventos que todavía no terminan, ordenados por fecha de inicio.
  /// Incluye el nombre del lugar donde ocurren.
  /// RLS solo deja ver los publicados y los cancelados (para avisar).
  Future<List<Evento>> obtenerProximos() async {
    try {
      final filas = await _db
          .from('eventos')
          .select('*, lugares(nombre)')
          .gte('termina', DateTime.now().toUtc().toIso8601String())
          .order('inicia');
      return filas.map(Evento.fromJson).toList();
    } on PostgrestException {
      throw const ErrorVeraGo('No pudimos cargar la agenda. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }
}
