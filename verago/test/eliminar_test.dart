// Pruebas del flujo para eliminar lugares, Puntos y negocios (sin Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/services/eliminar_service.dart';
import 'package:verago/widgets/eliminar_lugar.dart';

/// Servicio falso: responde lo que le digamos y anota si se eliminó.
class _ServicioFalso extends EliminarService {
  _ServicioFalso(this.revision);
  final RevisionEliminar revision;
  bool eliminado = false;

  @override
  Future<RevisionEliminar> revisar(String lugarId) async => revision;

  @override
  Future<void> eliminar(String lugarId, {String? fotoUrl}) async => eliminado = true;
}

final _lugar = Lugar.fromJson({
  'id': 'p1',
  'nombre': 'Punto Demo',
  'descripcion': null,
  'categorias': {'clave': 'punto', 'nombre': 'Puntos VeraGo'},
  'latitud': 19.19,
  'longitud': -96.13,
  'direccion': null,
  'telefono': null,
  'interes': 3,
  'duracion_visita_min': 30,
  'es_comercio': false,
  'es_demo': true,
  'participa_pasaporte': false,
});

/// Pantalla mínima con un botón que lanza el flujo.
Widget _app(EliminarService s, {required VoidCallback alOcultar, required void Function(bool) alTerminar}) =>
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => alTerminar(await EliminarLugar.ejecutar(
              context,
              _lugar,
              servicio: s,
              ocultar: () async => alOcultar(),
            )),
            child: const Text('eliminar'),
          ),
        ),
      ),
    );

void main() {
  test('lee la revisión de la base de datos', () {
    final r = RevisionEliminar.desdeJson({'estado': 'TIENE_SELLOS', 'sellos': 3});
    expect(r.sellos, 3);
    expect(r.sePuede, isFalse);
    expect(RevisionEliminar.desdeJson({'estado': 'SE_PUEDE', 'eventos': 1}).sePuede, isTrue);
  });

  testWidgets('un Punto con negocios no se elimina hasta vaciarlo', (tester) async {
    final s = _ServicioFalso(const RevisionEliminar('TIENE_NEGOCIOS', negocios: 2));
    bool? resultado;
    await tester.pumpWidget(_app(s, alOcultar: () {}, alTerminar: (r) => resultado = r));
    await tester.tap(find.text('eliminar'));
    await tester.pumpAndSettle();
    expect(find.text('No se puede eliminar todavía'), findsOneWidget);
    expect(find.textContaining('tiene 2 negocios'), findsOneWidget);
    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(resultado, isFalse);
    expect(s.eliminado, isFalse);
  });

  testWidgets('con sellos no se elimina: ofrece ocultarlo', (tester) async {
    final s = _ServicioFalso(const RevisionEliminar('TIENE_SELLOS', sellos: 5));
    var oculto = false;
    bool? resultado;
    await tester.pumpWidget(_app(s, alOcultar: () => oculto = true, alTerminar: (r) => resultado = r));
    await tester.tap(find.text('eliminar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('5 sellos'), findsOneWidget);
    await tester.tap(find.text('Ocultarlo'));
    await tester.pumpAndSettle();
    expect(oculto, isTrue);
    expect(s.eliminado, isFalse);
    expect(resultado, isTrue);
  });

  testWidgets('sin sellos ni negocios: confirma y elimina', (tester) async {
    final s = _ServicioFalso(const RevisionEliminar('SE_PUEDE', eventos: 1));
    bool? resultado;
    await tester.pumpWidget(_app(s, alOcultar: () {}, alTerminar: (r) => resultado = r));
    await tester.tap(find.text('eliminar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('para siempre'), findsOneWidget);
    expect(find.textContaining('1 evento quedará sin lugar'), findsOneWidget);
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    expect(s.eliminado, isTrue);
    expect(resultado, isTrue);
  });
}
