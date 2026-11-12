import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// SERVICIO del TRAZO POR LAS CALLES de una ruta.
///
/// Qué hace: le manda las paradas a un servidor de rutas a pie de
/// OpenStreetMap (OSRM en routing.openstreetmap.de) y recibe el camino
/// caminando por las calles, como una lista de puntos para dibujar.
///
/// Por qué: sin esto, la ruta se dibuja en línea recta y cruza edificios.
/// Solo cambia el DIBUJO: el armado de la ruta y sus tiempos siguen siendo
/// los de `RutasService` (que funciona sin internet).
///
/// Privacidad (decisión del equipo): se envían las paradas y el punto de
/// INICIO de la ruta. Si el turista eligió "Mi ubicación", ese punto es su
/// ubicación: se envía una vez por ruta y VeraGo no la guarda (lo explica
/// el Aviso de privacidad).
///
/// Reglas de uso del servidor que respetamos: pocas peticiones (una por
/// ruta, y se guardan en memoria para no repetirlas).
/// Si falla o no hay internet, devuelve null y la app dibuja la línea recta.
class TrazoService {
  TrazoService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// Trazos ya pedidos en esta sesión (clave = coordenadas de las paradas).
  static final _memoria = <String, List<LatLng>>{};

  /// Dirección del servidor para estas paradas. OSRM pide "longitud,latitud".
  static Uri direccion(List<LatLng> paradas) {
    final coords = paradas
        .map((p) => '${p.longitude.toStringAsFixed(6)},${p.latitude.toStringAsFixed(6)}')
        .join(';');
    return Uri.parse('https://routing.openstreetmap.de/routed-foot/route/v1/foot/$coords'
        '?overview=full&geometries=geojson');
  }

  /// Lee la respuesta de OSRM: routes[0].geometry.coordinates = [[lng, lat], ...].
  static List<LatLng>? leer(Map<String, dynamic> json) {
    if (json['code'] != 'Ok') return null;
    final rutas = json['routes'] as List?;
    if (rutas == null || rutas.isEmpty) return null;
    final coords = ((rutas.first as Map)['geometry'] as Map?)?['coordinates'] as List?;
    if (coords == null || coords.length < 2) return null;
    return [
      for (final c in coords) LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
    ];
  }

  /// Camino a pie por las calles que pasa por todas las paradas, en orden.
  Future<List<LatLng>?> caminoPorCalles(List<LatLng> paradas) async {
    if (paradas.length < 2) return null;
    final uri = direccion(paradas);
    final guardado = _memoria[uri.toString()];
    if (guardado != null) return guardado;
    try {
      final r = await _cliente
          // En web el navegador no deja cambiar el User-Agent (igual que en
          // GeocodificacionService), así que solo se envía en el celular.
          .get(uri, headers: kIsWeb ? null : {'User-Agent': 'VeraGo/1.0 (app de turismo, proyecto de hackaton)'})
          .timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final camino = leer(jsonDecode(r.body) as Map<String, dynamic>);
      if (camino != null) _memoria[uri.toString()] = camino;
      return camino;
    } catch (_) {
      return null; // sin internet o el servidor no respondió: línea recta
    }
  }
}
