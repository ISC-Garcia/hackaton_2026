import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lugar.dart';
import 'error_verago.dart';

/// Datos de un lugar o Punto VeraGo que el admin crea o edita.
class DatosLugar {
  const DatosLugar({
    required this.nombre,
    required this.descripcion,
    required this.categoriaId,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.interes,
    required this.duracionVisitaMin,
    required this.esPunto,
    required this.enRecorridoAPie,
    required this.publicado,
  });

  final String nombre;
  final String descripcion;
  final int categoriaId;
  final double latitud;
  final double longitud;
  final String direccion;
  final int interes;
  final int duracionVisitaMin;
  final bool esPunto;
  final bool enRecorridoAPie;
  final bool publicado;

  Map<String, dynamic> aFila() => {
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim().isEmpty ? null : descripcion.trim(),
        // Un Punto VeraGo siempre va en la categoría "Puntos VeraGo" (id 8).
        'categoria_id': esPunto ? 8 : categoriaId,
        'latitud': latitud,
        'longitud': longitud,
        'direccion': direccion.trim().isEmpty ? null : direccion.trim(),
        'interes': interes,
        'duracion_visita_min': duracionVisitaMin,
        'es_punto': esPunto,
        'en_recorrido_a_pie': enRecorridoAPie,
        'publicado': publicado,
      };
}

/// SERVICIO del panel de administración (solo admin).
///
/// Escribe directo en las tablas, pero la base de datos solo lo permite si
/// la cuenta es admin (reglas RLS "admin administra lugares/horarios" +
/// SQL 011). Si otro lo intenta, la base responde "permiso denegado".
class AdminService {
  SupabaseClient get _db => Supabase.instance.client;

  static const _columnas = '*, categorias(clave, nombre), horarios(*), giros(nombre), perfiles(nombre)';

  /// Negocios registrados desde "Soy un negocio", del más nuevo al más viejo.
  Future<List<Lugar>> negocios() => _leer(
        () => _db.from('lugares').select(_columnas).eq('es_comercio', true).order('creado_en', ascending: false),
      );

  /// Lugares públicos y Puntos VeraGo (no comercios), publicados o no.
  Future<List<Lugar>> lugares() => _leer(
        () => _db.from('lugares').select(_columnas).eq('es_comercio', false).order('nombre'),
      );

  /// Categorías para el formulario (id → nombre).
  Future<Map<int, String>> categorias() async {
    try {
      final filas = await _db.from('categorias').select('id, nombre').order('id');
      return {for (final f in filas) f['id'] as int: f['nombre'] as String};
    } catch (_) {
      throw const ErrorVeraGo('No pudimos cargar las categorías.');
    }
  }

  /// Aprobar, rechazar, suspender o reactivar un negocio.
  /// - aprobado: se ve en la app y da sellos.
  /// - rechazado / suspendido: deja de verse.
  /// Aprobar = se publica. Solo un negocio FORMAL da sellos (regla del
  /// equipo; la base de datos también lo exige, archivo 012).
  Future<void> cambiarEstadoNegocio(String id, String estado, {required bool formal}) {
    final aprobado = estado == 'aprobado';
    return _escribir(() => _db.from('lugares').update({
          'estado_aprobacion': estado,
          'publicado': aprobado,
          'participa_pasaporte': aprobado && formal,
        }).eq('id', id));
  }

  /// Crea o actualiza un lugar y reemplaza su horario.
  Future<void> guardarLugar({String? id, required DatosLugar datos, required List<Horario> horario}) async {
    late String lugarId;
    await _escribir(() async {
      if (id == null) {
        final fila = await _db.from('lugares').insert(datos.aFila()).select('id').single();
        lugarId = fila['id'] as String;
      } else {
        await _db.from('lugares').update(datos.aFila()).eq('id', id);
        lugarId = id;
      }
    });
    await guardarHorario(lugarId, horario);
  }

  /// Reemplaza el horario de cualquier lugar (también de comerciantes informales).
  Future<void> guardarHorario(String lugarId, List<Horario> horario) => _escribir(() async {
        await _db.from('horarios').delete().eq('lugar_id', lugarId);
        if (horario.isEmpty) return;
        await _db.from('horarios').insert([
          for (final h in horario)
            {
              'lugar_id': lugarId,
              'dia_semana': h.diaSemana,
              'abre': Horario.formato(h.abre),
              'cierra': Horario.formato(h.cierra),
            },
        ]);
      });

  Future<List<Lugar>> _leer(Future<List<Map<String, dynamic>>> Function() consulta) async {
    try {
      return (await consulta()).map(Lugar.fromJson).toList();
    } catch (_) {
      throw const ErrorVeraGo('No pudimos cargar la información. Intenta de nuevo.');
    }
  }

  Future<void> _escribir(Future<void> Function() accion) async {
    try {
      await accion();
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw const ErrorVeraGo('Solo un administrador puede hacer este cambio.');
      }
      if (e.code == '23505') {
        throw const ErrorVeraGo('Ese giro ya está ocupado en el punto o el nombre ya existe.');
      }
      throw const ErrorVeraGo('No pudimos guardar el cambio. Intenta de nuevo.');
    } catch (_) {
      throw const ErrorVeraGo('Revisa tu conexión a internet e intenta de nuevo.');
    }
  }
}
