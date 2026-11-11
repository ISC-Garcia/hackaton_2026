import 'dart:math';

import 'package:latlong2/latlong.dart';

/// Cálculos de distancia y tiempo caminando.
/// Lo usan Explorar (Fase 2) y el generador de rutas (Fase 3).
class Distancia {
  /// Punto de partida por defecto: el Zócalo (coordenada aproximada).
  /// Sirve para explorar SIN pedir permiso de ubicación.
  static const zocalo = LatLng(19.1996, -96.1342);

  /// Las calles no son líneas rectas: multiplicamos la distancia en línea
  /// recta por 1.3 (supuesto a calibrar caminando el centro).
  static const factorCalles = 1.3;

  /// Velocidad de caminata: 4 km/h ≈ 67 metros por minuto.
  static const metrosPorMinuto = 67.0;

  /// Fórmula de Haversine: distancia en metros entre dos puntos del
  /// planeta, usando latitud y longitud. Considera que la Tierra es una
  /// esfera de 6,371 km de radio.
  static double metros(LatLng a, LatLng b) {
    const radioTierra = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLon = _rad(b.longitude - a.longitude);
    final h = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(a.latitude)) * cos(_rad(b.latitude)) * sin(dLon / 2) * sin(dLon / 2);
    return 2 * radioTierra * asin(sqrt(h));
  }

  /// Minutos aproximados caminando por las calles (redondeado hacia arriba).
  static int minutosCaminando(LatLng a, LatLng b) =>
      (metros(a, b) * factorCalles / metrosPorMinuto).ceil();

  /// Texto corto para mostrar, por ejemplo "A 5 min a pie".
  static String texto(LatLng a, LatLng b) {
    final min = minutosCaminando(a, b);
    return min <= 1 ? 'A 1 min a pie' : 'A $min min a pie';
  }

  static double _rad(double grados) => grados * pi / 180;
}
