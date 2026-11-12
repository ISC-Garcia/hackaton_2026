import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/idioma.dart';
import 'error_verago.dart';
import 'fotos_service.dart';

/// Lo que responde la revisión antes de eliminar.
class RevisionEliminar {
  const RevisionEliminar(this.estado, {this.sellos = 0, this.negocios = 0, this.eventos = 0});

  /// 'SE_PUEDE', 'TIENE_SELLOS' o 'TIENE_NEGOCIOS'.
  final String estado;
  final int sellos;
  final int negocios;
  final int eventos;

  bool get sePuede => estado == 'SE_PUEDE';

  factory RevisionEliminar.desdeJson(Map<String, dynamic> j) => RevisionEliminar(
        j['estado'] as String,
        sellos: (j['sellos'] as num?)?.toInt() ?? 0,
        negocios: (j['negocios'] as num?)?.toInt() ?? 0,
        eventos: (j['eventos'] as num?)?.toInt() ?? 0,
      );
}

/// ELIMINAR lugares, Puntos VeraGo y negocios (SQL 019).
///
/// Lo decide la función protegida `eliminar_lugar` en la base de datos:
/// admin = cualquiera; comerciante = solo su negocio; nunca si tiene sellos
/// o si es un Punto con negocios dentro.
class EliminarService {
  SupabaseClient get _db => Supabase.instance.client;

  /// Paso 1: ¿se puede eliminar? (no borra nada).
  Future<RevisionEliminar> revisar(String lugarId) async =>
      RevisionEliminar.desdeJson(await _llamar(lugarId, confirmar: false));

  /// Paso 2: borra la foto (mientras aún hay permiso sobre su carpeta) y
  /// elimina el lugar.
  Future<void> eliminar(String lugarId, {String? fotoUrl}) async {
    if (fotoUrl != null) await FotosService().borrarArchivo(fotoUrl);
    final r = await _llamar(lugarId, confirmar: true);
    if (r['estado'] != 'OK') {
      throw ErrorVeraGo(tr('No se pudo eliminar: algo cambió mientras tanto. Vuelve a intentarlo.'));
    }
  }

  /// El comerciante oculta su negocio (si ya tiene sellos no se puede borrar).
  Future<void> ocultarMiNegocio() async {
    Map<String, dynamic> r;
    try {
      r = await _db.rpc('ocultar_mi_negocio') as Map<String, dynamic>;
    } catch (_) {
      throw ErrorVeraGo(tr('Revisa tu conexión a internet e intenta de nuevo.'));
    }
    if (r['estado'] != 'OK') throw ErrorVeraGo(tr('No pudimos ocultar tu negocio.'));
  }

  Future<Map<String, dynamic>> _llamar(String lugarId, {required bool confirmar}) async {
    Map<String, dynamic> r;
    try {
      r = await _db.rpc('eliminar_lugar', params: {'p_lugar': lugarId, 'p_confirmar': confirmar})
          as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        throw ErrorVeraGo(tr('Falta actualizar la base de datos (correr el SQL 019). Avisa a los desarrolladores.'));
      }
      throw ErrorVeraGo(tr('No pudimos eliminarlo. Intenta de nuevo.'));
    } catch (_) {
      throw ErrorVeraGo(tr('Revisa tu conexión a internet e intenta de nuevo.'));
    }
    switch (r['estado']) {
      case 'NO_AUTORIZADO':
        throw ErrorVeraGo(tr('No tienes permiso para eliminar este lugar.'));
      case 'NO_EXISTE':
        throw ErrorVeraGo(tr('Este lugar ya no existe.'));
      default:
        return r;
    }
  }
}
