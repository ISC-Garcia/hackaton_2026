// Pruebas del costo de entrada (SQL 014), sin internet.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verago/models/lugar.dart';
import 'package:verago/widgets/editor_costo_entrada.dart';

Lugar lugar({int? costo, bool comercio = false, bool punto = false, String? puntoId}) => Lugar.fromJson({
      'id': 'x',
      'nombre': 'Lugar',
      'descripcion': null,
      'categorias': {'clave': 'museo', 'nombre': 'Museos'},
      'latitud': 19.19,
      'longitud': -96.13,
      'direccion': null,
      'telefono': null,
      'interes': 3,
      'duracion_visita_min': 30,
      'es_comercio': comercio,
      'es_demo': false,
      'participa_pasaporte': false,
      'es_punto': punto,
      'punto_id': puntoId,
      'costo_entrada_mxn': costo,
    });

void main() {
  group('Texto de la entrada en la ficha', () {
    test('lugar público sin dato: avisa que no está disponible (no inventamos)', () {
      expect(lugar().textoEntrada, contains('no disponible'));
    });
    test('gratis y con costo', () {
      expect(lugar(costo: 0).textoEntrada, 'Entrada gratis');
      expect(lugar(costo: 75).textoEntrada, r'Entrada aprox. $75 MXN');
    });
    test('negocio sin dato: no cobra entrada, no se muestra nada', () {
      expect(lugar(comercio: true).textoEntrada, isNull);
    });
    test('no formales y Puntos VeraGo nunca muestran entrada', () {
      expect(lugar(comercio: true, puntoId: 'p').textoEntrada, isNull);
      expect(lugar(punto: true).textoEntrada, isNull);
    });
  });

  testWidgets('Editor: "Con costo" sin monto marca error; con monto avisa el valor', (tester) async {
    final formulario = GlobalKey<FormState>();
    int? valor = -1;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Form(
          key: formulario,
          child: EditorCostoEntrada(inicial: null, paraNegocio: false, alCambiar: (v) => valor = v),
        ),
      ),
    ));
    await tester.tap(find.text('Con costo'));
    await tester.pumpAndSettle();
    expect(formulario.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Escribe el costo (o elige otra opción)'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '60');
    expect(valor, 60);
    expect(formulario.currentState!.validate(), isTrue);

    await tester.tap(find.text('Gratis'));
    await tester.pumpAndSettle();
    expect(valor, 0);
  });

  testWidgets('Editor del negocio: solo "No cobro entrada" o "Cobro entrada"', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: EditorCostoEntrada(inicial: null, paraNegocio: true, alCambiar: (_) {})),
    ));
    expect(find.text('No cobro entrada'), findsOneWidget);
    expect(find.text('Cobro entrada'), findsOneWidget);
    expect(find.text('Gratis'), findsNothing);
  });
}
