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
  bool esPunto = false,
  String? puntoId,
}) =>
    Lugar(
      esPunto: esPunto,
      puntoId: puntoId,
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

  group('Regla del equipo: comerciantes en la ruta', () {
    // Monumentos muy interesantes y cercanos; el comercio formal y el punto
    // tienen menos interés y están más lejos: aun así deben entrar.
    final lugares = [
      lugar('m1', interes: 5, dLat: 0.0005),
      lugar('m2', interes: 5, dLat: 0.0008),
      lugar('m3', interes: 5, dLat: 0.0010),
      lugar('formal', comercio: true, interes: 2, dLat: 0.003),
      lugar('punto', esPunto: true, categoria: 'punto', interes: 2, dLat: -0.003),
      lugar('guayaberas', comercio: true, puntoId: 'punto', dLat: -0.003),
    ];

    test('incluye al menos 1 comercio formal y 1 Punto VeraGo', () {
      final ids = servicio.generar(peticion(minutos: 180), lugares).paradas.map((p) => p.lugar.id);
      expect(ids, contains('formal'));
      expect(ids, contains('punto'));
    });

    test('un comerciante informal nunca es parada suelta (la parada es su punto)', () {
      final ids = servicio.generar(peticion(minutos: 240), lugares).paradas.map((p) => p.lugar.id);
      expect(ids, isNot(contains('guayaberas')));
    });

    test('un punto sin comerciantes no entra a la ruta', () {
      final sinComerciantes = lugares.where((l) => l.id != 'guayaberas').toList();
      final ids = servicio.generar(peticion(minutos: 240), sinComerciantes).paradas.map((p) => p.lugar.id);
      expect(ids, isNot(contains('punto')));
    });

    test('si no cabe en el tiempo, no se fuerza', () {
      // 40 min: solo cabe una visita de 30 min cercana.
      final ruta = servicio.generar(peticion(minutos: 40), lugares);
      expect(ruta.minutosUsados, lessThanOrEqualTo(40));
    });
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
