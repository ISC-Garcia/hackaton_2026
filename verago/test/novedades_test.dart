// Pruebas de: insignia por niveles, búsqueda en el mapa, eventos que se
// repiten y vitrina digital (sin internet).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/insignia.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/screens/editar_vitrina_screen.dart';
import 'package:verago/screens/lugar_screen.dart';
import 'package:verago/screens/pasaporte_screen.dart';
import 'package:verago/services/eventos_service.dart';
import 'package:verago/services/geocodificacion_service.dart';
import 'package:verago/services/validaciones.dart';
import 'package:verago/widgets/insignia_visual.dart';

Lugar negocio({List<Map<String, dynamic>> productos = const [], String? promo}) => Lugar.fromJson({
      'id': 'n1',
      'nombre': 'Café Demo',
      'descripcion': 'Café de prueba.',
      'categorias': {'clave': 'cafeteria', 'nombre': 'Cafeterías'},
      'latitud': 19.19,
      'longitud': -96.13,
      'direccion': null,
      'telefono': null,
      'interes': 3,
      'duracion_visita_min': 30,
      'es_comercio': true,
      'es_demo': true,
      'participa_pasaporte': true,
      'vitrina_productos': productos,
      'promocion': promo,
    });

void main() {
  group('Insignia', () {
    test('cada nivel es una parte del total; el último = todos', () {
      expect(Insignia.metas(10), [2, 4, 6, 8, 10]);
      // 8 no se divide exacto entre 5: se redondea hacia arriba.
      expect(Insignia.metas(8), [2, 4, 5, 7, 8]);
    });

    test('calcula el nivel y lo que falta', () {
      final p = Insignia.calcular(logrados: 5, total: 10);
      expect(p.nivel, 2);
      expect(p.actual!.nombre, 'Explorador');
      expect(p.siguiente!.nombre, 'Viajero');
      expect(p.faltan, 1);
      expect(Insignia.calcular(logrados: 0, total: 10).nivel, 0);
      final completa = Insignia.calcular(logrados: 10, total: 10);
      expect(completa.completa, isTrue);
      expect(completa.actual!.nombre, 'Embajador VeraGo');
    });

    testWidgets('insignias ganadas y bloqueadas miden lo mismo (fila alineada)', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Row(children: [
            InsigniaVisual(nivel: 1, tamano: 34, key: Key('ganada')),
            InsigniaVisual(nivel: 2, tamano: 34, bloqueada: true, key: Key('bloqueada')),
          ]),
        ),
      ));
      expect(tester.getSize(find.byKey(const Key('ganada'))), tester.getSize(find.byKey(const Key('bloqueada'))));
    });

    testWidgets('la tarjeta dice cuántos sellos faltan', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: TarjetaInsignia(progreso: Insignia.calcular(logrados: 3, total: 10))),
      ));
      expect(find.text('Visitante'), findsOneWidget);
      expect(find.text('Te falta 1 sello para "Explorador"'), findsOneWidget);
    });
  });

  test('búsqueda en el mapa: lee la respuesta de Nominatim', () {
    final r = GeocodificacionService.leerBusqueda([
      {
        'lat': '19.1975',
        'lon': '-96.1530',
        'name': 'Instituto Tecnológico de Veracruz',
        'display_name': 'Instituto Tecnológico de Veracruz, Calle Potrero del Llano, Quinta Maria, Veracruz',
      },
      {'lat': 'x', 'lon': '1'}, // inválido: se ignora
    ]);
    expect(r, hasLength(1));
    expect(r.first.nombre, 'Instituto Tecnológico de Veracruz');
    expect(r.first.direccion, contains('Potrero del Llano'));
    expect(r.first.punto.latitude, 19.1975);
  });

  group('Eventos que se repiten', () {
    final base = DatosEvento(
      titulo: 'Danzón en el Zócalo',
      descripcion: '',
      lugarId: 'z',
      inicia: DateTime(2026, 11, 14, 18),
      termina: DateTime(2026, 11, 14, 20),
      estado: 'publicado',
      esGratuito: true,
      costoAproxMxn: null,
    );

    test('cada 7 días, 4 veces, a la misma hora', () {
      final fechas = DatosEvento.repetir(base, cadaDias: 7, veces: 4);
      expect(fechas.map((e) => e.inicia.day), [14, 21, 28, 5]);
      expect(fechas.every((e) => e.inicia.hour == 18 && e.termina.hour == 20), isTrue);
    });

    test('valida los números y que las fechas no se encimen', () {
      expect(Validaciones.repeticion(cadaDias: 7, veces: 4, duracion: const Duration(hours: 2)), isNull);
      expect(Validaciones.repeticion(cadaDias: 0, veces: 4, duracion: const Duration(hours: 2)), isNotNull);
      expect(Validaciones.repeticion(cadaDias: 7, veces: 1, duracion: const Duration(hours: 2)), isNotNull);
      expect(Validaciones.repeticion(cadaDias: 1, veces: 3, duracion: const Duration(days: 2)), isNotNull);
    });
  });

  group('Vitrina digital', () {
    test('lee productos y promoción', () {
      final l = negocio(productos: [
        {'nombre': 'Café lechero', 'precio': 45},
        {'nombre': 'Pan dulce', 'precio': null},
      ], promo: '2x1 de 4 a 6 pm');
      expect(l.tieneVitrina, isTrue);
      expect(l.productos.first.precioMxn, 45);
      expect(l.productos.last.precioMxn, isNull);
    });

    testWidgets('la ficha muestra la sección Vitrina con la promoción', (tester) async {
      final l = negocio(productos: [
        {'nombre': 'Café lechero', 'precio': 45},
      ], promo: '2x1 de 4 a 6 pm');
      await tester.pumpWidget(MaterialApp(home: LugarScreen(lugar: l, todos: [l])));
      await tester.scrollUntilVisible(find.text('Café lechero'), 200, scrollable: find.byType(Scrollable).first);
      expect(find.text('Vitrina'), findsOneWidget);
      expect(find.text('2x1 de 4 a 6 pm'), findsOneWidget);
      expect(find.text(r'≈ $45'), findsOneWidget);
    });

    testWidgets('editar vitrina: un producto sin nombre no se guarda', (tester) async {
      await tester.pumpWidget(MaterialApp(home: EditarVitrinaScreen(negocio: negocio())));
      await tester.tap(find.text('Agregar producto o servicio'));
      await tester.pump();
      await tester.tap(find.text('Guardar vitrina'));
      await tester.pump();
      expect(find.text('Escribe el nombre'), findsOneWidget);
    });
  });

  test('evento duplicado: mensaje claro', () {
    expect(EventosService.eventoDuplicado, contains('mismo nombre'.replaceAll('mismo ', '')));
    expect(EventosService.eventoDuplicado, contains('a esa hora y en ese lugar'));
  });
}
