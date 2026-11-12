import 'package:supabase_flutter/supabase_flutter.dart';

import '../i18n/idioma.dart';
import '../models/sello.dart';
import 'validaciones.dart';
import 'error_verago.dart';

/// Resultado de escanear un QR (lo que responde `registrar_visita`).
class ResultadoEscaneo {
  const ResultadoEscaneo({required this.estado, this.lugarId, this.lugarNombre, this.totalSellos});

  /// 'OK', 'YA_TIENE_SELLO_HOY', 'CODIGO_INVALIDO', 'ES_TU_NEGOCIO' o 'NECESITA_SESION'.
  final String estado;
  final String? lugarId;
  final String? lugarNombre;
  final int? totalSellos;

  bool get exito => estado == 'OK';

  /// Mensaje claro para el visitante.
  String get mensaje {
    switch (estado) {
      case 'OK':
        return tr('¡Sello obtenido en {lugar}! Llevas {n} en tu pasaporte.', {'lugar': lugarNombre, 'n': totalSellos});
      case 'YA_TIENE_SELLO_HOY':
        return tr('Ya tienes el sello de {lugar} de hoy. Vuelve otro día o descubre otro lugar.', {'lugar': lugarNombre});
      case 'NECESITA_SESION':
        return tr('Inicia sesión para guardar tus sellos.');
      case 'ES_TU_NEGOCIO':
        return tr('No puedes darte un sello de tu propio negocio. Pide a un turista que lo escanee.');
      default:
        return tr('Este código ya venció o no es válido. Pide al comercio que te muestre el QR actual.');
    }
  }
}

/// SERVICIO del pasaporte: sellos, perfil y QR de comerciante.
///
/// Importante: la app NUNCA escribe directo en la tabla `visitas`.
/// Llama a las funciones de PostgreSQL con `rpc`, y ellas validan todo
/// dentro de la base de datos (archivo 003 del SQL).
class PasaporteService {
  SupabaseClient get _db => Supabase.instance.client;
  String? get _uid => _db.auth.currentUser?.id;

  /// Mi perfil (nombre y rol).
  /// `maybeSingle()` devuelve null si no hay fila (por ejemplo, una cuenta
  /// creada antes de que existiera el trigger crear_perfil). En ese caso
  /// usamos el inicio del correo como nombre y el rol "usuario", para que
  /// el pasaporte funcione igual.
  Future<Perfil> miPerfil() async {
    Map<String, dynamic>? fila;
    try {
      fila = await _db.from('perfiles').select('nombre, rol').eq('id', _uid!).maybeSingle();
    } catch (_) {
      throw ErrorVeraGo(tr('No pudimos cargar tu perfil. Intenta de nuevo.'));
    }
    if (fila != null) return Perfil.fromJson(fila);
    final correo = _db.auth.currentUser?.email ?? 'Visitante';
    return Perfil(nombre: correo.split('@').first, rol: 'usuario');
  }

  /// Correo de la cuenta con sesión (lo guarda Supabase Auth).
  String? get miCorreo {
    try {
      return _db.auth.currentUser?.email;
    } catch (_) {
      return null; // sin Supabase configurado (pruebas)
    }
  }

  /// Cambia mi nombre visible.
  /// La base solo permite editar la columna `nombre` (GRANT del archivo 005)
  /// y solo de mi propio perfil (regla RLS "editar mi perfil").
  Future<void> cambiarNombre(String nombre) async {
    try {
      await _db.from('perfiles').update({'nombre': nombre.trim()}).eq('id', _uid!);
    } catch (_) {
      throw ErrorVeraGo(tr('No pudimos guardar tu nombre. Intenta de nuevo.'));
    }
  }

  /// BORRAR MI CUENTA (derecho ARCO de cancelación, SQL 016).
  /// La función protegida borra la cuenta, el perfil y los sellos.
  /// Devuelve null si salió bien, o el mensaje para la persona.
  Future<String?> borrarMiCuenta() async {
    Map<String, dynamic> r;
    try {
      r = await _db.rpc('borrar_mi_cuenta') as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST202') {
        return tr('Falta actualizar la base de datos (correr el SQL 016). Avisa a los desarrolladores.');
      }
      return tr('No pudimos borrar tu cuenta. Intenta de nuevo.');
    } catch (_) {
      return tr('Revisa tu conexión a internet e intenta de nuevo.');
    }
    switch (r['estado']) {
      case 'OK':
        return null;
      case 'ES_ADMIN':
        return tr('Una cuenta de administrador no se borra desde la app. Pídeselo a los desarrolladores.');
      default:
        return tr('No pudimos borrar tu cuenta. Intenta de nuevo.');
    }
  }

  /// Mis sellos, del más reciente al más antiguo.
  ///
  /// OJO: la regla RLS deja al ADMIN ver los sellos de todos (para
  /// estadísticas). Por eso filtramos por `usuario_id`: el Pasaporte, el
  /// historial y la insignia solo deben contar lo que YO escaneé. Antes, un
  /// admin con negocio veía en su historial los escaneos que le hicieron.
  Future<List<Sello>> misSellos() async {
    final uid = _uid;
    if (uid == null) return const [];
    try {
      final filas = await _db
          .from('visitas')
          .select('lugar_id, creado_en, lugares(nombre, categorias(clave))')
          .eq('usuario_id', uid)
          .order('creado_en', ascending: false);
      return filas.map(Sello.fromJson).toList();
    } catch (_) {
      throw ErrorVeraGo(tr('No pudimos cargar tus sellos. Intenta de nuevo.'));
    }
  }

  /// Envía el código escaneado a la función `registrar_visita`.
  Future<ResultadoEscaneo> registrarVisita(String codigo) async {
    try {
      final r = await _db.rpc('registrar_visita', params: {'p_codigo': Validaciones.normalizarCodigo(codigo)})
          as Map<String, dynamic>;
      return ResultadoEscaneo(
        estado: r['estado'] as String,
        lugarId: r['lugar_id'] as String?,
        lugarNombre: r['lugar_nombre'] as String?,
        totalSellos: r['total_sellos'] as int?,
      );
    } on PostgrestException {
      // Sí hubo conexión, pero la base de datos respondió con un error.
      throw ErrorVeraGo(tr('No pudimos validar el código. Intenta de nuevo.'));
    } catch (_) {
      // SIN CONEXIÓN (decisión del equipo): NO se guarda para después. El QR
      // vence en 60 s y se valida en el momento; guardarlo para luego
      // obligaría a aceptar códigos vencidos (y servirían las capturas).
      throw ErrorVeraGo(tr(sinConexionAlEscanear));
    }
  }

  /// Mensaje cuando se escanea sin internet (público para probarlo).
  static const sinConexionAlEscanear = 'Sin conexión: el sello necesita internet para validarse en el momento '
      '(el QR cambia cada 60 segundos). Vuelve a escanear cuando tengas señal.';

  /// Comercios de los que soy dueño y que dan sellos.
  Future<List<({String id, String nombre})>> misComercios() async {
    try {
      final filas = await _db
          .from('lugares')
          .select('id, nombre')
          .eq('dueno_id', _uid!)
          .eq('participa_pasaporte', true)
          .order('nombre');
      return [for (final f in filas) (id: f['id'] as String, nombre: f['nombre'] as String)];
    } catch (_) {
      throw ErrorVeraGo(tr('No pudimos cargar tu comercio. Intenta de nuevo.'));
    }
  }

  /// Pide a la función `generar_codigo_qr` un código nuevo (dura 60 s).
  Future<({String codigo, DateTime venceEn})> generarCodigo(String lugarId) async {
    Map<String, dynamic> r;
    try {
      r = await _db.rpc('generar_codigo_qr', params: {'p_lugar': lugarId}) as Map<String, dynamic>;
    } catch (_) {
      throw ErrorVeraGo(tr('No pudimos generar el código. Revisa tu conexión.'));
    }
    if (r['estado'] != 'OK') {
      throw ErrorVeraGo(tr('Tu cuenta no está autorizada para mostrar el QR de este comercio.'));
    }
    return (
      codigo: r['codigo'] as String,
      venceEn: DateTime.parse(r['vence_en'] as String).toLocal(),
    );
  }
}
