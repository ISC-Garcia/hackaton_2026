// Pruebas del generador de rutas (sección 16 del documento).
// No usan internet: se le dan lugares inventados para la prueba.

import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/rutas_screen.dart';
import 'package:verago/widgets/etiqueta.dart';
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

  group('Negocios y Puntos VeraGo en la ruta', () {
    final lugares = [
      lugar('m1', interes: 5, dLat: 0.0005),
      lugar('m2', interes: 5, dLat: 0.0008),
      lugar('m3', interes: 5, dLat: 0.0010),
      lugar('formal', comercio: true, interes: 2, dLat: 0.003),
      lugar('punto', esPunto: true, categoria: 'punto', interes: 2, dLat: -0.003),
      lugar('guayaberas', comercio: true, puntoId: 'punto', dLat: -0.003),
    ];

    test('un Punto VeraGo entra solo si se elige "Puntos VeraGo"', () {
      final ids = servicio
          .generar(peticion(minutos: 180, intereses: {'punto'}), lugares)
          .paradas
          .map((p) => p.lugar.id);
      expect(ids, ['punto']);
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

  group('Filtro por intereses', () {
    final lugares = [
      lugar('h1', categoria: 'historia', interes: 5, dLat: 0.0005),
      lugar('h2', categoria: 'historia', interes: 5, dLat: 0.0008),
      lugar('museo', categoria: 'museo', interes: 3, dLat: 0.001),
      lugar('cafe', categoria: 'cafeteria', comercio: true, interes: 2, dLat: 0.002),
      lugar('punto', esPunto: true, categoria: 'punto', interes: 2, dLat: -0.003),
      lugar('guayaberas', comercio: true, puntoId: 'punto', dLat: -0.003),
    ];

    test('SOLO entran las categorías elegidas (nada de negocios a fuerza)', () {
      final ids = servicio
          .generar(peticion(minutos: 240, intereses: {'museo'}), lugares)
          .paradas
          .map((p) => p.lugar.id);
      expect(ids, contains('museo'));
      expect(ids, isNot(contains('h1')));
      expect(ids, isNot(contains('h2')));
      // Antes se metían a fuerza un negocio formal y un Punto VeraGo; ya no.
      expect(ids, isNot(contains('cafe')));
      expect(ids, isNot(contains('punto')));
    });

    test('sin intereses no falla (usa todas las categorías)', () {
      final ruta = servicio.generar(peticion(minutos: 240), lugares);
      expect(ruta.paradas, isNotEmpty);
    });

    test('los chips de Rutas incluyen Puntos VeraGo, pero no lugares lejanos', () {
      final cats = RutasScreen.categoriasDeRuta([
        ...lugares,
        lugar('ulua', categoria: 'fuerte', aPie: false),
      ]);
      expect(cats.keys, containsAll(['historia', 'museo', 'cafeteria']));
      expect(cats.keys, contains('punto'));
      expect(cats.keys, isNot(contains('fuerte')));
    });

    test('la sugerencia del final respeta los intereses', () {
      final s = servicio.sugerenciaCercana(Distancia.zocalo, lugares, {}, intereses: {'museo'});
      expect(s, isNull); // el único negocio es un café: no se sugiere en una ruta de museos
      expect(servicio.sugerenciaCercana(Distancia.zocalo, lugares, {})?.id, 'cafe');
    });
  });

  test('etiqueta Formal / No formal', () {
    expect(Etiqueta.tipoNegocio(lugar('f', comercio: true))?.texto, 'Negocio formal');
    expect(Etiqueta.tipoNegocio(lugar('i', comercio: true, puntoId: 'p'))?.texto,
        'No formal · Punto VeraGo');
    expect(Etiqueta.tipoNegocio(lugar('plaza')), isNull);
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

  test('la sugerencia nunca es un negocio no formal (se visita en su punto)', () {
    final lugares = [
      lugar('informal', comercio: true, puntoId: 'p', dLat: 0.0002),
      lugar('formal', comercio: true, dLat: 0.002),
    ];
    expect(servicio.sugerenciaCercana(Distancia.zocalo, lugares, {})?.id, 'formal');
  });
}
