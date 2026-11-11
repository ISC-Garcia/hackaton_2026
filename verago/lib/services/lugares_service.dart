import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lugar.dart';
import 'error_verago.dart';

/// SERVICIO de lugares: la única parte de la app que pide lugares a Supabase.
///
/// Por qué existe: las pantallas no hablan directo con la base de datos.
/// Si mañana cambia una columna, solo se corrige aquí.
class LugaresService {
  SupabaseClient get _db => Supabase.instance.client;

  /// Trae todos los lugares publicados con su categoría y su horario.
  ///
  /// `categorias(clave, nombre)` y `horarios(*)` le piden a Supabase que una
  /// cada lugar con su categoría y su horario (como un JOIN de SQL) en una
  /// sola consulta. Las reglas RLS ya filtran lo que podemos ver.
  Future<List<Lugar>> obtenerLugares() async {
    try {
      final filas = await _db
          .from('lugares')
          .select('*, categorias(clave, nombre), horarios(*)')
          .eq('publicado', true)
          .order('nombre');
      return filas.map(Lugar.fromJson).toList();
    } on PostgrestException {
      throw const ErrorVeraGo('No pudimos cargar los lugares. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }
}
