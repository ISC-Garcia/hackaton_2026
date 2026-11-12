import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Un lugar encontrado en OpenStreetMap que NO es un lugar de VeraGo
/// (ej. "Tecnológico", "Oxxo"). Solo se muestra en el mapa; no se guarda.
class LugarDelMapa {
  const LugarDelMapa({required this.nombre, required this.direccion, required this.punto});
  final String nombre;
  final String? direccion;
  final LatLng punto;
}

/// GEOCODIFICACIÓN con Nominatim (OpenStreetMap):
/// - INVERSA (`direccionDe`): punto del mapa → dirección escrita.
/// - BÚSQUEDA (`buscar`): texto → lugares de la zona de Veracruz.
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
  static const _baseBuscar = 'https://nominatim.openstreetmap.org/search';

  /// Rectángulo de Veracruz y Boca del Río (longitud, latitud de dos
  /// esquinas): la búsqueda solo devuelve lugares de aquí.
  static const zonaVeracruz = '-96.30,19.28,-96.00,19.02';

  /// Busca lugares por texto (ej. "Tecnológico"). Reglas de Nominatim:
  /// una búsqueda solo cuando la persona la pide (nunca mientras escribe).
  /// Solo se envía el texto buscado. Devuelve [] si no hay o no hay internet.
  Future<List<LugarDelMapa>> buscar(String texto) async {
    final q = texto.trim();
    if (q.length < 3) return const [];
    final url = Uri.parse(_baseBuscar).replace(queryParameters: {
      'q': q,
      'format': 'jsonv2',
      'limit': '8',
      'viewbox': zonaVeracruz,
      'bounded': '1',
      'accept-language': 'es',
    });
    try {
      final r = await http
          .get(url, headers: kIsWeb ? null : {'User-Agent': 'VeraGo/0.1 (app de hackaton)'})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return const [];
      return leerBusqueda(jsonDecode(r.body) as List);
    } catch (_) {
      return const [];
    }
  }

  /// Convierte la respuesta de Nominatim en `LugarDelMapa` (sin internet,
  /// para poder probarlo). `display_name` = "Nombre, calle, colonia, …".
  static List<LugarDelMapa> leerBusqueda(List datos) {
    final resultado = <LugarDelMapa>[];
    for (final d in datos) {
      if (d is! Map) continue;
      final lat = double.tryParse('${d['lat']}');
      final lon = double.tryParse('${d['lon']}');
      if (lat == null || lon == null) continue;
      final completo = '${d['display_name'] ?? ''}';
      final partes = completo.split(', ');
      final nombre = '${d['name'] ?? ''}'.trim().isNotEmpty ? '${d['name']}' : partes.first;
      final resto = partes.where((p) => p != nombre).take(3).join(', ');
      resultado.add(LugarDelMapa(nombre: nombre, direccion: resto.isEmpty ? null : resto, punto: LatLng(lat, lon)));
    }
    return resultado;
  }

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
