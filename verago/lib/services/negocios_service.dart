import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lugar.dart';
import 'auth_service.dart';
import 'error_verago.dart';
import 'lugares_service.dart';

/// Un giro de negocio informal (tabla `giros`), ej. "Guayaberas".
class Giro {
  const Giro(this.id, this.nombre);
  final int id;
  final String nombre;
}

/// Datos del formulario "Soy un negocio".
class SolicitudNegocio {
  const SolicitudNegocio({
    required this.formal,
    required this.nombre,
    required this.descripcion,
    required this.telefono,
    this.categoriaId,
    this.direccion,
    this.latitud,
    this.longitud,
    this.puntoId,
    this.giroId,
  });

  /// true = local propio; false = espacio en un Punto VeraGo.
  final bool formal;
  final String nombre;
  final String descripcion;
  final String telefono;
  // Solo formal:
  final int? categoriaId;
  final String? direccion;
  final double? latitud;
  final double? longitud;
  // Solo informal:
  final String? puntoId;
  final int? giroId;
}

/// SERVICIO de negocios: registro de comerciantes, su negocio y su edición.
///
/// La parte delicada (crear el negocio, darle el rol de comerciante,
/// revisar "un giro por punto") la hace la base de datos con funciones
/// protegidas (archivo 008). La app solo envía los datos.
class NegociosService {
  SupabaseClient get _db => Supabase.instance.client;
  final _auth = AuthService();

  /// Puntos VeraGo publicados (para elegir dónde vender).
  Future<List<Lugar>> obtenerPuntos() async {
    final lugares = await LugaresService().obtenerLugares();
    return lugares.where((l) => l.esPunto).toList();
  }

  Future<List<Giro>> obtenerGiros() async {
    try {
      final filas = await _db.from('giros').select('id, nombre').order('id');
      return [for (final f in filas) Giro(f['id'] as int, f['nombre'] as String)];
    } catch (_) {
      throw const ErrorVeraGo('No pudimos cargar los giros. Intenta de nuevo.');
    }
  }

  /// Giros ya tomados en un punto (incluye solicitudes pendientes).
  Future<Set<int>> girosOcupados(String puntoId) async {
    try {
      final r = await _db.rpc('giros_ocupados', params: {'p_punto': puntoId}) as List;
      return r.map((e) => (e is Map ? e.values.first : e) as int).toSet();
    } catch (_) {
      throw const ErrorVeraGo('No pudimos revisar los giros disponibles.');
    }
  }

  /// 1. Crea la cuenta del encargado (si aún no tiene sesión con ese correo).
  ///    Si ya hay sesión (turista o admin), NO se pide cuenta nueva: se usa la
  ///    de la sesión y no hace falta mandar nombre, correo ni contraseña.
  /// 2. Llama a `registrar_negocio`, que crea el negocio PENDIENTE, lo liga
  ///    al encargado y le da el rol de comerciante (un admin conserva su rol).
  Future<void> registrar({
    String? nombreEncargado,
    String? correo,
    String? contrasena,
    required SolicitudNegocio s,
  }) async {
    // Con sesión y sin correo nuevo: usamos la cuenta de la sesión.
    // También si un intento anterior ya creó la cuenta (y falló el negocio,
    // por ejemplo por nombre repetido): no la volvemos a crear.
    final yaConCuenta = _auth.usuario != null &&
        (correo == null || _auth.usuario?.email?.toLowerCase() == correo.trim().toLowerCase());
    if (!yaConCuenta) {
      if (nombreEncargado == null || correo == null || contrasena == null) {
        throw const ErrorVeraGo('Escribe tus datos de encargado para crear tu cuenta.');
      }
      final conSesion = await _auth.registrar(nombreEncargado, correo, contrasena);
      if (!conSesion) {
        throw const ErrorVeraGo(
          'Creamos tu cuenta, pero falta confirmar tu correo. Ábrelo, confirma y vuelve '
          'a tocar "Registrar mi negocio".',
        );
      }
    }

    Map<String, dynamic> r;
    try {
      r = await _db.rpc('registrar_negocio', params: {
        'p_formal': s.formal,
        'p_nombre': s.nombre,
        'p_descripcion': s.descripcion,
        'p_telefono': s.telefono,
        'p_categoria_id': s.categoriaId,
        'p_direccion': s.direccion,
        'p_latitud': s.latitud,
        'p_longitud': s.longitud,
        'p_punto_id': s.puntoId,
        'p_giro_id': s.giroId,
      }) as Map<String, dynamic>;
    } catch (_) {
      throw const ErrorVeraGo('No pudimos registrar tu negocio. Revisa tu conexión.');
    }

    switch (r['estado']) {
      case 'OK':
        return;
      case 'NOMBRE_DUPLICADO':
        throw const ErrorVeraGo('Ya existe un negocio registrado con ese nombre comercial.');
      case 'GIRO_OCUPADO':
        throw const ErrorVeraGo('Ese giro ya está ocupado en este punto. Elige otro punto o giro.');
      case 'YA_TIENE_NEGOCIO':
        throw const ErrorVeraGo('Esta cuenta ya tiene un negocio registrado. Ábrelo desde '
            'Pasaporte → "Soy un negocio" o inicia sesión para verlo.');
      default:
        throw const ErrorVeraGo('Revisa los datos del negocio e intenta de nuevo.');
    }
  }

  /// El negocio del comerciante con sesión (aunque esté pendiente: la regla
  /// RLS deja al dueño ver su propio lugar). null si no tiene.
  Future<Lugar?> miNegocio() async {
    final uid = _auth.usuario?.id;
    if (uid == null) return null;
    try {
      final fila = await _db
          .from('lugares')
          .select('*, categorias(clave, nombre), horarios(*), giros(nombre)')
          .eq('dueno_id', uid)
          .eq('es_comercio', true)
          .order('creado_en', ascending: false)
          .limit(1)
          .maybeSingle();
      return fila == null ? null : Lugar.fromJson(fila);
    } catch (_) {
      throw const ErrorVeraGo('No pudimos cargar tu negocio. Intenta de nuevo.');
    }
  }

  /// Cambia descripción y teléfono (función protegida).
  /// La dirección ya no se cambia aquí: va con `solicitarCambioUbicacion`.
  /// (Se envía la dirección actual solo porque la función la pide.)
  Future<void> actualizar({
    required String descripcion,
    required String telefono,
    required String direccionActual,
  }) async {
    final r = await _rpc('actualizar_mi_negocio', {
      'p_descripcion': descripcion,
      'p_telefono': telefono,
      'p_direccion': direccionActual,
    });
    if (r['estado'] != 'OK') {
      throw const ErrorVeraGo('No pudimos guardar los cambios de tu negocio.');
    }
  }

  /// PIDE un cambio de ubicación; el admin debe aceptarlo (SQL 013).
  /// - Formal: `punto` del mapa + `direccion`.
  /// - No formal: `puntoId` del Punto VeraGo al que se quiere cambiar.
  Future<void> solicitarCambioUbicacion({
    LatLng? punto,
    String? direccion,
    String? puntoId,
  }) async {
    final r = await _rpc('solicitar_cambio_ubicacion', {
      'p_latitud': punto?.latitude,
      'p_longitud': punto?.longitude,
      'p_direccion': direccion,
      'p_punto_id': puntoId,
    });
    switch (r['estado']) {
      case 'OK':
        return;
      case 'GIRO_OCUPADO':
        throw const ErrorVeraGo('Tu giro ya está ocupado en ese Punto VeraGo. Elige otro punto.');
      case 'MISMO_PUNTO':
        throw const ErrorVeraGo('Ya estás en ese Punto VeraGo.');
      case 'DATOS_INVALIDOS':
        throw const ErrorVeraGo('Marca la nueva ubicación en el mapa y escribe la dirección.');
      default:
        throw const ErrorVeraGo('No pudimos enviar tu solicitud. Intenta de nuevo.');
    }
  }

  /// Costo de entrada del negocio FORMAL (null = no cobro entrada).
  /// Se publica directo, sin aprobación (decisión del equipo; SQL 014).
  Future<void> guardarCostoEntrada(int? costo) async {
    final r = await _rpc('guardar_mi_costo_entrada', {'p_costo': costo});
    if (r['estado'] != 'OK') throw const ErrorVeraGo('No pudimos guardar el costo de entrada.');
  }

  /// Retira la solicitud de cambio de ubicación pendiente.
  Future<void> cancelarCambioUbicacion() async {
    final r = await _rpc('cancelar_cambio_ubicacion', {});
    if (r['estado'] != 'OK') throw const ErrorVeraGo('No pudimos cancelar la solicitud.');
  }

  /// Reemplaza el horario del negocio FORMAL (función protegida).
  Future<void> guardarHorario(List<Horario> horario) async {
    final r = await _rpc('guardar_mi_horario', {
      'p_horario': [
        for (final h in horario)
          {'dia': h.diaSemana, 'abre': Horario.formato(h.abre), 'cierra': Horario.formato(h.cierra)},
      ],
    });
    if (r['estado'] != 'OK') {
      throw const ErrorVeraGo('Revisa el horario: la hora de cierre debe ser después de la de apertura.');
    }
  }

  Future<Map<String, dynamic>> _rpc(String funcion, Map<String, dynamic> params) async {
    try {
      return await _db.rpc(funcion, params: params) as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      // PGRST202 = la función no existe; 42703 = la columna no existe:
      // falta correr un SQL nuevo en Supabase.
      if (e.code == 'PGRST202' || e.code == '42703' || e.code == 'PGRST204') {
        throw const ErrorVeraGo('Falta actualizar la base de datos (correr el SQL más reciente en '
            'Supabase). Avisa a los desarrolladores.');
      }
      throw const ErrorVeraGo('No pudimos completar la operación. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }
}
