/// MODELO: un evento de la agenda cultural (tabla `eventos`).
class Evento {
  const Evento({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.inicia,
    required this.termina,
    required this.estado,
    required this.esGratuito,
    required this.esDemo,
    required this.lugarId,
    required this.lugarNombre,
    this.costoAproxMxn,
  });

  /// Costo aproximado en pesos (null si no se sabe). Columna costo_aprox_mxn.
  final int? costoAproxMxn;

  /// Texto del costo para mostrar en la Agenda.
  /// - Gratuito → "Gratuito"
  /// - Con precio → "≈ $150 MXN"
  /// - Con costo pero sin precio cargado → "Con costo"
  String get textoCosto {
    if (esGratuito) return 'Gratuito';
    final costo = costoAproxMxn;
    return costo == null ? 'Con costo' : '≈ \$$costo MXN';
  }

  final String id;
  final String titulo;
  final String? descripcion;
  final DateTime inicia;
  final DateTime termina;

  /// 'publicado' o 'cancelado' (los 'pendiente' no llegan a la app por RLS).
  final String estado;
  final bool esGratuito;
  final bool esDemo;
  final String? lugarId;
  final String? lugarNombre;

  bool get cancelado => estado == 'cancelado';

  /// Borrador: estado 'pendiente'. Solo el admin lo ve (regla RLS).
  bool get borrador => estado == 'pendiente';

  factory Evento.fromJson(Map<String, dynamic> json) {
    final lugar = json['lugares'] as Map<String, dynamic>?;
    return Evento(
      id: json['id'] as String,
      titulo: json['titulo'] as String,
      descripcion: json['descripcion'] as String?,
      // La base guarda la hora en UTC; toLocal() la pasa a la hora del celular.
      inicia: DateTime.parse(json['inicia'] as String).toLocal(),
      termina: DateTime.parse(json['termina'] as String).toLocal(),
      estado: json['estado'] as String,
      esGratuito: json['es_gratuito'] as bool,
      esDemo: json['es_demo'] as bool,
      lugarId: json['lugar_id'] as String?,
      lugarNombre: lugar?['nombre'] as String?,
      // Puede no existir si aún no se corre el SQL 007: entonces queda null.
      costoAproxMxn: json['costo_aprox_mxn'] as int?,
    );
  }

  /// ¿Está ocurriendo en este momento?
  bool enCurso(DateTime ahora) => !ahora.isBefore(inicia) && ahora.isBefore(termina);
}
