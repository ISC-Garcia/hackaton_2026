import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/idioma.dart';
import 'error_verago.dart';

/// Sellos de un día (para la gráfica).
class SellosDelDia {
  const SellosDelDia(this.fecha, this.total);
  final DateTime fecha;
  final int total;
}

/// Números REALES que devuelven las funciones del SQL 016.
/// Solo totales: nunca nombres ni correos de turistas.
class Estadisticas {
  const Estadisticas({
    required this.datos,
    required this.porDia,
    required this.topNegocios,
  });

  /// Totales sueltos (ej. 'sellos_total' → 12).
  final Map<String, int> datos;
  final List<SellosDelDia> porDia;

  /// Solo admin: nombre del negocio → sellos.
  final Map<String, int> topNegocios;

  int dato(String clave) => datos[clave] ?? 0;

  /// Convierte la respuesta JSON de la función (pública para probarla).
  factory Estadisticas.desdeJson(Map<String, dynamic> j) {
    return Estadisticas(
      datos: {
        for (final e in j.entries)
          if (e.value is num) e.key: (e.value as num).toInt(),
      },
      porDia: [
        for (final d in (j['por_dia'] as List? ?? const []))
          SellosDelDia(DateTime.parse(d['fecha'] as String), (d['total'] as num).toInt()),
      ],
      topNegocios: {
        for (final t in (j['top_negocios'] as List? ?? const []))
          t['nombre'] as String: (t['total'] as num).toInt(),
      },
    );
  }
}

/// SERVICIO de estadísticas: llama a las funciones protegidas del SQL 016.
class EstadisticasService {
  SupabaseClient get _db => Supabase.instance.client;

  Future<Estadisticas> deLaApp() => _pedir('estadisticas_admin');

  Future<Estadisticas> deMiNegocio() => _pedir('estadisticas_mi_negocio');

  Future<Estadisticas> _pedir(String funcion) async {
    Map<String, dynamic> r;
    try {
      r = await _db.rpc(funcion) as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        throw ErrorVeraGo(tr('Falta actualizar la base de datos (correr el SQL 016 en Supabase). Avisa a los desarrolladores.'));
      }
      throw ErrorVeraGo(tr('No pudimos cargar las estadísticas. Intenta de nuevo.'));
    } catch (_) {
      throw ErrorVeraGo(tr('Revisa tu conexión a internet e intenta de nuevo.'));
    }
    switch (r['estado']) {
      case 'OK':
        return Estadisticas.desdeJson(r);
      case 'SIN_NEGOCIO':
        throw ErrorVeraGo(tr('Esta cuenta no tiene un negocio.'));
      default:
        throw ErrorVeraGo(tr('Solo un administrador puede ver estas estadísticas.'));
    }
  }
}
