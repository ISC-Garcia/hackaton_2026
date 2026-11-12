// Pruebas del límite del municipio de Veracruz (sin internet).

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:verago/services/distancia.dart';
import 'package:verago/services/municipio_veracruz.dart';
import 'package:verago/widgets/selector_ubicacion.dart';

void main() {
  test('dentro del municipio de Veracruz', () {
    expect(MunicipioVeracruz.contiene(Distancia.zocalo), isTrue);
    expect(MunicipioVeracruz.contiene(const LatLng(19.1975, -96.1314)), isTrue); // Malecón
    expect(MunicipioVeracruz.contiene(const LatLng(19.1975, -96.1530)), isTrue); // Tecnológico
    expect(MunicipioVeracruz.contiene(const LatLng(19.2087, -96.1336)), isTrue); // San Juan de Ulúa
  });

  test('fuera del municipio (otro municipio, otra ciudad, otro país)', () {
    expect(MunicipioVeracruz.contiene(const LatLng(19.1047, -96.1057)), isFalse); // Boca del Río
    expect(MunicipioVeracruz.contiene(const LatLng(19.5438, -96.9102)), isFalse); // Xalapa
    expect(MunicipioVeracruz.contiene(const LatLng(19.4326, -99.1332)), isFalse); // CDMX
    expect(MunicipioVeracruz.contiene(const LatLng(40.4168, -3.7038)), isFalse); // Madrid
  });

  test('el rectángulo del mapa encierra el municipio', () {
    expect(MunicipioVeracruz.limites.contains(Distancia.zocalo), isTrue);
    expect(MunicipioVeracruz.limites.contains(const LatLng(19.4326, -99.1332)), isFalse);
  });

  test('mensaje al tocar fuera', () {
    expect(SelectorUbicacion.fueraDelMunicipio, contains('municipio de Veracruz'));
  });
}
