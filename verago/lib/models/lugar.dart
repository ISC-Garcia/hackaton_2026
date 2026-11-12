import 'package:latlong2/latlong.dart';

/// Un día del horario de un lugar (una fila de la tabla `horarios`).
class Horario {
  const Horario({required this.diaSemana, required this.abre, required this.cierra});

  /// 0 = domingo ... 6 = sábado (igual que en la base de datos).
  final int diaSemana;

  /// Minutos desde la medianoche (ej. 08:30 → 510). Así comparar horas es
  /// una simple resta de números.
  final int abre;
  final int cierra;

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        diaSemana: json['dia_semana'] as int,
        abre: _aMinutos(json['abre'] as String),
        cierra: _aMinutos(json['cierra'] as String),
      );

  /// Convierte "08:30:00" (como llega de PostgreSQL) en 510.
  static int _aMinutos(String hora) {
    final partes = hora.split(':');
    return int.parse(partes[0]) * 60 + int.parse(partes[1]);
  }

  /// Convierte 510 en "08:30" para mostrarlo.
  static String formato(int minutos) =>
      '${(minutos ~/ 60).toString().padLeft(2, '0')}:${(minutos % 60).toString().padLeft(2, '0')}';
}

/// Resultado de preguntar "¿está abierto?".
enum EstadoApertura { abierto, cerrado, sinDatos }

/// MODELO: cómo se ve un lugar dentro de la app.
///
/// Qué hace: convierte la fila que llega de Supabase (un mapa JSON) en un
/// objeto de Dart con nombres claros y tipos correctos.
/// Por qué: el resto del código trabaja con `lugar.nombre` en lugar de
/// `json['nombre']`, y si algo viene mal, falla aquí y no en una pantalla.
class Lugar {
  const Lugar({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.categoriaClave,
    required this.categoriaNombre,
    required this.latitud,
    required this.longitud,
    required this.direccion,
    required this.telefono,
    required this.interes,
    required this.duracionVisitaMin,
    required this.esComercio,
    required this.esDemo,
    required this.participaPasaporte,
    required this.horarios,
    this.enRecorridoAPie = true,
    this.esPunto = false,
    this.puntoId,
    this.giroNombre,
    this.giroId,
    this.estadoAprobacion = 'aprobado',
    this.publicado = true,
    this.categoriaId,
    this.duenoNombre,
    this.cambioLatitud,
    this.cambioLongitud,
    this.cambioDireccion,
    this.cambioPuntoId,
    this.cambioSolicitadoEn,
    this.costoEntradaMxn,
  });

  /// COSTO DE ENTRADA en pesos (SQL 014): null = sin dato, 0 = gratis,
  /// > 0 = aproximado. Lo pone el negocio formal o el admin.
  final int? costoEntradaMxn;

  /// Los no formales y los Puntos VeraGo no llevan costo de entrada.
  bool get admiteCostoEntrada => !esPunto && !esInformal;

  /// Texto para la ficha, o null si no hay nada que decir.
  /// - Público sin dato: lo avisamos (no inventamos precios).
  /// - Negocio sin dato: no cobra entrada, no se muestra nada.
  String? get textoEntrada {
    if (!admiteCostoEntrada) return null;
    final c = costoEntradaMxn;
    if (c == null) return esComercio ? null : 'Costo de entrada no disponible: confírmalo en el lugar.';
    if (c == 0) return 'Entrada gratis';
    return 'Entrada aprox. \$$c MXN';
  }

  /// CAMBIO DE UBICACIÓN PENDIENTE (SQL 013): lo que pidió el comerciante y
  /// aún no acepta el admin. Mientras tanto, el negocio sigue en `punto`.
  final double? cambioLatitud;
  final double? cambioLongitud;
  final String? cambioDireccion;

  /// Si es no formal: el Punto VeraGo al que pidió cambiarse.
  final String? cambioPuntoId;
  final DateTime? cambioSolicitadoEn;

  bool get tieneCambioPendiente => cambioSolicitadoEn != null && cambioLatitud != null && cambioLongitud != null;

  /// Punto del mapa que pidió (null si no hay cambio pendiente).
  LatLng? get puntoSolicitado => tieneCambioPendiente ? LatLng(cambioLatitud!, cambioLongitud!) : null;

  /// Si se ve en la app (el admin también ve los no publicados).
  final bool publicado;

  /// Id de la categoría (lo usa el formulario del admin).
  final int? categoriaId;

  /// Nombre del encargado del negocio (solo lo ve el admin).
  final String? duenoNombre;

  /// true = es un Punto VeraGo (espacio donde VeraGo renta mesas a
  /// comerciantes informales, ej. Parque Zamora).
  final bool esPunto;

  /// Si es un comerciante INFORMAL: id del punto donde vende. Si es null y
  /// esComercio es true, es un comercio FORMAL (local propio).
  final String? puntoId;

  /// Giro del comerciante informal (ej. "Guayaberas").
  final String? giroNombre;
  final int? giroId;

  /// 'pendiente', 'aprobado', 'rechazado' o 'suspendido'.
  final String estadoAprobacion;

  /// Comercio con local propio.
  bool get esFormal => esComercio && puntoId == null;

  /// Comerciante que vende dentro de un Punto VeraGo.
  bool get esInformal => puntoId != null;

  final String id;
  final String nombre;
  final String? descripcion;
  final String categoriaClave;
  final String categoriaNombre;
  final double latitud;
  final double longitud;
  final String? direccion;
  final String? telefono;
  final int interes;
  final int duracionVisitaMin;
  final bool esComercio;
  final bool esDemo;
  final bool participaPasaporte;
  final List<Horario> horarios;

  /// false si no se llega caminando desde el centro (las rutas lo omiten).
  final bool enRecorridoAPie;

  /// Punto en el mapa (paquete latlong2).
  LatLng get punto => LatLng(latitud, longitud);

  factory Lugar.fromJson(Map<String, dynamic> json) {
    final categoria = json['categorias'] as Map<String, dynamic>;
    final horarios = (json['horarios'] as List? ?? [])
        .map((h) => Horario.fromJson(h as Map<String, dynamic>))
        .toList();
    return Lugar(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      categoriaClave: categoria['clave'] as String,
      categoriaNombre: categoria['nombre'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
      direccion: json['direccion'] as String?,
      telefono: json['telefono'] as String?,
      interes: json['interes'] as int,
      duracionVisitaMin: json['duracion_visita_min'] as int,
      esComercio: json['es_comercio'] as bool,
      esDemo: json['es_demo'] as bool,
      participaPasaporte: json['participa_pasaporte'] as bool,
      horarios: horarios,
      enRecorridoAPie: json['en_recorrido_a_pie'] as bool? ?? true,
      // Columnas del archivo 008. Si aún no se corre, toman valores por defecto.
      esPunto: json['es_punto'] as bool? ?? false,
      puntoId: json['punto_id'] as String?,
      giroNombre: (json['giros'] as Map<String, dynamic>?)?['nombre'] as String?,
      giroId: json['giro_id'] as int?,
      estadoAprobacion: json['estado_aprobacion'] as String? ?? 'aprobado',
      publicado: json['publicado'] as bool? ?? true,
      categoriaId: json['categoria_id'] as int?,
      duenoNombre: (json['perfiles'] as Map<String, dynamic>?)?['nombre'] as String?,
      // Columnas del archivo 013 (si no existen, quedan en null).
      cambioLatitud: (json['cambio_latitud'] as num?)?.toDouble(),
      cambioLongitud: (json['cambio_longitud'] as num?)?.toDouble(),
      cambioDireccion: json['cambio_direccion'] as String?,
      cambioPuntoId: json['cambio_punto_id'] as String?,
      costoEntradaMxn: json['costo_entrada_mxn'] as int?,
      cambioSolicitadoEn: json['cambio_solicitado_en'] == null
          ? null
          : DateTime.parse(json['cambio_solicitado_en'] as String).toLocal(),
    );
  }

  /// Horario del día indicado, o null si ese día no hay datos.
  Horario? horarioDel(int diaSemana) {
    for (final h in horarios) {
      if (h.diaSemana == diaSemana) return h;
    }
    return null;
  }

  /// ¿Está abierto en este momento?
  /// - Sin horarios cargados → sinDatos (no inventamos horarios reales).
  /// - Usa la hora del celular (se asume que está en Veracruz).
  EstadoApertura estadoEn(DateTime momento) {
    if (horarios.isEmpty) return EstadoApertura.sinDatos;
    // En Dart, weekday va de 1 (lunes) a 7 (domingo). "% 7" deja el
    // domingo en 0, igual que en la base de datos.
    final hoy = horarioDel(momento.weekday % 7);
    if (hoy == null) return EstadoApertura.cerrado;
    final minutos = momento.hour * 60 + momento.minute;
    return (minutos >= hoy.abre && minutos < hoy.cierra)
        ? EstadoApertura.abierto
        : EstadoApertura.cerrado;
  }
}
