// Pruebas de lógica (sin pantallas ni internet):
// - "¿Está abierto?" a partir del horario.
// - Distancia y minutos caminando.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/services/distancia.dart';

/// Crea un lugar de prueba con el horario indicado.
Lugar lugarDePrueba(List<Horario> horarios) => Lugar(
      id: '1',
      nombre: 'Café de prueba',
      descripcion: null,
      categoriaClave: 'cafeteria',
      categoriaNombre: 'Cafeterías',
      latitud: 19.1985,
      longitud: -96.1338,
      direccion: null,
      telefono: null,
      interes: 4,
      duracionVisitaMin: 30,
      esComercio: true,
      esDemo: true,
      participaPasaporte: true,
      horarios: horarios,
    );

void main() {
  group('¿Está abierto?', () {
    // Lunes (dia_semana 1) de 09:00 a 18:00.
    final lugar = lugarDePrueba([const Horario(diaSemana: 1, abre: 9 * 60, cierra: 18 * 60)]);

    // 10 de noviembre de 2025 fue lunes.
    test('abierto a las 09:00 en punto', () {
      expect(lugar.estadoEn(DateTime(2025, 11, 10, 9, 0)), EstadoApertura.abierto);
    });
    test('cerrado a las 08:59', () {
      expect(lugar.estadoEn(DateTime(2025, 11, 10, 8, 59)), EstadoApertura.cerrado);
    });
    test('cerrado a las 18:00 (hora de cierre)', () {
      expect(lugar.estadoEn(DateTime(2025, 11, 10, 18, 0)), EstadoApertura.cerrado);
    });
    test('cerrado un día sin horario (martes)', () {
      expect(lugar.estadoEn(DateTime(2025, 11, 11, 12, 0)), EstadoApertura.cerrado);
    });
    test('sin horarios cargados → "sin datos", no se inventa', () {
      expect(lugarDePrueba([]).estadoEn(DateTime(2025, 11, 10, 12, 0)), EstadoApertura.sinDatos);
    });
  });

  group('Distancia', () {
    test('mismo punto = 0 metros', () {
      expect(Distancia.metros(Distancia.zocalo, Distancia.zocalo), 0);
    });
    test('~111 km por cada grado de latitud', () {
      final m = Distancia.metros(const LatLng(19, -96), const LatLng(20, -96));
      expect(m, closeTo(111195, 200));
    });
    test('500 m en línea recta ≈ 10 min caminando (con factor de calles 1.3)', () {
      // 0.0045° de latitud ≈ 500 m
      final b = LatLng(Distancia.zocalo.latitude + 0.0045, Distancia.zocalo.longitude);
      expect(Distancia.minutosCaminando(Distancia.zocalo, b), 10);
    });
  });
}
