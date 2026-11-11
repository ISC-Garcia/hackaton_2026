// Pruebas del generador de rutas (sección 16 del documento).
// No usan internet: se le dan lugares inventados para la prueba.

import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/services/distancia.dart';
import 'package:verago/services/rutas_service.dart';

Lugar lugar(
  String id, {
  String categoria = 'historia',
  double dLat = 0,
  int interes = 3,
  int visita = 30,
  List<Horario> horarios = const [],
  bool aPie = true,
  bool comercio = false,
}) =>
    Lugar(
      id: id,
      nombre: 'Lugar $id',
      descripcion: null,
      categoriaClave: categoria,
      categoriaNombre: categoria,
      latitud: Distancia.zocalo.latitude + dLat,
      longitud: Distancia.zocalo.longitude,
      direccion: null,
      telefono: null,
      interes: interes,
      duracionVisitaMin: visita,
      esComercio: comercio,
      esDemo: true,
      participaPasaporte: comercio,
      horarios: horarios,
      enRecorridoAPie: aPie,
    );

PeticionRuta peticion({
  int minutos = 180,
  Set<String> intereses = const {},
  Set<String> excluir = const {},
  DateTime? hora,
}) =>
    PeticionRuta(
      inicio: Distancia.zocalo,
      nombreInicio: 'el Zócalo',
      horaInicio: hora ?? DateTime(2025, 11, 10, 15, 0), // lunes 15:00
      minutosDisponibles: minutos,
      intereses: intereses,
      excluir: excluir,
    );

void main() {
  final servicio = RutasService();

  test('nunca se pasa del tiempo disponible', () {
    final lugares = [for (var i = 0; i < 10; i++) lugar('$i', dLat: i * 0.001)];
    final ruta = servicio.generar(peticion(minutos: 120), lugares);
    expect(ruta.paradas, isNotEmpty);
    expect(ruta.minutosUsados, lessThanOrEqualTo(120));
  });

  test('no repite lugares', () {
    final lugares = [for (var i = 0; i < 10; i++) lugar('$i', dLat: i * 0.001)];
    final ruta = servicio.generar(peticion(minutos: 240), lugares);
    final ids = ruta.paradas.map((p) => p.lugar.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('prefiere la categoría favorita', () {
    final lugares = [
      lugar('museo', categoria: 'historia', dLat: 0.001),
      lugar('cafe', categoria: 'cafeteria', dLat: 0.001),
    ];
    final ruta = servicio.generar(
      peticion(minutos: 45, intereses: {'cafeteria'}),
      lugares,
    );
    expect(ruta.paradas.first.lugar.id, 'cafe');
  });

  test('omite lugares cerrados a la hora de llegada', () {
    // Abre lunes solo de 09:00 a 12:00; la ruta empieza a las 15:00.
    final cerrado = lugar('cerrado', interes: 5, comercio: true, horarios: const [
      Horario(diaSemana: 1, abre: 9 * 60, cierra: 12 * 60),
    ]);
    final ruta = servicio.generar(peticion(), [cerrado, lugar('abierto', dLat: 0.002)]);
    expect(ruta.paradas.map((p) => p.lugar.id), isNot(contains('cerrado')));
  });

  test('omite lugares que no se recorren a pie (ej. San Juan de Ulúa)', () {
    final ruta = servicio.generar(peticion(), [lugar('ulua', aPie: false, interes: 5)]);
    expect(ruta.paradas, isEmpty);
  });

  test('"Quitar" una parada la excluye al regenerar', () {
    final lugares = [lugar('a', dLat: 0.001), lugar('b', dLat: 0.002)];
    final ruta = servicio.generar(peticion(excluir: {'a'}), lugares);
    expect(ruta.paradas.map((p) => p.lugar.id), isNot(contains('a')));
  });

  test('sugiere el comercio más cercano que no está en la ruta', () {
    final lugares = [
      lugar('lejos', comercio: true, dLat: 0.004),
      lugar('cerca', comercio: true, dLat: 0.0005),
      lugar('monumento', dLat: 0.0001),
    ];
    final s = servicio.sugerenciaCercana(Distancia.zocalo, lugares, {});
    expect(s?.id, 'cerca');
  });
}
