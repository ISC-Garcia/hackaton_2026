/// INSIGNIA DEL PASAPORTE: mejora conforme juntas sellos de negocios.
///
/// Regla (decisión del equipo): el total de negocios que dan sellos se
/// divide entre los 5 niveles. Cada nivel se gana con un "pedazo" más del
/// total y el último (Embajador VeraGo) solo con TODOS los negocios.
///
///   sellos para el nivel k = ⌈ total × k ÷ 5 ⌉   (k = 1 … 5)
///
/// Ejemplo con 10 negocios: niveles en 2, 4, 6, 8 y 10 sellos.
/// Si el total no se divide exacto, se redondea hacia arriba
/// (ej. 8 negocios: 2, 4, 5, 7 y 8).
class NivelInsignia {
  const NivelInsignia(this.numero, this.nombre, this.descripcion);

  /// 1 a 5.
  final int numero;
  final String nombre;
  final String descripcion;
}

/// Cómo vas: nivel ganado, cuántos sellos faltan para el siguiente, etc.
class ProgresoInsignia {
  const ProgresoInsignia({
    required this.logrados,
    required this.total,
    required this.nivel,
    required this.metas,
  });

  /// Negocios distintos sellados (que siguen dando sellos).
  final int logrados;

  /// Negocios que dan sellos.
  final int total;

  /// Nivel ganado (0 = todavía ninguno).
  final int nivel;

  /// Sellos necesarios para cada nivel (5 números, el último = total).
  final List<int> metas;

  NivelInsignia? get actual => nivel == 0 ? null : Insignia.niveles[nivel - 1];
  NivelInsignia? get siguiente => nivel >= Insignia.niveles.length ? null : Insignia.niveles[nivel];
  bool get completa => total > 0 && nivel == Insignia.niveles.length;

  /// Cuántos sellos faltan para el siguiente nivel (0 si ya está completa).
  int get faltan => completa || total == 0 ? 0 : metas[nivel] - logrados;

  /// Avance hacia el siguiente nivel, de 0 a 1 (para la barra).
  double get avance {
    if (total == 0) return 0;
    if (completa) return 1;
    final desde = nivel == 0 ? 0 : metas[nivel - 1];
    final hasta = metas[nivel];
    return hasta == desde ? 1 : ((logrados - desde) / (hasta - desde)).clamp(0, 1).toDouble();
  }
}

class Insignia {
  static const niveles = [
    NivelInsignia(1, 'Visitante', 'Diste tus primeros pasos por el centro.'),
    NivelInsignia(2, 'Explorador', 'Ya conoces varios rincones del puerto.'),
    NivelInsignia(3, 'Viajero', 'Recorriste la mitad de los negocios.'),
    NivelInsignia(4, 'Jarocho', 'Conoces el centro como alguien de aquí.'),
    NivelInsignia(5, 'Embajador VeraGo', '¡Visitaste todos los negocios! El centro es tuyo.'),
  ];

  /// Sellos necesarios para cada nivel: ⌈ total × k ÷ 5 ⌉.
  static List<int> metas(int total) {
    final n = niveles.length;
    return [for (var k = 1; k <= n; k++) ((total * k) + n - 1) ~/ n];
  }

  static ProgresoInsignia calcular({required int logrados, required int total}) {
    final m = metas(total);
    var nivel = 0;
    if (total > 0) {
      for (var k = 0; k < m.length; k++) {
        if (logrados >= m[k]) nivel = k + 1;
      }
    }
    return ProgresoInsignia(logrados: logrados, total: total, nivel: nivel, metas: m);
  }
}
