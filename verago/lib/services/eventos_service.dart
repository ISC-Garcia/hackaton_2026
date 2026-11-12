import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/evento.dart';
import 'error_verago.dart';

/// Datos de un evento que el admin crea o edita.
class DatosEvento {
  const DatosEvento({
    required this.titulo,
    required this.descripcion,
    required this.lugarId,
    required this.inicia,
    required this.termina,
    required this.estado,
    required this.esGratuito,
    required this.costoAproxMxn,
  });

  final String titulo;
  final String descripcion;
  final String lugarId;
  final DateTime inicia;
  final DateTime termina;
  /// 'publicado' (todos lo ven), 'pendiente' (borrador: solo el admin) o 'cancelado'.
  final String estado;
  final bool esGratuito;
  final int? costoAproxMxn;

  /// Copia del evento movida `dias` días (misma hora de inicio y fin).
  DatosEvento movido(int dias) => DatosEvento(
        titulo: titulo,
        descripcion: descripcion,
        lugarId: lugarId,
        inicia: inicia.add(Duration(days: dias)),
        termina: termina.add(Duration(days: dias)),
        estado: estado,
        esGratuito: esGratuito,
        costoAproxMxn: costoAproxMxn,
      );

  /// EVENTO QUE SE REPITE: "cada [cadaDias] días, [veces] veces".
  /// Devuelve un evento por fecha (el primero es el original). Así cada
  /// fecha se puede editar o cancelar por separado (ej. si llueve un día).
  static List<DatosEvento> repetir(DatosEvento base, {required int cadaDias, required int veces}) =>
      [for (var i = 0; i < veces; i++) base.movido(i * cadaDias)];

  /// Columnas de la tabla `eventos`. Las fechas viajan en UTC.
  Map<String, dynamic> aFila() => {
        'titulo': titulo.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        'lugar_id': lugarId,
        'inicia': inicia.toUtc().toIso8601String(),
        'termina': termina.toUtc().toIso8601String(),
        'estado': estado,
        'es_gratuito': esGratuito,
        'costo_aprox_mxn': esGratuito ? null : costoAproxMxn,
      };
}

/// SERVICIO de eventos: pide la agenda cultural a Supabase y, si eres
/// admin, la modifica.
///
/// Seguridad: la app NO decide quién puede escribir. La regla RLS
/// "admin administra eventos" solo deja escribir al rol admin; si otro lo
/// intenta, la base responde con error y aquí lo traducimos.
class EventosService {
  SupabaseClient get _db => Supabase.instance.client;

  /// Eventos que todavía no terminan, ordenados por fecha de inicio.
  /// Incluye el nombre del lugar donde ocurren.
  /// RLS deja ver los publicados y cancelados; el admin ve también los borradores.
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

  Future<void> crear(DatosEvento d) => _escribir(() => _db.from('eventos').insert(d.aFila()));

  /// Crea varias fechas de un evento que se repite, en UNA sola petición
  /// (si una falla, no se crea ninguna).
  Future<void> crearVarios(List<DatosEvento> eventos) =>
      _escribir(() => _db.from('eventos').insert([for (final e in eventos) e.aFila()]));

  Future<void> actualizar(String id, DatosEvento d) =>
      _escribir(() => _db.from('eventos').update(d.aFila()).eq('id', id));

  /// Cambia solo el estado: 'publicado', 'pendiente' (borrador) o 'cancelado'.
  Future<void> cambiarEstado(String id, String estado) =>
      _escribir(() => _db.from('eventos').update({'estado': estado}).eq('id', id));

  Future<void> eliminar(String id) => _escribir(() => _db.from('eventos').delete().eq('id', id));

  Future<void> _escribir(Future<void> Function() accion) async {
    try {
      await accion();
    } on PostgrestException catch (e) {
      // 42501 = permiso denegado (no es admin, o falta correr el SQL 010).
      if (e.code == '42501') {
        throw const ErrorVeraGo('Solo un administrador puede modificar la agenda.');
      }
      // 23514 = no cumple una regla CHECK (ej. termina antes de iniciar).
      if (e.code == '23514') {
        throw const ErrorVeraGo('Revisa los datos: el evento debe terminar después de iniciar.');
      }
      throw const ErrorVeraGo('No pudimos guardar el evento. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }
}
