import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// GEOCODIFICACIÓN INVERSA: convierte un punto del mapa (latitud, longitud)
/// en una dirección escrita.
///
/// Qué usa: Nominatim, el servicio gratuito de OpenStreetMap.
/// Por qué: así la dirección SIEMPRE coincide con el punto que el comerciante
/// tocó en el mapa (antes se escribían por separado y podían no coincidir).
///
/// Reglas de uso de Nominatim que respetamos:
/// - Pocas consultas: solo una cuando el usuario toca el mapa.
/// - Identificar la app (User-Agent). En web el navegador no deja cambiarlo
///   y Nominatim usa la página de origen.
/// Solo se envían las coordenadas del NEGOCIO (no la ubicación del usuario).
class GeocodificacionService {
  static const _base = 'https://nominatim.openstreetmap.org/reverse';

  /// Devuelve la dirección del punto, o null si no se pudo obtener.
  Future<String?> direccionDe(LatLng punto) async {
    final url = Uri.parse(_base).replace(queryParameters: {
      'format': 'jsonv2',
      'lat': punto.latitude.toStringAsFixed(6),
      'lon': punto.longitude.toStringAsFixed(6),
      'zoom': '18', // nivel de calle y número
      'addressdetails': '1',
      'accept-language': 'es',
    });
    try {
      final respuesta = await http
          .get(url, headers: kIsWeb ? null : {'User-Agent': 'VeraGo/0.1 (app de hackaton)'})
          .timeout(const Duration(seconds: 10));
      if (respuesta.statusCode != 200) return null;
      final datos = jsonDecode(respuesta.body) as Map<String, dynamic>;
      return formatear(datos['address'] as Map<String, dynamic>?);
    } catch (_) {
      return null; // sin internet o servicio no disponible
    }
  }

  /// Arma una dirección corta: "Calle Número, Colonia, Ciudad".
  /// Es pública y sin internet para poder probarla.
  static String? formatear(Map<String, dynamic>? a) {
    if (a == null) return null;
    final calle = a['road'] ?? a['pedestrian'] ?? a['footway'] ?? a['square'];
    final numero = a['house_number'];
    final colonia = a['suburb'] ?? a['neighbourhood'] ?? a['quarter'];
    final ciudad = a['city'] ?? a['town'] ?? a['village'];
    final partes = <String>[
      if (calle != null) numero != null ? '$calle $numero' : '$calle',
      if (colonia != null) '$colonia',
      if (ciudad != null) '$ciudad',
    ];
    return partes.isEmpty ? null : partes.join(', ');
  }
}
