/// MODELO: un sello del pasaporte (una fila de la tabla `visitas`).
class Sello {
  const Sello({
    required this.lugarId,
    required this.lugarNombre,
    required this.categoriaClave,
    required this.fecha,
  });

  final String lugarId;
  final String lugarNombre;
  final String categoriaClave;
  final DateTime fecha;

  factory Sello.fromJson(Map<String, dynamic> json) {
    final lugar = json['lugares'] as Map<String, dynamic>;
    final categoria = lugar['categorias'] as Map<String, dynamic>;
    return Sello(
      lugarId: json['lugar_id'] as String,
      lugarNombre: lugar['nombre'] as String,
      categoriaClave: categoria['clave'] as String,
      fecha: DateTime.parse(json['creado_en'] as String).toLocal(),
    );
  }
}

/// MODELO: el perfil del usuario (tabla `perfiles`).
class Perfil {
  const Perfil({required this.nombre, required this.rol});

  final String nombre;

  /// 'usuario', 'comerciante' o 'admin'.
  final String rol;

  bool get esComerciante => rol == 'comerciante' || rol == 'admin';
  bool get esAdmin => rol == 'admin';

  factory Perfil.fromJson(Map<String, dynamic> json) =>
      Perfil(nombre: json['nombre'] as String, rol: json['rol'] as String);
}
